import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game_status.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/domain/usecases/play_human_move.dart';
import 'package:tic_tac_toe_v2_flutter/domain/usecases/play_robot_move.dart';
import 'package:tic_tac_toe_v2_flutter/domain/usecases/start_game.dart';

import '../../helpers/fakes.dart';

void main() {
  group('StartGame', () {
    test('returns a fresh game and saves it', () {
      final repository = FakeGameRepository();

      final game = StartGame(repository)();

      expect(game, Game.start());
      expect(repository.current, Game.start());
      expect(repository.saveCount, 1);
    });

    test('replaces a game already in progress', () {
      final repository = FakeGameRepository(Game.start().playAt(0));

      final game = StartGame(repository)();

      expect(game.board.emptyCells.length, 9);
      expect(game.currentPlayer, Mark.x);
    });
  });

  group('PlayHumanMove', () {
    test('applies the move and saves the result', () {
      final repository = FakeGameRepository(Game.start());

      final game = PlayHumanMove(repository)(4);

      expect(game.board.cellAt(4), Mark.x);
      expect(repository.current, game);
      expect(repository.saveCount, 1);
    });

    test('throws when no game is in progress', () {
      final repository = FakeGameRepository();

      expect(() => PlayHumanMove(repository)(0), throwsStateError);
    });
  });

  group('PlayRobotMove', () {
    test('plays the move the strategy chose and saves it', () {
      final repository = FakeGameRepository(Game.start().playAt(0));
      final strategy = StubRobotStrategy([4]);

      final game = PlayRobotMove(repository, strategy)();

      expect(game.board.cellAt(4), Mark.o);
      expect(game.currentPlayer, Mark.x);
      expect(repository.current, game);
    });

    test('does nothing once the game is over', () {
      // x has already won with 0, 1, 2.
      var finished = Game.start();
      for (final index in [0, 3, 1, 4, 2]) {
        finished = finished.playAt(index);
      }
      final repository = FakeGameRepository(finished);
      final strategy = StubRobotStrategy([5]);

      final game = PlayRobotMove(repository, strategy)();

      expect(game, finished);
      expect(game.status, const Win(Mark.x, [0, 1, 2]));
      expect(strategy.calls, 0);
      expect(repository.saveCount, 0);
    });

    test('throws when no game is in progress', () {
      final repository = FakeGameRepository();

      expect(
        () => PlayRobotMove(repository, StubRobotStrategy([0]))(),
        throwsStateError,
      );
    });
  });
}
