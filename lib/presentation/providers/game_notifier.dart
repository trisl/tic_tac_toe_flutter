import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_providers.dart';
import 'game_ui_state.dart';

/// Owns the turn cycle: the human moves, then the robot answers after a beat.
///
/// The pause lives here rather than in a use case so that the domain stays
/// free of UI timing.
class GameNotifier extends Notifier<GameUiState> {
  bool _disposed = false;
  int _generation = 0;

  @override
  GameUiState build() {
    _disposed = false;
    // A rebuild starts a new game too, so stale replies from the previous
    // one must be invalidated here as well as in startNewGame().
    _generation++;
    ref.onDispose(() => _disposed = true);
    return GameUiState(game: ref.read(startGameProvider)());
  }

  Future<void> playAt(int index) async {
    if (!state.canPlay || !state.game.board.isEmptyAt(index)) {
      return;
    }

    final generation = _generation;
    final afterHuman = ref.read(playHumanMoveProvider)(index);
    state = GameUiState(game: afterHuman);
    if (afterHuman.isOver) {
      return;
    }

    state = state.copyWith(robotThinking: true);
    await Future<void>.delayed(ref.read(robotDelayProvider));
    // A new game started while we were waiting makes this reply stale.
    if (_disposed || generation != _generation) {
      return;
    }
    state = GameUiState(game: ref.read(playRobotMoveProvider)());
  }

  void startNewGame() {
    _generation++;
    state = GameUiState(game: ref.read(startGameProvider)());
  }
}
