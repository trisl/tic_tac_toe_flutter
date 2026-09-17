import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game_status.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';

void main() {
  group('GameStatus', () {
    test('two separately built statuses of the same kind are equal', () {
      // Written without `const` on purpose, so this checks Freezed's
      // generated `==` (value equality) rather than object identity.
      // ignore: prefer_const_constructors
      expect(InProgress(), equals(InProgress()));
      // ignore: prefer_const_constructors
      expect(InProgress().hashCode, equals(InProgress().hashCode));
      // ignore: prefer_const_constructors
      expect(Draw(), equals(Draw()));
      // ignore: prefer_const_constructors
      expect(Draw().hashCode, equals(Draw().hashCode));
    });

    test('an in-progress status is never equal to a draw', () {
      // ignore: prefer_const_constructors
      expect(InProgress(), isNot(equals(Draw())));
    });

    test('two wins are equal only when both winner and line match', () {
      expect(
        const Win(Mark.x, [0, 1, 2]),
        equals(const Win(Mark.x, [0, 1, 2])),
      );
      expect(
        const Win(Mark.x, [0, 1, 2]),
        isNot(equals(const Win(Mark.o, [0, 1, 2]))),
      );
      expect(
        const Win(Mark.x, [0, 1, 2]),
        isNot(equals(const Win(Mark.x, [3, 4, 5]))),
      );
    });
  });
}
