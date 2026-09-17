import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/data/services/random_robot_strategy.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';

void main() {
  group('RandomRobotStrategy', () {
    test('only ever picks an empty cell', () {
      final strategy = RandomRobotStrategy(Random(1));
      final board = Board.empty()
          .placeMark(0, Mark.x)
          .placeMark(1, Mark.o)
          .placeMark(2, Mark.x);

      for (var attempt = 0; attempt < 100; attempt++) {
        expect(board.emptyCells, contains(strategy.chooseMove(board)));
      }
    });

    test('takes the last free cell when only one is left', () {
      final strategy = RandomRobotStrategy(Random(7));
      var board = Board.empty();
      for (final index in [0, 1, 2, 3, 4, 5, 6, 7]) {
        board = board.placeMark(index, Mark.x);
      }

      expect(strategy.chooseMove(board), 8);
    });

    test('is deterministic for a given seed', () {
      final first = RandomRobotStrategy(Random(42)).chooseMove(Board.empty());
      final second = RandomRobotStrategy(Random(42)).chooseMove(Board.empty());

      expect(first, second);
    });

    test('spreads its choices over the free cells', () {
      final strategy = RandomRobotStrategy(Random(3));
      final chosen = <int>{};

      for (var attempt = 0; attempt < 200; attempt++) {
        chosen.add(strategy.chooseMove(Board.empty()));
      }

      expect(chosen.length, greaterThan(1));
    });

    test('throws when the board is full', () {
      var board = Board.empty();
      for (var index = 0; index < 9; index++) {
        board = board.placeMark(index, Mark.x);
      }

      expect(
        () => RandomRobotStrategy(Random(0)).chooseMove(board),
        throwsStateError,
      );
    });
  });
}
