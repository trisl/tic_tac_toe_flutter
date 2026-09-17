import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/data/repositories/in_memory_game_repository.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';

void main() {
  group('InMemoryGameRepository', () {
    test('has no game before one is saved', () {
      expect(InMemoryGameRepository().getCurrent(), isNull);
    });

    test('returns the game that was saved', () {
      final repository = InMemoryGameRepository();
      final game = Game.start();

      repository.save(game);

      expect(repository.getCurrent(), game);
    });

    test('keeps only the most recent game', () {
      final repository = InMemoryGameRepository()..save(Game.start());

      repository.save(Game.start().playAt(0));

      expect(repository.getCurrent()!.board.cellAt(0), Mark.x);
    });

    test('two instances do not share state', () {
      final first = InMemoryGameRepository()..save(Game.start());
      final second = InMemoryGameRepository();

      expect(first.getCurrent(), isNotNull);
      expect(second.getCurrent(), isNull);
    });
  });
}
