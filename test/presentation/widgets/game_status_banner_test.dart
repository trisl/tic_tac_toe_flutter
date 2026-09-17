import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_ui_state.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/game_status_banner.dart';

Game playAll(List<int> indices) {
  var game = Game.start();
  for (final index in indices) {
    game = game.playAt(index);
  }
  return game;
}

Future<void> pumpBanner(WidgetTester tester, GameUiState state) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameStatusBanner(state: state)),
      ),
    );

void main() {
  group('GameStatusBanner', () {
    testWidgets('prompts the human on their turn', (tester) async {
      await pumpBanner(tester, GameUiState(game: Game.start()));

      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
    });

    testWidgets('announces the robot thinking', (tester) async {
      await pumpBanner(
        tester,
        GameUiState(game: Game.start().playAt(0), robotThinking: true),
      );

      expect(find.text(GameStatusBanner.thinking), findsOneWidget);
    });

    testWidgets('announces a human win', (tester) async {
      await pumpBanner(tester, GameUiState(game: playAll([0, 3, 1, 4, 2])));

      expect(find.text(GameStatusBanner.youWin), findsOneWidget);
    });

    testWidgets('announces a robot win', (tester) async {
      await pumpBanner(tester, GameUiState(game: playAll([0, 3, 1, 4, 8, 5])));

      expect(find.text(GameStatusBanner.robotWins), findsOneWidget);
    });

    testWidgets('announces a draw', (tester) async {
      await pumpBanner(
        tester,
        GameUiState(game: playAll([0, 1, 2, 4, 3, 5, 7, 6, 8])),
      );

      expect(find.text(GameStatusBanner.draw), findsOneWidget);
    });
  });

  group('copy', () {
    test('matches the wording the spec fixes', () {
      expect(GameStatusBanner.yourTurn, 'Your turn');
      expect(GameStatusBanner.thinking, 'Robot is thinking\u{2026}');
      expect(GameStatusBanner.youWin, 'You win!');
      expect(GameStatusBanner.robotWins, 'Robot wins!');
      expect(GameStatusBanner.draw, 'Draw');
    });
  });
}
