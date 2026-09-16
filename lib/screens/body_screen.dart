import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/body_entry.dart';
import '../models/profile.dart';
import '../state/gym_provider.dart';
import '../utils/format.dart';
import '../utils/health.dart';
import '../widgets/body_editors.dart';
import '../widgets/common.dart';
import 'food_search_screen.dart';

class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  Future<void> _editProfile(BuildContext context, Profile profile) async {
    final updated = await showProfileEditor(context, profile);
    if (updated != null && context.mounted) {
      await context.read<GymProvider>().saveProfile(updated);
    }
  }

  Future<void> _logEntry(BuildContext context,
      {BodyEntry? existing, double? previousWeight}) async {
    final provider = context.read<GymProvider>();
    final entry = await showBodyEntryEditor(context,
        existing: existing, previousWeight: previousWeight);
    if (entry == null) return;
    if (entry.id == null) {
      await provider.addBodyEntry(entry);
    } else {
      await provider.updateBodyEntry(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body'),
        actions: [
          Consumer<GymProvider>(
            builder: (context, provider, _) => IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.person_outline),
              onPressed: () => _editProfile(context, provider.profile),
            ),
          ),
          IconButton(
            tooltip: 'Food search',
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const FoodSearchScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logEntry(context,
            previousWeight: context.read<GymProvider>().currentBodyWeight),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<GymProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile = provider.profile;
            final entries = provider.bodyEntries;
            final latest = entries.isNotEmpty ? entries.first : null;
            final stats = HealthStats.compute(profile: profile, latest: latest);

            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (!profile.isComplete)
                    _SetupCard(
                        onSetup: () => _editProfile(context, profile)),
                  if (!profile.isComplete) const SizedBox(height: 16),
                  if (latest == null)
                    const EmptyState(
                      icon: Icons.monitor_weight_outlined,
                      title: 'No measurements yet',
                      message:
                          'Tap “Log” to record your weight and measurements.',
                    )
                  else ...[
                    _WeightCard(
                      latest: latest,
                      previous: entries.length > 1 ? entries[1] : null,
                      profile: profile,
                    ),
                    const SizedBox(height: 16),
                    _MetricsGrid(stats: stats),
                    if (stats.macros != null) ...[
                      const SizedBox(height: 16),
                      _MacroCard(profile: profile, macros: stats.macros!),
                    ],
                    if (entries.length > 1) ...[
                      const SizedBox(height: 16),
                      _WeightTrendCard(entries: entries),
                    ],
                    const SizedBox(height: 16),
                    _MeasurementsCard(entry: latest),
                    const SizedBox(height: 16),
                    _FoodButton(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FoodSearchScreen())),
                    ),
                    const SizedBox(height: 20),
                    Text('History',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final e in entries)
                      _HistoryTile(
                        entry: e,
                        onTap: () => _logEntry(context, existing: e),
                        onDelete: () =>
                            provider.deleteBodyEntry(e.id!),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add your sex, birth year and height to unlock BMR, TDEE and '
              'macro targets.',
              style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onSetup, child: const Text('Set up')),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard(
      {required this.latest, required this.previous, required this.profile});

  final BodyEntry latest;
  final BodyEntry? previous;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = profile.targetWeight ??
        (profile.heightCm != null
            ? suggestedTargetWeight(profile.heightCm!)
            : null);
    final delta = previous == null ? null : latest.weight - previous!.weight;
    final toTarget = target == null ? null : latest.weight - target;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current weight',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onPrimary)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${formatNumber(latest.weight)} kg',
                  style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              if (delta != null && delta != 0)
                Text(
                  '${delta > 0 ? '▲' : '▼'} ${formatNumber(delta.abs())} kg',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary
                          .withValues(alpha: 0.9)),
                ),
            ],
          ),
          if (target != null) ...[
            const SizedBox(height: 10),
            Text(
              toTarget!.abs() < 0.1
                  ? 'At your target of ${formatNumber(target)} kg 🎯'
                  : '${formatNumber(toTarget.abs())} kg to '
                      '${toTarget > 0 ? 'lose' : 'gain'} '
                      '· target ${formatNumber(target)} kg',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.stats});

  final HealthStats stats;

  @override
  Widget build(BuildContext context) {
    String orDash(double? v, {int decimals = 0}) =>
        v == null ? '—' : v.toStringAsFixed(decimals);

    final tiles = <Widget>[
      StatTile(
        value: orDash(stats.bmi, decimals: 1),
        label: stats.bmiCategory?.label ?? 'BMI',
        icon: Icons.straighten,
      ),
      StatTile(
        value: orDash(stats.bmr),
        unit: 'kcal',
        label: 'BMR',
        icon: Icons.bedtime_outlined,
      ),
      StatTile(
        value: orDash(stats.tdee),
        unit: 'kcal',
        label: 'TDEE',
        icon: Icons.local_fire_department_outlined,
      ),
      StatTile(
        value: orDash(stats.bodyFatPercent, decimals: 1),
        unit: stats.bodyFatPercent == null ? null : '%',
        label: 'Body fat',
        icon: Icons.pie_chart_outline,
      ),
      StatTile(
        value: orDash(stats.leanMass, decimals: 1),
        unit: stats.leanMass == null ? null : 'kg',
        label: 'Lean mass',
        icon: Icons.fitness_center,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 10.0;
      final width = (constraints.maxWidth - spacing * 2) / 3;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final t in tiles) SizedBox(width: width, child: t),
        ],
      );
    });
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.profile, required this.macros});

  final Profile profile;
  final MacroPlan macros;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Daily macro target',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(profile.goal.label, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${macros.calories.round()}',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Text('kcal / day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroPill(
                  label: 'Protein',
                  grams: macros.protein,
                  color: const Color(0xFFEF4444)),
              const SizedBox(width: 10),
              _MacroPill(
                  label: 'Carbs',
                  grams: macros.carbs,
                  color: const Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              _MacroPill(
                  label: 'Fat',
                  grams: macros.fat,
                  color: const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill(
      {required this.label, required this.grams, required this.color});

  final String label;
  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('${grams.round()} g',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({required this.entries});

  final List<BodyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Chronological order for the chart.
    final ordered = entries.reversed.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < ordered.length; i++)
        FlSpot(i.toDouble(), ordered[i].weight),
    ];
    final values = ordered.map((e) => e.weight).toList();
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final pad = (maxV - minV) * 0.2 + 0.5;
    final step = (ordered.length / 4).ceil().clamp(1, ordered.length);

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
            child: Text('Weight trend',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minV - pad,
                maxY: maxV + pad,
                minX: 0,
                maxX: (ordered.length - 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(formatNumber(value),
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
                        if (i < 0 || i >= ordered.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(formatDayMonth(ordered[i].date),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementsCard extends StatelessWidget {
  const _MeasurementsCard({required this.entry});

  final BodyEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, double?)>[
      ('Neck', entry.neck),
      ('Chest', entry.chest),
      ('Waist', entry.waist),
      ('Hip', entry.hip),
      ('Arm', entry.arm),
      ('Thigh', entry.thigh),
      ('Calf', entry.calf),
    ].where((e) => e.$2 != null).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest measurements',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final it in items)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${it.$1} ',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text('${formatNumber(it.$2!)} cm',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodButton extends StatelessWidget {
  const _FoodButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Search foods & macros'),
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(
      {required this.entry, required this.onTap, required this.onDelete});

  final BodyEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = <String>[
      if (entry.bodyFat != null) '${formatNumber(entry.bodyFat!)}% fat',
      if (entry.waist != null) 'waist ${formatNumber(entry.waist!)}',
    ].join('  ·  ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.monitor_weight_outlined,
              color: theme.colorScheme.onPrimaryContainer, size: 20),
        ),
        title: Text('${formatNumber(entry.weight)} kg',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text([
          formatShortDate(entry.date),
          if (extra.isNotEmpty) extra,
        ].join('  ·  ')),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
