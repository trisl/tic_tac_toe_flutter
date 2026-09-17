import '../entities/game.dart';
import '../repositories/game_repository.dart';

/// Applies the human player's move to the game in progress.
class PlayHumanMove {
  const PlayHumanMove(this._repository);

  final GameRepository _repository;

  Game call(int index) {
    final current = _repository.getCurrent();
    if (current == null) {
      throw StateError('No game in progress.');
    }
    final next = current.playAt(index);
    _repository.save(next);
    return next;
  }
}
