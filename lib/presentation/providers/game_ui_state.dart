import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/game.dart';

part 'game_ui_state.freezed.dart';

/// Everything the game screen needs to render one frame.
@freezed
abstract class GameUiState with _$GameUiState {
  const GameUiState._();

  const factory GameUiState({
    required Game game,
    @Default(false) bool robotThinking,
  }) = _GameUiState;

  /// Whether a tap on an empty cell should be accepted.
  bool get canPlay => !robotThinking && !game.isOver;
}
