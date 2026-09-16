import 'package:flutter/material.dart';

import '../models/catalog_exercise.dart';
import '../models/muscle_group.dart';
import 'muscle_map.dart';

/// A card summarising which muscles a set of exercises works, with a body map
/// and per-group chips. Used to show the muscles trained on a workout day.
class MuscleSummaryCard extends StatelessWidget {
  const MuscleSummaryCard({super.key, required this.exercises});

  final List<CatalogExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primary = <String>{};
    final secondary = <String>{};
    final groupCounts = <MuscleGroup, int>{};
    for (final e in exercises) {
      primary.addAll(e.primaryMuscles);
      secondary.addAll(e.secondaryMuscles);
      groupCounts.update(e.group, (v) => v + 1, ifAbsent: () => 1);
    }
    secondary.removeAll(primary);

    // Order groups by how many exercises hit them (desc).
    final groups = groupCounts.keys.toList()
      ..sort((a, b) => groupCounts[b]!.compareTo(groupCounts[a]!));

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
              Icon(Icons.accessibility_new,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${groups.length} muscle ${groups.length == 1 ? 'group' : 'groups'} worked',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in groups)
                _GroupChip(group: g, count: groupCounts[g]!),
            ],
          ),
          if (primary.isNotEmpty || secondary.isNotEmpty) ...[
            const SizedBox(height: 16),
            MuscleMap(primary: primary, secondary: secondary, height: 210),
          ],
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.group, required this.count});

  final MuscleGroup group;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: group.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(group.icon, size: 16, color: group.color),
          const SizedBox(width: 6),
          Text(group.label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: group.color)),
          ),
        ],
      ),
    );
  }
}
