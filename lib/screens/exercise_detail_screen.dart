import 'package:flutter/material.dart';

import '../data/media_helpers.dart';
import '../models/exercise.dart';
import '../widgets/exercise_demo.dart';
import '../widgets/muscle_map.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  String _pretty(String muscle) => muscle
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = mediaFor(exercise.name);
    final muscles = musclesFor(exercise);
    final orderedMuscles = [
      ...muscles.primary,
      ...muscles.secondary.where((m) => !muscles.primary.contains(m)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              Icon(exercise.group.icon, color: exercise.group.color, size: 20),
              const SizedBox(width: 8),
              Text(exercise.group.label,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          if (media != null && media.frames.isNotEmpty) ...[
            ExerciseDemo(frames: media.frames, height: 240),
            const SizedBox(height: 6),
            Center(
              child: Text('Animated demo',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 20),
          ],
          _SectionTitle('Muscles worked'),
          const SizedBox(height: 4),
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
                    label: Text(_pretty(m)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: muscles.primary.contains(m)
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            MuscleMap(primary: muscles.primary, secondary: muscles.secondary),
          ],
          if (media != null && media.instructions.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle('How to perform'),
            const SizedBox(height: 8),
            for (var i = 0; i < media.instructions.length; i++)
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
                      child: Text(media.instructions[i],
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
          if (exercise.notes != null && exercise.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle('Notes'),
            const SizedBox(height: 8),
            Text(exercise.notes!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
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
