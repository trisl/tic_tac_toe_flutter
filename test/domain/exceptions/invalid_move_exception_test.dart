import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/exceptions/invalid_move_exception.dart';

void main() {
  group('InvalidMoveException', () {
    test('round-trips the message', () {
      const exception = InvalidMoveException('cell is taken');

      expect(exception.message, 'cell is taken');
    });

    test('toString formats as "InvalidMoveException: <message>"', () {
      const exception = InvalidMoveException('cell is taken');

      expect(exception.toString(), 'InvalidMoveException: cell is taken');
    });
  });
}
