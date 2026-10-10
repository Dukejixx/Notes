import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/note_stats.dart';
import '../../../shared/formatters.dart';

/// Gráfica de líneas de notas creadas por día. La API ya incluye los días sin
/// notas con valor 0, así que la línea no tiene saltos.
class ActivityLineChart extends StatelessWidget {
  const ActivityLineChart({super.key, required this.activity});

  final List<DailyActivity> activity;

  /// Número aproximado de etiquetas en el eje X para que no se solapen.
  static const _maxBottomLabels = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final maxCount = activity.fold<int>(
      0,
      (max, day) => math.max(max, day.count),
    );
    final labelEvery = math.max(1, (activity.length / _maxBottomLabels).ceil());
    final yInterval = math.max(1, (maxCount / 4).ceil()).toDouble();

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, activity.length - 1).toDouble(),
          minY: 0,
          maxY: (maxCount + yInterval).toDouble(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: yInterval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 ||
                      index >= activity.length ||
                      index % labelEvery != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      formatShortDate(activity[index].date),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${formatDate(activity[spot.x.toInt()].date)}\n'
                    '${spot.y.toInt()} ${spot.y == 1 ? 'nota' : 'notas'}',
                    TextStyle(color: theme.colorScheme.onInverseSurface),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < activity.length; i++)
                  FlSpot(i.toDouble(), activity[i].count.toDouble()),
              ],
              color: color,
              barWidth: 3,
              // Línea recta: una curva sugeriría valores intermedios inexistentes.
              isCurved: false,
              dotData: FlDotData(show: activity.length <= 31),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
