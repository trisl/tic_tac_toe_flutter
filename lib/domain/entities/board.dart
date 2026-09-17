import 'package:freezed_annotation/freezed_annotation.dart';

import '../exceptions/invalid_move_exception.dart';
import 'mark.dart';

part 'board.freezed.dart';

/// An immutable 3x3 board, stored as nine cells in row-major order.
@freezed
abstract class Board with _$Board {
  const Board._();

  @Assert('cells.length == 9', 'a board has 9 cells')
  const factory Board(List<Mark?> cells) = _Board;

  factory Board.empty() => Board(List<Mark?>.filled(9, null));

  static const int size = 9;

  /// The eight lines that win a game: three rows, three columns, two diagonals.
  static const List<List<int>> lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  Mark? cellAt(int index) => cells[index];

  bool isEmptyAt(int index) => cells[index] == null;

  List<int> get emptyCells => [
    for (var index = 0; index < size; index++)
      if (cells[index] == null) index,
  ];

  bool get isFull => emptyCells.isEmpty;

  /// The indices of the first complete line, or `null` when there is none.
  List<int>? get winningLine {
    for (final line in lines) {
      final mark = cells[line[0]];
      if (mark != null && cells[line[1]] == mark && cells[line[2]] == mark) {
        return line;
      }
    }
    return null;
  }

  /// Returns a new board with [mark] placed at [index].
  ///
  /// Throws [InvalidMoveException] when [index] is out of range or taken.
  Board placeMark(int index, Mark mark) {
    if (index < 0 || index >= size) {
      throw InvalidMoveException('Cell index $index is outside 0..8.');
    }
    if (cells[index] != null) {
      throw InvalidMoveException('Cell $index is already taken.');
    }
    final next = List<Mark?>.of(cells);
    next[index] = mark;
    return Board(next);
  }
}
