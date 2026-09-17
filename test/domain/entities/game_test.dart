import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game_status.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/domain/exceptions/invalid_move_exception.dart';

/// Plays [indices] in order, alternating players from the starting position.
Game playAll(List<int> indices) {
  var game = Game.start();
  for (final index in indices) {
    game = game.playAt(index);
  }
  return game;
}

void main() {
  group('Game.start', () {
    test('begins with an empty board and the human to move', () {
      final game = Game.start();

      expect(game.board, Board.empty());
      expect(game.currentPlayer, Mark.x);
      expect(game.status, const InProgress());
      expect(game.isOver, isFalse);
    });
  });

  group('playAt', () {
    test('places the current mark and hands over the turn', () {
      final game = Game.start().playAt(4);

      expect(game.board.cellAt(4), Mark.x);
      expect(game.currentPlayer, Mark.o);
    });

    test('alternates players across moves', () {
      final game = playAll([0, 1, 2]);

      expect(game.board.cellAt(0), Mark.x);
      expect(game.board.cellAt(1), Mark.o);
      expect(game.board.cellAt(2), Mark.x);
      expect(game.currentPlayer, Mark.o);
    });

    test('leaves the previous game untouched', () {
      final first = Game.start();

      first.playAt(0);

      expect(first.board.cellAt(0), isNull);
      expect(first.currentPlayer, Mark.x);
    });

    test('rejects a taken cell', () {
      final game = Game.start().playAt(0);

      expect(() => game.playAt(0), throwsA(isA<InvalidMoveException>()));
    });

    test('rejects any move once the game is over', () {
      // x: 0, 1, 2 wins; o: 3, 4.
      final game = playAll([0, 3, 1, 4, 2]);

      expect(game.isOver, isTrue);
      expect(() => game.playAt(5), throwsA(isA<InvalidMoveException>()));
    });
  });

  group('status', () {
    test('reports a human win with the winning line', () {
      final game = playAll([0, 3, 1, 4, 2]);

      expect(game.status, const Win(Mark.x, [0, 1, 2]));
    });

    test('reports a robot win', () {
      // x: 0, 1, 8; o: 3, 4, 5 wins.
      final game = playAll([0, 3, 1, 4, 8, 5]);

      expect(game.status, const Win(Mark.o, [3, 4, 5]));
      expect(game.isOver, isTrue);
    });

    test('reports a draw when the board fills with no line', () {
      // Final board: x o x / x o o / o x x
      final game = playAll([0, 1, 2, 4, 3, 5, 7, 6, 8]);

      expect(game.board.isFull, isTrue);
      expect(game.status, const Draw());
      expect(game.isOver, isTrue);
    });

    test('is in progress while the board is open and unwon', () {
      final game = playAll([0, 4]);

      expect(game.status, const InProgress());
    });
  });
}
