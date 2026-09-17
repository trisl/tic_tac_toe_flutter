import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/cell_view.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CellView', () {
    testWidgets('renders X for Mark.x', (tester) async {
      await tester.pumpWidget(
        wrap(
          CellView(index: 0, mark: Mark.x, highlighted: false, onTap: () {}),
        ),
      );

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsNothing);
    });

    testWidgets('renders O for Mark.o', (tester) async {
      await tester.pumpWidget(
        wrap(
          CellView(index: 0, mark: Mark.o, highlighted: false, onTap: () {}),
        ),
      );

      expect(find.text('O'), findsOneWidget);
      expect(find.text('X'), findsNothing);
    });

    testWidgets('renders nothing for an empty cell', (tester) async {
      await tester.pumpWidget(
        wrap(CellView(index: 0, mark: null, highlighted: false, onTap: () {})),
      );

      expect(find.text('X'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('semantics label for an occupied X cell', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          CellView(index: 2, mark: Mark.x, highlighted: false, onTap: () {}),
        ),
      );

      // The child glyph's own Text semantics merges into this node too (no
      // `excludeSemantics` boundary), so the label carries the accessible
      // text as its prefix; that prefix is CellView's actual contract.
      final semantics = tester.getSemantics(find.byType(CellView));
      expect(semantics.label, startsWith('Cell 3, your X'));

      handle.dispose();
    });

    testWidgets('semantics label for an occupied O cell', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          CellView(index: 4, mark: Mark.o, highlighted: false, onTap: () {}),
        ),
      );

      final semantics = tester.getSemantics(find.byType(CellView));
      expect(semantics.label, startsWith("Cell 5, the robot's O"));

      handle.dispose();
    });

    testWidgets('semantics label for an empty cell', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(CellView(index: 8, mark: null, highlighted: false, onTap: () {})),
      );

      final semantics = tester.getSemantics(find.byType(CellView));
      expect(semantics.label, 'Cell 9, empty');
      expect(semantics.label, isNot(contains('X')));
      expect(semantics.label, isNot(contains('O')));

      handle.dispose();
    });

    testWidgets('semantics label appends the winning-line suffix', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(CellView(index: 0, mark: Mark.x, highlighted: true, onTap: () {})),
      );

      final semantics = tester.getSemantics(find.byType(CellView));
      expect(
        semantics.label,
        startsWith('Cell 1, your X, part of the winning line'),
      );

      handle.dispose();
    });

    testWidgets('is announced as an enabled button when onTap is set', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(CellView(index: 0, mark: null, highlighted: false, onTap: () {})),
      );

      final semantics = tester.getSemantics(find.byType(CellView));
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);

      handle.dispose();
    });

    testWidgets('is announced as a disabled button when onTap is null', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          const CellView(index: 0, mark: null, highlighted: false, onTap: null),
        ),
      );

      final semantics = tester.getSemantics(find.byType(CellView));
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);

      handle.dispose();
    });
  });
}
