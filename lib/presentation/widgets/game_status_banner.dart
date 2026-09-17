import 'package:flutter/material.dart';

import '../../domain/entities/game_status.dart';
import '../../domain/entities/mark.dart';
import '../providers/game_ui_state.dart';

/// The single line of text above the board.
class GameStatusBanner extends StatelessWidget {
  const GameStatusBanner({super.key, required this.state});

  static const String yourTurn = 'Your turn';
  static const String thinking = 'Robot is thinking…';
  static const String youWin = 'You win!';
  static const String robotWins = 'Robot wins!';
  static const String draw = 'Draw';

  final GameUiState state;

  String get message => switch (state.game.status) {
    Win(winner: final winner) => winner == Mark.x ? youWin : robotWins,
    Draw() => draw,
    InProgress() => state.robotThinking ? thinking : yourTurn,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}
