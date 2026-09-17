import 'package:freezed_annotation/freezed_annotation.dart';

import 'mark.dart';

part 'game_status.freezed.dart';

/// The outcome of a game at a point in time.
@freezed
sealed class GameStatus with _$GameStatus {
  const factory GameStatus.inProgress() = InProgress;
  const factory GameStatus.win(Mark winner, List<int> line) = Win;
  const factory GameStatus.draw() = Draw;
}
