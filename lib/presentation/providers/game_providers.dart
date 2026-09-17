import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_game_repository.dart';
import '../../data/services/random_robot_strategy.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/robot_strategy.dart';
import '../../domain/usecases/play_human_move.dart';
import '../../domain/usecases/play_robot_move.dart';
import '../../domain/usecases/start_game.dart';
import 'game_notifier.dart';
import 'game_ui_state.dart';

/// Composition root: the only place where interfaces meet implementations.
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => InMemoryGameRepository(),
);

final robotStrategyProvider = Provider<RobotStrategy>(
  (ref) => RandomRobotStrategy(),
);

final startGameProvider = Provider<StartGame>(
  (ref) => StartGame(ref.watch(gameRepositoryProvider)),
);

final playHumanMoveProvider = Provider<PlayHumanMove>(
  (ref) => PlayHumanMove(ref.watch(gameRepositoryProvider)),
);

final playRobotMoveProvider = Provider<PlayRobotMove>(
  (ref) => PlayRobotMove(
    ref.watch(gameRepositoryProvider),
    ref.watch(robotStrategyProvider),
  ),
);

/// How long the robot appears to think before answering.
/// Tests override this with [Duration.zero].
final robotDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 500),
);

// Auto-dispose so that leaving the game page really does end the game:
// re-entering the route rebuilds the notifier and deals a fresh board,
// rather than depending on a caller to reset it first.
final gameNotifierProvider = NotifierProvider<GameNotifier, GameUiState>(
  GameNotifier.new,
  isAutoDispose: true,
);
