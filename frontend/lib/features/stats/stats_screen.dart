import 'package:flutter/material.dart';

import '../../models/note_stats.dart';
import '../../services/notes_api.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/status_views.dart';
import 'stats_controller.dart';
import 'widgets/activity_line_chart.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/chart_card.dart';
import 'widgets/summary_cards.dart';

/// Panel con las estadísticas de `GET /api/v1/notes/stats`.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.controller});

  final StatsController controller;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _twoColumnsMinWidth = 900.0;

  StatsController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (_controller.stats == null && !_controller.isLoading) {
      _controller.load();
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _controller.range,
      helpText: 'Selecciona el período',
      saveText: 'Aplicar',
    );
    if (picked == null || !mounted) return;
    if (StatsController.exceedsMaxRange(picked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El período no puede superar ${NotesApi.maxStatsRangeDays} días.',
          ),
        ),
      );
      return;
    }
    await _controller.setRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _controller.load,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Column(
          children: [
            _RangeBar(
              range: _controller.range,
              onPick: _pickRange,
              onClear: () => _controller.setRange(null),
            ),
            if (_controller.isLoading) const LinearProgressIndicator(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final stats = _controller.stats;
    final error = _controller.error;
    if (error != null) {
      return ErrorView(message: error, onRetry: _controller.load);
    }
    if (stats == null) return const SizedBox.shrink();
    if (stats.isEmpty) {
      return EmptyView(
        icon: Icons.insights_outlined,
        title: 'Sin datos',
        message: _controller.range == null
            ? 'Todavía no hay notas para mostrar estadísticas.'
            : 'No hay notas en el período seleccionado.',
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SummaryCards(stats: stats),
            const SizedBox(height: 12),
            ..._buildCharts(stats, constraints.maxWidth >= _twoColumnsMinWidth),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCharts(NoteStats stats, bool twoColumns) {
    final categories = ChartCard(
      title: 'Notas por categoría',
      child: CategoryPieChart(categories: stats.byCategory),
    );
    final activity = ChartCard(
      title: 'Actividad diaria',
      subtitle: 'Notas creadas por día (UTC)',
      child: ActivityLineChart(activity: stats.activity),
    );
    if (!twoColumns) return [categories, const SizedBox(height: 12), activity];
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: categories),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: activity),
        ],
      ),
    ];
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.range,
    required this.onPick,
    required this.onClear,
  });

  final DateTimeRange? range;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final current = range;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              avatar: const Icon(Icons.date_range, size: 18),
              label: Text(
                current == null
                    ? 'Todo el historial'
                    : '${formatDate(current.start)} – ${formatDate(current.end)}',
              ),
              onPressed: onPick,
            ),
            if (current != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Quitar filtro'),
              ),
          ],
        ),
      ),
    );
  }
}
