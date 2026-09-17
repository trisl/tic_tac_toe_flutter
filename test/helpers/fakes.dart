import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/domain/repositories/game_repository.dart';
import 'package:tic_tac_toe_v2_flutter/domain/services/robot_strategy.dart';

/// An in-test double that exposes what was saved.
class FakeGameRepository implements GameRepository {
  FakeGameRepository([this.current]);

  Game? current;
  int saveCount = 0;

  @override
  Game? getCurrent() => current;

  @override
  void save(Game game) {
    current = game;
    saveCount++;
  }
}

/// Returns the queued moves in order, so robot behaviour is deterministic.
class StubRobotStrategy implements RobotStrategy {
  StubRobotStrategy(this.moves);

  final List<int> moves;
  int calls = 0;

  @override
  int chooseMove(Board board) {
    if (calls >= moves.length) {
      throw StateError('StubRobotStrategy ran out of queued moves.');
    }
    return moves[calls++];
  }
}
