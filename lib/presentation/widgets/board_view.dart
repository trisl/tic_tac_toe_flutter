import 'package:flutter/material.dart';

import '../../domain/entities/board.dart';
import 'cell_view.dart';

/// The 3x3 grid.
///
/// Passing a null [onCellTap] disables the whole board, which is how the UI
/// stops the human moving out of turn or after the game ends.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.winningLine,
    required this.onCellTap,
  });

  final Board board;
  final List<int>? winningLine;
  final void Function(int index)? onCellTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: Board.size,
        itemBuilder: (context, index) {
          final mark = board.cellAt(index);
          final playable = onCellTap != null && mark == null;
          return CellView(
            key: ValueKey('cell-$index'),
            index: index,
            mark: mark,
            highlighted: winningLine?.contains(index) ?? false,
            onTap: playable ? () => onCellTap!(index) : null,
          );
        },
      ),
    );
  }
}
