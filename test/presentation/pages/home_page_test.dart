import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/pages/game_page.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/pages/home_page.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_providers.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/routing/app_router.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/game_status_banner.dart';

import '../../helpers/fakes.dart';

Finder cell(int index) => find.byKey(ValueKey('cell-$index'));

Future<AppRouter> pumpApp(WidgetTester tester, List<int> robotMoves) async {
  final router = AppRouter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        robotStrategyProvider.overrideWithValue(StubRobotStrategy(robotMoves)),
        robotDelayProvider.overrideWithValue(Duration.zero),
      ],
      child: MaterialApp.router(routerConfig: router.config()),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('HomePage', () {
    testWidgets('is the first screen', (tester) async {
      await pumpApp(tester, []);

      expect(find.text('Tic Tac Toe'), findsOneWidget);
      expect(find.text('Play a round against the robot.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Play'), findsOneWidget);
      expect(find.byType(GamePage), findsNothing);
    });

    testWidgets('Play opens the game on an empty board', (tester) async {
      await pumpApp(tester, []);

      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePage), findsOneWidget);
      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
      expect(find.text('X'), findsNothing);
    });

    testWidgets('the back arrow returns from the game to the landing page', (
      tester,
    ) async {
      await pumpApp(tester, []);

      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();
      expect(find.byType(GamePage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(GamePage), findsNothing);
      expect(find.text('Play a round against the robot.'), findsOneWidget);
    });

    testWidgets('a second game starts fresh after going back', (tester) async {
      final router = await pumpApp(tester, [4]);

      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();
      await tester.tap(cell(0));
      await tester.pumpAndSettle();
      expect(find.text('X'), findsOneWidget);

      await router.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
    });
  });
}
