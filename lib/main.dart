import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/errors/app_error_handler.dart';
import 'presentation/errors/error_dialog.dart';
import 'presentation/routing/app_router.dart';

void main() {
  // The lint only checks runApp()'s argument type; it can't see that
  // TicTacToeAppRoot.build() wraps ProviderScope one level down (done
  // deliberately, see the class doc, so widget tests can pump the root
  // widget directly). ProviderScope is present; this is a false positive.
  // ignore: riverpod_lint/missing_provider_scope
  runApp(const TicTacToeAppRoot());
}

/// The app plus its provider scope, so widget tests can pump the real thing.
class TicTacToeAppRoot extends StatelessWidget {
  const TicTacToeAppRoot({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProviderScope(child: TicTacToeApp());
}

class TicTacToeApp extends ConsumerStatefulWidget {
  const TicTacToeApp({super.key});

  @override
  ConsumerState<TicTacToeApp> createState() => _TicTacToeAppState();
}

class _TicTacToeAppState extends ConsumerState<TicTacToeApp> {
  final AppRouter _router = AppRouter();
  late final AppErrorHandler _errorHandler;

  @override
  void initState() {
    super.initState();
    _errorHandler = AppErrorHandler(
      presentApology: _presentApology,
      returnHome: _returnHome,
      intercept: ref.read(interceptAppErrorsProvider),
    )..install();
  }

  @override
  void dispose() {
    _errorHandler.uninstall();
    super.dispose();
  }

  Future<void> _presentApology() async {
    final BuildContext? context = _router.navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    await showErrorDialog(context);
  }

  Future<void> _returnHome() async {
    // gameNotifierProvider is auto-dispose, so leaving the game page for
    // home already discards whatever game state was mid-flight; that is a
    // desirable side effect here, since that state is exactly what the
    // error may have corrupted.
    await _router.replaceAll([const HomeRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tic Tac Toe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: _router.config(),
    );
  }
}
