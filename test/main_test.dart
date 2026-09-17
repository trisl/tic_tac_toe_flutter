import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/main.dart' as app;
import 'package:tic_tac_toe_v2_flutter/main.dart';

void main() {
  testWidgets('the app boots on the landing page', (tester) async {
    await tester.pumpWidget(const TicTacToeAppRoot());
    await tester.pumpAndSettle();

    expect(find.text('Tic Tac Toe'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('main() runs the real app via runApp', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Tic Tac Toe'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
}
