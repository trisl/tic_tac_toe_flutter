import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/board_view.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/cell_view.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Finder cell(int index) => find.byKey(ValueKey('cell-$index'));

void main() {
  group('BoardView', () {
    testWidgets('renders nine cells', (tester) async {
      await tester.pumpWidget(
        wrap(
          BoardView(board: Board.empty(), winningLine: null, onCellTap: (_) {}),
        ),
      );

      for (var index = 0; index < 9; index++) {
        expect(cell(index), findsOneWidget);
      }
    });

    testWidgets('renders the marks that are on the board', (tester) async {
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty().placeMark(0, Mark.x).placeMark(8, Mark.o),
            winningLine: null,
            onCellTap: (_) {},
          ),
        ),
      );

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
    });

    testWidgets('reports the index of a tapped empty cell', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty(),
            winningLine: null,
            onCellTap: tapped.add,
          ),
        ),
      );

      await tester.tap(cell(4));

      expect(tapped, [4]);
    });

    testWidgets('ignores a tap on a cell that is taken', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty().placeMark(4, Mark.x),
            winningLine: null,
            onCellTap: tapped.add,
          ),
        ),
      );

      await tester.tap(cell(4), warnIfMissed: false);

      expect(tapped, isEmpty);
    });

    testWidgets('ignores every tap when onCellTap is null', (tester) async {
      await tester.pumpWidget(
        wrap(
          BoardView(board: Board.empty(), winningLine: null, onCellTap: null),
        ),
      );

      await tester.tap(cell(0), warnIfMissed: false);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('marks only the winning cells as highlighted', (tester) async {
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty()
                .placeMark(0, Mark.x)
                .placeMark(1, Mark.x)
                .placeMark(2, Mark.x),
            winningLine: const [0, 1, 2],
            onCellTap: null,
          ),
        ),
      );

      for (var index = 0; index < 9; index++) {
        expect(
          tester.widget<CellView>(cell(index)).highlighted,
          index <= 2,
          reason: 'cell $index',
        );
      }
    });

    testWidgets('paints a highlighted cell differently from a plain one', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty(),
            winningLine: const [0, 1, 2],
            onCellTap: null,
          ),
        ),
      );

      Color? colorOf(int index) => tester
          .widget<Material>(
            find.descendant(of: cell(index), matching: find.byType(Material)),
          )
          .color;

      expect(colorOf(0), isNot(colorOf(4)));
    });
  });
}
