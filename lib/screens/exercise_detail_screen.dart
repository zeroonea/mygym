import 'package:flutter/material.dart';

import '../data/muscle_taxonomy.dart';
import '../models/catalog_exercise.dart';
import '../widgets/exercise_demo.dart';
import '../widgets/muscle_map.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final CatalogExercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = exercise;
    final orderedMuscles = [
      ...e.primaryMuscles,
      ...e.secondaryMuscles.where((m) => !e.primaryMuscles.contains(m)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Icon(e.group.icon, color: e.group.color, size: 20),
              const SizedBox(width: 8),
              Text(e.group.label,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (e.equipment != null)
                _MetaChip(icon: Icons.fitness_center, label: e.equipment!),
              if (e.level != null)
                _MetaChip(icon: Icons.signal_cellular_alt, label: e.level!),
              if (e.mechanic != null)
                _MetaChip(icon: Icons.settings, label: e.mechanic!),
              if (e.isCustom)
                _MetaChip(icon: Icons.person, label: 'Custom'),
            ],
          ),
          const SizedBox(height: 18),
          if (e.hasDemo) ...[
            ExerciseDemo(frames: e.imageUrls, height: 240),
            const SizedBox(height: 6),
            Center(
              child: Text('Animated demo',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 20),
          ],
          _SectionTitle('Muscles worked'),
          const SizedBox(height: 8),
          if (orderedMuscles.isEmpty)
            Text('No muscle data for this exercise.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant))
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in orderedMuscles)
                  Chip(
                    label: Text(prettyMuscle(m)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: e.primaryMuscles.contains(m)
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            MuscleMap(
              primary: e.primaryMuscles.toSet(),
              secondary: e.secondaryMuscles.toSet(),
            ),
          ],
          if (e.instructions.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle('How to perform'),
            const SizedBox(height: 8),
            for (var i = 0; i < e.instructions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  theme.colorScheme.onSecondaryContainer)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.instructions[i],
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
          if (e.notes != null && e.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle('Notes'),
            const SizedBox(height: 8),
            Text(e.notes!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(_titleCase(label), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}
