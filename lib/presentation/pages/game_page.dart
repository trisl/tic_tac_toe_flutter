import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_status.dart';
import '../providers/game_providers.dart';
import '../widgets/board_view.dart';
import '../widgets/game_status_banner.dart';

@RoutePage()
class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);
    final status = state.game.status;

    return Scaffold(
      appBar: AppBar(title: const Text('Tic Tac Toe')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Centres the board when there is room, and scrolls rather than
            // overflowing when there is not.
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameStatusBanner(state: state),
                          const SizedBox(height: 24),
                          BoardView(
                            board: state.game.board,
                            winningLine: status is Win ? status.line : null,
                            onCellTap: state.canPlay ? notifier.playAt : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: state.game.isOver
                                ? FilledButton(
                                    onPressed: notifier.startNewGame,
                                    child: const Text('Play again'),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
