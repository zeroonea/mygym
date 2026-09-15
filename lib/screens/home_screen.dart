import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../state/gym_provider.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'workout_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _startWorkout(BuildContext context) async {
    final provider = context.read<GymProvider>();
    final id = await provider.startWorkout();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(workoutId: id),
      ),
    );
  }

  Future<void> _openWorkout(BuildContext context, int id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Consumer<GymProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final summary = provider.weekSummary;
            final workouts = provider.workouts;
            final active =
                workouts.where((w) => !w.completed).toList();
            final recent = workouts.take(6).toList();

            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text('MyGym',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Let\'s train.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  _WeekCard(
                    workouts: summary.workoutCount,
                    sets: summary.totalSets,
                    volume: summary.totalVolume,
                  ),
                  const SizedBox(height: 16),
                  if (active.isNotEmpty)
                    _ResumeCard(
                      workout: active.first,
                      onTap: () => _openWorkout(context, active.first.id!),
                    ),
                  if (active.isNotEmpty) const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _startWorkout(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Start a workout'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Recent workouts',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No workouts yet. Tap “Start a workout” to begin.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  else
                    ...recent.map(
                      (w) => _WorkoutTile(
                        workout: w,
                        onTap: () => _openWorkout(context, w.id!),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.workouts,
    required this.sets,
    required this.volume,
  });

  final int workouts;
  final int sets;
  final double volume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text('This week',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              _WeekStat(value: '$workouts', label: 'Workouts'),
              _WeekStat(value: '$sets', label: 'Sets'),
              _WeekStat(
                  value: formatVolume(volume), label: 'Volume (kg)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.workout, required this.onTap});

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.play_circle_fill,
            color: theme.colorScheme.onTertiaryContainer),
        title: Text(workout.name ?? 'Workout in progress',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onTertiaryContainer)),
        subtitle: Text('Started ${relativeDay(workout.date)} · tap to resume',
            style:
                TextStyle(color: theme.colorScheme.onTertiaryContainer)),
        trailing: Icon(Icons.chevron_right,
            color: theme.colorScheme.onTertiaryContainer),
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({required this.workout, required this.onTap});

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: const MuscleAvatarPlaceholder(),
        title: Text(workout.name ?? 'Workout',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(relativeDay(workout.date)),
        trailing: workout.completed
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
