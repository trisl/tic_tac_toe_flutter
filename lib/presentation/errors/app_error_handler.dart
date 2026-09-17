import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Installs global handlers that catch errors escaping the widget tree
/// (`FlutterError.onError`) and the zone/engine
/// (`PlatformDispatcher.instance.onError`), so the user sees one apology
/// dialog and is returned to the home page instead of a broken screen.
///
/// Framework-agnostic and injectable on purpose: [presentApology] and
/// [returnHome] are supplied by the caller, so this class can be exercised
/// in a unit test without mounting the real app, and [intercept] defaults to
/// [kReleaseMode] but can be forced on so widget tests (which always run in
/// debug) can still exercise the release behaviour.
class AppErrorHandler {
  AppErrorHandler({
    required this.presentApology,
    required this.returnHome,
    this.intercept = kReleaseMode,
  });

  final Future<void> Function() presentApology;
  final Future<void> Function() returnHome;

  /// Whether errors are actually intercepted (apology dialog + redirect
  /// home). Defaults to [kReleaseMode] so debug/profile keeps the red error
  /// screen and console output; tests force this to `true` to exercise the
  /// release behaviour while running in debug.
  final bool intercept;

  FlutterExceptionHandler? _previousOnError;
  bool Function(Object exception, StackTrace stack)? _previousPlatformOnError;
  ErrorWidgetBuilder? _previousErrorWidgetBuilder;

  // Guards against a build error firing on every rebuilt frame: the user
  // gets a single dialog, not a storm of them. Set while an apology is in
  // flight (dialog shown + navigation back home) and cleared once that
  // round trip completes.
  bool _apologyInFlight = false;

  /// Wires this handler into the global hooks. Whatever was previously
  /// registered is preserved and still invoked first, so the framework's
  /// red error screen, the console stack trace, and `flutter_test`'s own
  /// failure reporting keep working in debug/profile and in tests.
  void install() {
    _previousOnError = FlutterError.onError;
    FlutterError.onError = handleFlutterError;

    _previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = handlePlatformError;

    _previousErrorWidgetBuilder = ErrorWidget.builder;
    if (intercept) {
      // A neutral, empty surface instead of the red error box, so a broken
      // subtree does not flash red behind the apology dialog.
      ErrorWidget.builder = (FlutterErrorDetails details) =>
          const SizedBox.shrink();
    }
  }

  /// Restores whatever was registered before [install]. Must be called from
  /// the owning widget's `dispose()` — otherwise a widget test that mounts
  /// the app leaves these global handlers behind and poisons later tests.
  void uninstall() {
    FlutterError.onError = _previousOnError;
    PlatformDispatcher.instance.onError = _previousPlatformOnError;
    ErrorWidget.builder = _previousErrorWidgetBuilder ?? ErrorWidget.builder;
  }

  /// The new `FlutterError.onError`. Public so it can be exercised directly
  /// in a unit test without going through [install].
  void handleFlutterError(FlutterErrorDetails details) {
    _previousOnError?.call(details);
    _scheduleApology();
  }

  /// The new `PlatformDispatcher.instance.onError`. Public for the same
  /// reason as [handleFlutterError].
  bool handlePlatformError(Object error, StackTrace stack) {
    _previousPlatformOnError?.call(error, stack);
    // Not caught by FlutterError.onError, so it never reaches the console
    // on its own: surface it the same way the framework would.
    FlutterError.presentError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    _scheduleApology();
    return true;
  }

  void _scheduleApology() {
    if (!intercept || _apologyInFlight) {
      return;
    }
    _apologyInFlight = true;
    // FlutterError.onError can fire mid-build, where showing a dialog is
    // illegal; defer to the next frame instead of showing it inline. A
    // build error implies a frame is already in flight, so the callback
    // would fire on its own in that case — but a PlatformDispatcher error
    // (e.g. from a Future/timer) can happen while the app is otherwise
    // idle, with no frame pending, so a frame is explicitly requested to
    // guarantee the callback actually runs promptly either way.
    WidgetsBinding.instance.scheduleFrame();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) async {
      try {
        await presentApology();
        await returnHome();
      } finally {
        _apologyInFlight = false;
      }
    });
  }
}

/// Whether [AppErrorHandler] actually intercepts errors, defaulting to
/// [kReleaseMode]. Exposed as a provider — rather than, say, a constructor
/// parameter on the app widget — so it can be overridden the same way the
/// rest of the app injects test doubles (see `robotStrategyProvider`,
/// `robotDelayProvider`): via `ProviderScope(overrides: [...])`. That lets
/// a test exercise the real `_TicTacToeAppState` wiring end to end while
/// running in debug, where [kReleaseMode] is always `false`.
final Provider<bool> interceptAppErrorsProvider = Provider<bool>(
  (ref) => kReleaseMode,
);
