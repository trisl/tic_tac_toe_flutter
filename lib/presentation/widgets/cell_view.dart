import 'package:flutter/material.dart';

import '../../domain/entities/mark.dart';

/// One square of the board.
///
/// [onTap] is null when the square cannot be played, which also greys it out.
class CellView extends StatelessWidget {
  const CellView({
    super.key,
    required this.index,
    required this.mark,
    required this.highlighted,
    required this.onTap,
  });

  final int index;
  final Mark? mark;

  /// True when this cell is part of the winning line.
  final bool highlighted;

  final VoidCallback? onTap;

  String get _symbol => switch (mark) {
    Mark.x => 'X',
    Mark.o => 'O',
    null => '',
  };

  String get _semanticsLabel {
    final occupant = switch (mark) {
      Mark.x => 'your X',
      Mark.o => "the robot's O",
      null => 'empty',
    };
    return highlighted
        ? 'Cell ${index + 1}, $occupant, part of the winning line'
        : 'Cell ${index + 1}, $occupant';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: _semanticsLabel,
      button: true,
      enabled: onTap != null,
      child: Material(
        color: highlighted
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              _symbol,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: mark == Mark.x ? colors.primary : colors.tertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
