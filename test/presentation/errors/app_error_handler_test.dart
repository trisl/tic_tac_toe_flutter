import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/errors/app_error_handler.dart';

void main() {
  // AppErrorHandler.install()/uninstall() touch these real global hooks.
  // Every test that calls install() must leave them exactly as found, or it
  // poisons every test that runs after it (including flutter_test's own
  // failure reporting, which lives behind FlutterError.onError).
  late FlutterExceptionHandler? savedOnError;
  late bool Function(Object exception, StackTrace stack)? savedPlatformOnError;
  late ErrorWidgetBuilder savedErrorWidgetBuilder;

  setUp(() {
    savedOnError = FlutterError.onError;
    savedPlatformOnError = PlatformDispatcher.instance.onError;
    savedErrorWidgetBuilder = ErrorWidget.builder;
  });

  tearDown(() {
    FlutterError.onError = savedOnError;
    PlatformDispatcher.instance.onError = savedPlatformOnError;
    ErrorWidget.builder = savedErrorWidgetBuilder;
  });

  group('AppErrorHandler', () {
    testWidgets(
      'intercept true: presents the apology then returns home, in order',
      (tester) async {
        // _scheduleApology() defers via WidgetsBinding's post-frame
        // callback, which only runs when a frame is actually pumped. In
        // the real app there is always a widget tree producing frames;
        // here a minimal one is pumped so tester.pump() below drives it.
        await tester.pumpWidget(const SizedBox.shrink());

        final calls = <String>[];
        final handler = AppErrorHandler(
          presentApology: () async {
            calls.add('apology');
          },
          returnHome: () async {
            calls.add('home');
          },
          intercept: true,
        );

        handler.handleFlutterError(
          FlutterErrorDetails(exception: Exception('boom')),
        );
        await tester.pump();

        expect(calls, ['apology', 'home']);
      },
    );

    testWidgets(
      'intercept defaults to kReleaseMode (false under test): does neither',
      (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        final calls = <String>[];
        final handler = AppErrorHandler(
          presentApology: () async {
            calls.add('apology');
          },
          returnHome: () async {
            calls.add('home');
          },
        );

        handler.handleFlutterError(
          FlutterErrorDetails(exception: Exception('boom')),
        );
        await tester.pump();

        expect(calls, isEmpty);
      },
    );

    testWidgets(
      'a second error while an apology is in flight does not present a '
      'second dialog',
      (tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        var presentCount = 0;
        final apologyStarted = Completer<void>();
        final releaseApology = Completer<void>();
        final handler = AppErrorHandler(
          presentApology: () async {
            presentCount++;
            apologyStarted.complete();
            await releaseApology.future;
          },
          returnHome: () async {},
          intercept: true,
        );

        handler.handleFlutterError(
          FlutterErrorDetails(exception: Exception('first')),
        );
        // The post-frame callback runs synchronously as part of this pump,
        // up to presentApology's own first `await` — so by the time pump()
        // returns, apologyStarted must already be complete. Assert that
        // instead of awaiting the completer directly: if the deferred
        // callback never ran, an `await` on it would hang the test forever
        // rather than fail it, and a hang is strictly worse than a failure.
        await tester.pump();
        expect(
          apologyStarted.isCompleted,
          isTrue,
          reason:
              'the deferred apology never ran; nothing below can be '
              'trusted',
        );

        // A second error arrives while the first apology is still pending
        // (presentApology's future has not resolved yet).
        handler.handleFlutterError(
          FlutterErrorDetails(exception: Exception('second')),
        );
        await tester.pump();

        expect(presentCount, 1);

        releaseApology.complete();
        await tester.pump();
        await tester.pump();
      },
    );

    testWidgets('install() forwards to the previously-registered handler', (
      tester,
    ) async {
      final forwarded = <FlutterErrorDetails>[];
      FlutterError.onError = forwarded.add;

      final handler = AppErrorHandler(
        presentApology: () async {},
        returnHome: () async {},
      );
      handler.install();

      final details = FlutterErrorDetails(exception: Exception('boom'));
      FlutterError.onError!(details);

      expect(forwarded, [details]);

      handler.uninstall();
    });

    testWidgets(
      'install() forwards platform errors to the previously-registered '
      'handler',
      (tester) async {
        final forwarded = <Object>[];
        PlatformDispatcher.instance.onError = (Object error, StackTrace _) {
          forwarded.add(error);
          return true;
        };

        final handler = AppErrorHandler(
          presentApology: () async {},
          returnHome: () async {},
        );
        handler.install();

        final error = Exception('boom');
        final handled = PlatformDispatcher.instance.onError!(
          error,
          StackTrace.empty,
        );

        expect(forwarded, [error]);
        expect(handled, isTrue);

        handler.uninstall();
      },
    );

    testWidgets('uninstall() restores the previous handler', (tester) async {
      void previous(FlutterErrorDetails details) {}
      FlutterError.onError = previous;

      final handler = AppErrorHandler(
        presentApology: () async {},
        returnHome: () async {},
      );
      handler.install();
      expect(FlutterError.onError, isNot(same(previous)));

      handler.uninstall();

      expect(FlutterError.onError, same(previous));
    });

    testWidgets(
      'install() swaps ErrorWidget.builder for a neutral surface when '
      'intercept is true, and uninstall() restores it',
      (tester) async {
        final ErrorWidgetBuilder original = ErrorWidget.builder;
        final handler = AppErrorHandler(
          presentApology: () async {},
          returnHome: () async {},
          intercept: true,
        );

        handler.install();

        expect(ErrorWidget.builder, isNot(same(original)));
        final Widget built = ErrorWidget.builder(
          FlutterErrorDetails(exception: Exception('boom')),
        );
        expect(built, isA<SizedBox>());
        expect((built as SizedBox).width, 0);
        expect(built.height, 0);

        handler.uninstall();

        expect(ErrorWidget.builder, same(original));
      },
    );

    testWidgets(
      'install() leaves ErrorWidget.builder alone when intercept is false',
      (tester) async {
        final ErrorWidgetBuilder original = ErrorWidget.builder;
        final handler = AppErrorHandler(
          presentApology: () async {},
          returnHome: () async {},
        );

        handler.install();

        expect(ErrorWidget.builder, same(original));

        handler.uninstall();
      },
    );
  });
}
