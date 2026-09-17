import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/main.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/errors/app_error_handler.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/errors/error_dialog.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/pages/game_page.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/pages/home_page.dart';

void main() {
  testWidgets(
    'a global error shows the apology over the game page and returns the '
    'user to a clean home page',
    (tester) async {
      // Pumps the real TicTacToeApp/_TicTacToeAppState wiring (not a test
      // double), with interceptAppErrorsProvider overridden to true so the
      // release behaviour runs while this test executes in debug — the
      // same seam the rest of the app uses for test doubles (see
      // robotStrategyProvider, robotDelayProvider).
      await tester.pumpWidget(
        ProviderScope(
          overrides: [interceptAppErrorsProvider.overrideWithValue(true)],
          child: const TicTacToeApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(GamePage), findsNothing);

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      // Triggered via the real, globally-installed PlatformDispatcher hook,
      // not FlutterError.onError: this app's install() correctly forwards
      // to whatever FlutterError.onError was previously registered, which
      // in this test is flutter_test's own failure reporter — forwarding a
      // real error there would (correctly) fail the test, which is not
      // what this test wants to exercise. PlatformDispatcher.onError is
      // untouched by flutter_test, so it exercises the same
      // apology/redirect wiring without that side effect.
      final bool? handled = PlatformDispatcher.instance.onError?.call(
        Exception('boom'),
        StackTrace.current,
      );
      expect(handled, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(ErrorDialog), findsOneWidget);
      expect(find.byType(GamePage), findsOneWidget);

      await tester.tap(find.text(ErrorDialog.acknowledge));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(GamePage), findsNothing);
      expect(find.byType(ErrorDialog), findsNothing);
    },
  );
}
