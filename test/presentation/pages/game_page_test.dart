import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/pages/game_page.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_providers.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/board_view.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/cell_view.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/game_status_banner.dart';

import '../../helpers/fakes.dart';

Finder cell(int index) => find.byKey(ValueKey('cell-$index'));

Future<void> pumpGamePage(WidgetTester tester, List<int> robotMoves) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          robotStrategyProvider.overrideWithValue(
            StubRobotStrategy(robotMoves),
          ),
          robotDelayProvider.overrideWithValue(Duration.zero),
        ],
        child: const MaterialApp(home: GamePage()),
      ),
    );

void main() {
  group('GamePage', () {
    testWidgets('opens on an empty board prompting the human', (tester) async {
      await pumpGamePage(tester, []);

      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
      expect(find.text('X'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text('Play again'), findsNothing);
    });

    testWidgets('marks the tapped cell and lets the robot reply', (
      tester,
    ) async {
      await pumpGamePage(tester, [4]);

      await tester.tap(cell(0));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
    });

    testWidgets('announces a win and offers a rematch', (tester) async {
      await pumpGamePage(tester, [3, 4]);

      for (final index in [0, 1, 2]) {
        await tester.tap(cell(index));
        await tester.pumpAndSettle();
      }

      expect(find.text(GameStatusBanner.youWin), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);

      // GamePage derives BoardView's winningLine from the game status
      // (`status is Win ? status.line : null`); this proves that wiring
      // reaches CellView end to end, rather than only BoardView's own test
      // which passes a line in directly.
      for (var index = 0; index < 9; index++) {
        expect(
          tester.widget<CellView>(cell(index)).highlighted,
          index <= 2,
          reason: 'cell $index',
        );
      }
    });

    testWidgets('Play again clears the board', (tester) async {
      await pumpGamePage(tester, [3, 4]);
      for (final index in [0, 1, 2]) {
        await tester.tap(cell(index));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
      expect(find.text('Play again'), findsNothing);
    });

    testWidgets('a tap on a taken cell changes nothing', (tester) async {
      await pumpGamePage(tester, [4]);
      await tester.tap(cell(0));
      await tester.pumpAndSettle();

      await tester.tap(cell(0), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
    });

    testWidgets('scrolls instead of overflowing on a short viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpGamePage(tester, []);

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('disables the board while the robot is thinking', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            robotStrategyProvider.overrideWithValue(StubRobotStrategy([4])),
            robotDelayProvider.overrideWithValue(
              const Duration(milliseconds: 100),
            ),
          ],
          child: const MaterialApp(home: GamePage()),
        ),
      );

      await tester.tap(cell(0));
      await tester.pump(); // one frame: the human move landed, robot pending

      expect(find.text(GameStatusBanner.thinking), findsOneWidget);
      expect(
        tester.widget<BoardView>(find.byType(BoardView)).onCellTap,
        isNull,
      );

      // A tap now must be ignored entirely.
      await tester.tap(cell(1), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
    });
  });
}
