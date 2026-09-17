import 'dart:math';

import '../../domain/entities/board.dart';
import '../../domain/services/robot_strategy.dart';

/// Picks uniformly among the free cells.
///
/// The [Random] is injected so tests can seed it and get a fixed sequence.
class RandomRobotStrategy implements RobotStrategy {
  RandomRobotStrategy([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  int chooseMove(Board board) {
    final free = board.emptyCells;
    if (free.isEmpty) {
      throw StateError('The board is full, the robot has no move to make.');
    }
    return free[_random.nextInt(free.length)];
  }
}
