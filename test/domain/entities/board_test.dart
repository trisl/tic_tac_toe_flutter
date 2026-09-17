import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/domain/exceptions/invalid_move_exception.dart';

/// Builds a board from a 9-character string: 'x', 'o' or '.' per cell.
Board boardFrom(String pattern) {
  expect(pattern.length, 9, reason: 'a board pattern must have 9 cells');
  return Board([
    for (final char in pattern.split(''))
      switch (char) {
        'x' => Mark.x,
        'o' => Mark.o,
        _ => null,
      },
  ]);
}

void main() {
  group('Mark', () {
    test('opponent flips the mark', () {
      expect(Mark.x.opponent, Mark.o);
      expect(Mark.o.opponent, Mark.x);
    });
  });

  group('Board.empty', () {
    test('has nine empty cells', () {
      final board = Board.empty();

      expect(board.cells.length, 9);
      expect(board.emptyCells, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect(board.isFull, isFalse);
      expect(board.winningLine, isNull);
    });
  });

  group('placeMark', () {
    test('returns a new board with the mark placed', () {
      final board = Board.empty().placeMark(4, Mark.x);

      expect(board.cellAt(4), Mark.x);
      expect(board.isEmptyAt(4), isFalse);
      expect(board.emptyCells, [0, 1, 2, 3, 5, 6, 7, 8]);
    });

    test('leaves the original board untouched', () {
      final original = Board.empty();

      original.placeMark(0, Mark.x);

      expect(original.cellAt(0), isNull);
      expect(original.emptyCells.length, 9);
    });

    test('rejects a cell that is already taken', () {
      final board = Board.empty().placeMark(0, Mark.x);

      expect(
        () => board.placeMark(0, Mark.o),
        throwsA(isA<InvalidMoveException>()),
      );
    });

    test('rejects an index outside 0..8', () {
      expect(
        () => Board.empty().placeMark(-1, Mark.x),
        throwsA(isA<InvalidMoveException>()),
      );
      expect(
        () => Board.empty().placeMark(9, Mark.x),
        throwsA(isA<InvalidMoveException>()),
      );
    });
  });

  group('winningLine', () {
    test('finds each of the three rows', () {
      expect(boardFrom('xxx.o.o..').winningLine, [0, 1, 2]);
      expect(boardFrom('o.oxxx...').winningLine, [3, 4, 5]);
      expect(boardFrom('.oo.x.xxx').winningLine, [6, 7, 8]);
    });

    test('finds each of the three columns', () {
      expect(boardFrom('x.ox.ox..').winningLine, [0, 3, 6]);
      expect(boardFrom('ox.ox..x.').winningLine, [1, 4, 7]);
      expect(boardFrom('o.xo.x..x').winningLine, [2, 5, 8]);
    });

    test('finds both diagonals', () {
      expect(boardFrom('xo.ox...x').winningLine, [0, 4, 8]);
      expect(boardFrom('o.x.x.xo.').winningLine, [2, 4, 6]);
    });

    test('works for the robot too', () {
      expect(boardFrom('ooox.x.x.').winningLine, [0, 1, 2]);
    });

    test('is null when no line is complete', () {
      expect(boardFrom('xoxxoxoxo').winningLine, isNull);
    });
  });

  group('isFull', () {
    test('is true only when every cell is taken', () {
      expect(boardFrom('xoxxoxoxo').isFull, isTrue);
      expect(boardFrom('xoxxoxox.').isFull, isFalse);
    });
  });

  group('equality', () {
    test('two boards with the same cells are equal', () {
      expect(boardFrom('xo.......'), boardFrom('xo.......'));
      expect(boardFrom('xo.......'), isNot(boardFrom('ox.......')));
    });
  });
}
