import 'package:freezed_annotation/freezed_annotation.dart';

import '../exceptions/invalid_move_exception.dart';
import 'board.dart';
import 'game_status.dart';
import 'mark.dart';

part 'game.freezed.dart';

/// A game in progress: the board plus whose turn it is.
///
/// The status is derived from the board rather than stored, so it can never
/// drift out of sync with it.
@freezed
abstract class Game with _$Game {
  const Game._();

  const factory Game({required Board board, required Mark currentPlayer}) =
      _Game;

  factory Game.start() => Game(board: Board.empty(), currentPlayer: Mark.x);

  GameStatus get status {
    final line = board.winningLine;
    if (line != null) {
      return Win(board.cellAt(line.first)!, line);
    }
    if (board.isFull) {
      return const Draw();
    }
    return const InProgress();
  }

  bool get isOver => status is! InProgress;

  /// Returns the game that follows from the current player taking [index].
  ///
  /// Throws [InvalidMoveException] when the game is over or the cell is not
  /// playable.
  Game playAt(int index) {
    if (isOver) {
      throw const InvalidMoveException('The game is already over.');
    }
    return Game(
      board: board.placeMark(index, currentPlayer),
      currentPlayer: currentPlayer.opponent,
    );
  }
}
