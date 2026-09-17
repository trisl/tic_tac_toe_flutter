import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/data/repositories/in_memory_game_repository.dart';
import 'package:tic_tac_toe_v2_flutter/data/services/random_robot_strategy.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_providers.dart';

void main() {
  group('game_providers production defaults', () {
    test('robotStrategyProvider defaults to RandomRobotStrategy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(robotStrategyProvider), isA<RandomRobotStrategy>());
    });

    test('robotDelayProvider defaults to 500ms', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(robotDelayProvider),
        const Duration(milliseconds: 500),
      );
    });

    test('gameRepositoryProvider defaults to InMemoryGameRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(gameRepositoryProvider),
        isA<InMemoryGameRepository>(),
      );
    });
  });
}
