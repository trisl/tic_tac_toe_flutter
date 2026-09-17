import '../entities/game.dart';
import '../repositories/game_repository.dart';

/// Begins a new game, discarding any game already in progress.
class StartGame {
  const StartGame(this._repository);

  final GameRepository _repository;

  Game call() {
    final game = Game.start();
    _repository.save(game);
    return game;
  }
}
