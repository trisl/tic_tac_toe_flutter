import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/errors/error_dialog.dart';

Future<void> pumpDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () => showErrorDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('ErrorDialog', () {
    testWidgets('renders the title, message and acknowledge button', (
      tester,
    ) async {
      await pumpDialog(tester);

      expect(find.text(ErrorDialog.title), findsOneWidget);
      expect(find.text(ErrorDialog.message), findsOneWidget);
      expect(find.text(ErrorDialog.acknowledge), findsOneWidget);
    });

    testWidgets('tapping the acknowledge button pops it', (tester) async {
      await pumpDialog(tester);
      expect(find.byType(ErrorDialog), findsOneWidget);

      await tester.tap(find.text(ErrorDialog.acknowledge));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorDialog), findsNothing);
    });

    testWidgets('tapping the barrier does not dismiss it', (tester) async {
      await pumpDialog(tester);
      expect(find.byType(ErrorDialog), findsOneWidget);

      // Tap far outside the dialog's content, on the modal barrier.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorDialog), findsOneWidget);
    });
  });

  group('copy', () {
    test('matches the wording the spec fixes', () {
      expect(ErrorDialog.title, 'Oops, something went wrong');
      expect(
        ErrorDialog.message,
        'Something unexpected happened, and we are taking you back to the '
        'home page.',
      );
      expect(ErrorDialog.acknowledge, 'Understand');
    });
  });
}
