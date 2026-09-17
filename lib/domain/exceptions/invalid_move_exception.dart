/// Thrown when a move is not legal for the current board or game.
///
/// The UI makes illegal moves unreachable, so this is a safety net rather
/// than a control-flow path.
class InvalidMoveException implements Exception {
  const InvalidMoveException(this.message);

  final String message;

  @override
  String toString() => 'InvalidMoveException: $message';
}
