import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game_status.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_providers.dart';

import '../../helpers/fakes.dart';

/// A container wired with a deterministic robot and no thinking delay.
ProviderContainer containerWith(List<int> robotMoves) {
  final container = ProviderContainer(
    overrides: [
      robotStrategyProvider.overrideWithValue(StubRobotStrategy(robotMoves)),
      robotDelayProvider.overrideWithValue(Duration.zero),
    ],
  );
  addTearDown(container.dispose);
  // An auto-dispose provider needs a subscriber to stay alive across awaits.
  // In the app that subscriber is GamePage's `ref.watch`; here it is this
  // listener. Without it the notifier disposes mid-turn and every await
  // throws "Cannot use the Ref after it has been disposed".
  container.listen(gameNotifierProvider, (previous, next) {});
  return container;
}

void main() {
  group('GameNotifier', () {
    test('starts on an empty board with the human to move', () {
      final container = containerWith([]);

      final state = container.read(gameNotifierProvider);

      expect(state.game.board.emptyCells.length, 9);
      expect(state.game.currentPlayer, Mark.x);
      expect(state.robotThinking, isFalse);
      expect(state.canPlay, isTrue);
    });

    test('plays the human move and then the robot reply', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);

      await notifier.playAt(0);

      final state = container.read(gameNotifierProvider);
      expect(state.game.board.cellAt(0), Mark.x);
      expect(state.game.board.cellAt(4), Mark.o);
      expect(state.game.currentPlayer, Mark.x);
      expect(state.robotThinking, isFalse);
    });

    test('flags robotThinking between the two moves', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);

      // `playAt` runs synchronously up to its first await, so the flag is
      // already set by the time it hands back the future — no sleeping.
      final pending = notifier.playAt(0);

      expect(container.read(gameNotifierProvider).robotThinking, isTrue);
      expect(container.read(gameNotifierProvider).canPlay, isFalse);

      await pending;

      expect(container.read(gameNotifierProvider).robotThinking, isFalse);
    });

    test('ignores a tap on a cell that is already taken', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.playAt(0);

      await notifier.playAt(4);

      expect(container.read(gameNotifierProvider).game.board.cellAt(4), Mark.o);
    });

    test('lets the human win without giving the robot another move', () async {
      // Human takes 0, 1, 2; the robot answers 3 then 4 and never moves again.
      final container = containerWith([3, 4]);
      final notifier = container.read(gameNotifierProvider.notifier);

      await notifier.playAt(0);
      await notifier.playAt(1);
      await notifier.playAt(2);

      final state = container.read(gameNotifierProvider);
      expect(state.game.status, const Win(Mark.x, [0, 1, 2]));
      expect(state.canPlay, isFalse);
    });

    test('ignores taps once the game is over', () async {
      final container = containerWith([3, 4]);
      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.playAt(0);
      await notifier.playAt(1);
      await notifier.playAt(2);

      await notifier.playAt(5);

      expect(container.read(gameNotifierProvider).game.board.cellAt(5), isNull);
    });

    test('startNewGame clears the board', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.playAt(0);

      notifier.startNewGame();

      final state = container.read(gameNotifierProvider);
      expect(state.game.board.emptyCells.length, 9);
      expect(state.game.currentPlayer, Mark.x);
      expect(state.robotThinking, isFalse);
      expect(state.game.status, const InProgress());
    });

    test(
      'a new game started mid-turn is untouched by the pending robot move',
      () async {
        final container = containerWith([4]);
        final notifier = container.read(gameNotifierProvider.notifier);

        final pending = notifier.playAt(0);
        notifier.startNewGame();
        await pending;

        final state = container.read(gameNotifierProvider);
        expect(state.game.board.emptyCells.length, 9);
        expect(state.game.currentPlayer, Mark.x);
        expect(state.robotThinking, isFalse);
      },
    );
  });

  group('GameUiState', () {
    test('cannot play while the robot is thinking', () {
      final container = containerWith([]);
      final state = container.read(gameNotifierProvider);

      expect(state.copyWith(robotThinking: true).canPlay, isFalse);
    });
  });
}
