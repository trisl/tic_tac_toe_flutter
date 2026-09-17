import '../entities/game.dart';
import '../repositories/game_repository.dart';
import '../services/robot_strategy.dart';

/// Lets the robot answer the human's move.
///
/// Returns the game unchanged when it has already ended, so callers do not
/// have to re-check the status themselves.
class PlayRobotMove {
  const PlayRobotMove(this._repository, this._strategy);

  final GameRepository _repository;
  final RobotStrategy _strategy;

  Game call() {
    final current = _repository.getCurrent();
    if (current == null) {
      throw StateError('No game in progress.');
    }
    if (current.isOver) {
      return current;
    }
    final next = current.playAt(_strategy.chooseMove(current.board));
    _repository.save(next);
    return next;
  }
}
