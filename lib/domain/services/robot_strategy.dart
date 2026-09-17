import '../entities/board.dart';

/// Chooses the robot's move.
///
/// Implementations must return an index drawn from [Board.emptyCells], and
/// must throw a [StateError] when the board is full.
abstract interface class RobotStrategy {
  int chooseMove(Board board);
}
