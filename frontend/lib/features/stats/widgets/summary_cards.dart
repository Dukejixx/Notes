import 'package:flutter/material.dart';

import '../../../models/note_stats.dart';

/// Indicadores principales: total, categoría más usada y número de categorías.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.stats});

  final NoteStats stats;

  static const _spacing = 12.0;
  static const _minCardWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        icon: Icons.notes,
        label: 'Total de notas',
        value: '${stats.totalNotes}',
      ),
      _SummaryCard(
        icon: Icons.star_outline,
        label: 'Categoría más usada',
        value: stats.mostUsedCategory ?? '—',
      ),
      _SummaryCard(
        icon: Icons.category_outlined,
        label: 'Categorías',
        value: '${stats.byCategory.length}',
      ),
    ];
    // Reparte el ancho disponible en 1, 2 o 3 columnas sin dejar huecos.
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ((constraints.maxWidth + _spacing) / (_minCardWidth + _spacing))
                .floor()
                .clamp(1, cards.length);
        final cardWidth =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
