import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';

/// Holds the current game for the lifetime of the app.
///
/// Nothing is persisted: closing the app discards the game, which is what the
/// product asks for.
class InMemoryGameRepository implements GameRepository {
  Game? _game;

  @override
  Game? getCurrent() => _game;

  @override
  void save(Game game) => _game = game;
}
