import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/note_stats.dart';
import '../../../shared/category_colors.dart';
import '../../../shared/formatters.dart';

/// Gráfica circular de notas por categoría con su leyenda.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.categories});

  final List<CategoryStat> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: [
                for (final stat in categories)
                  PieChartSectionData(
                    value: stat.count.toDouble(),
                    color: categoryColor(stat.category),
                    radius: 56,
                    // Solo se rotulan porciones con espacio suficiente.
                    showTitle: stat.percentage >= 8,
                    title: '${stat.percentage.round()} %',
                    titleStyle: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final stat in categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: categoryColor(stat.category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(stat.category, overflow: TextOverflow.ellipsis),
                ),
                Text('${stat.count}', style: theme.textTheme.bodyMedium),
                SizedBox(
                  width: 80,
                  child: Text(
                    formatPercentage(stat.percentage),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
