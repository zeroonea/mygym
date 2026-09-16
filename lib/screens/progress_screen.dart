import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aggregates.dart';
import '../models/catalog_exercise.dart';
import '../state/gym_provider.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<CatalogExercise> _exercises = [];
  CatalogExercise? _selected;
  List<ProgressPoint> _points = [];
  bool _loading = true;

  GymProvider get _provider => context.read<GymProvider>();

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final list = await _provider.repository.exercisesWithHistory();
    if (!mounted) return;
    setState(() {
      _exercises = list;
      _selected = list.isNotEmpty ? list.first : null;
      _loading = false;
    });
    if (_selected != null) {
      await _loadPoints(_selected!);
    }
  }

  Future<void> _loadPoints(CatalogExercise exercise) async {
    final points = await _provider.repository.exerciseProgress(exercise.id);
    if (!mounted) return;
    setState(() => _points = points);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _exercises.isEmpty
                ? const EmptyState(
                    icon: Icons.insights,
                    title: 'No data yet',
                    message:
                        'Log some sets and your progress charts will show up here.',
                  )
                : RefreshIndicator(
                    onRefresh: _loadExercises,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _buildSelector(),
                        const SizedBox(height: 16),
                        if (_points.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                                child: Text('No sets logged for this exercise')),
                          )
                        else ...[
                          _buildPrCards(),
                          const SizedBox(height: 20),
                          _buildChartCard(
                            title: 'Estimated 1RM',
                            values: _points
                                .map((p) => p.bestOneRepMax)
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          _buildChartCard(
                            title: 'Top set weight',
                            values:
                                _points.map((p) => p.bestWeight).toList(),
                          ),
                          const SizedBox(height: 16),
                          _buildChartCard(
                            title: 'Volume per session',
                            values: _points.map((p) => p.volume).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSelector() {
    return DropdownButtonFormField<CatalogExercise>(
      initialValue: _selected,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Exercise'),
      items: [
        for (final e in _exercises)
          DropdownMenuItem(
            value: e,
            child: Row(
              children: [
                Icon(e.group.icon, size: 18, color: e.group.color),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(e.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      onChanged: (e) {
        if (e == null) return;
        setState(() => _selected = e);
        _loadPoints(e);
      },
    );
  }

  Widget _buildPrCards() {
    final bestWeight =
        _points.map((p) => p.bestWeight).reduce(math.max);
    final bestOrm =
        _points.map((p) => p.bestOneRepMax).reduce(math.max);
    final totalVolume =
        _points.fold<double>(0, (sum, p) => sum + p.volume);
    return Row(
      children: [
        Expanded(
            child: StatTile(
                value: formatWeight(bestWeight),
                unit: 'kg',
                label: 'Best set',
                icon: Icons.emoji_events_outlined)),
        const SizedBox(width: 10),
        Expanded(
            child: StatTile(
                value: formatWeight(bestOrm),
                unit: 'kg',
                label: 'Best 1RM',
                icon: Icons.trending_up)),
        const SizedBox(width: 10),
        Expanded(
            child: StatTile(
                value: formatVolume(totalVolume),
                unit: 'kg',
                label: 'Total vol.',
                icon: Icons.summarize_outlined)),
      ],
    );
  }

  Widget _buildChartCard({required String title, required List<double> values}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _LineChartView(points: _points, values: values),
          ),
        ],
      ),
    );
  }
}

class _LineChartView extends StatelessWidget {
  const _LineChartView({required this.points, required this.values});

  final List<ProgressPoint> points;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final pad = (maxValue - minValue) * 0.15 + 1;
    final maxY = maxValue + pad;
    final minY = math.max(0, minValue - pad);

    // Show at most ~5 date labels along the x axis.
    final step = (points.length / 5).ceil().clamp(1, points.length);

    return LineChart(
      LineChartData(
        minY: minY.toDouble(),
        maxY: maxY,
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(formatWeight(value),
                    style: theme.textTheme.bodySmall);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: step.toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(formatDayMonth(points[i].date),
                      style: theme.textTheme.bodySmall),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: spots.length <= 12,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: theme.colorScheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
