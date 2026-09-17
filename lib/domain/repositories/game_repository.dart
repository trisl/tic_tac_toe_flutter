import '../entities/game.dart';

/// Stores the game currently being played.
abstract interface class GameRepository {
  /// The game in progress, or `null` when none has been started.
  Game? getCurrent();

  void save(Game game);
}
