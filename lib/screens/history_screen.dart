import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../state/gym_provider.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Workout workout) async {
    final provider = context.read<GymProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text(
            'This will remove the workout and all its logged sets.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await provider.deleteWorkout(workout.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        top: false,
        child: Consumer<GymProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final workouts = provider.workouts;
            if (workouts.isEmpty) {
              return const EmptyState(
                icon: Icons.history,
                title: 'No workouts yet',
                message: 'Your finished and in-progress workouts appear here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: workouts.length,
              itemBuilder: (context, i) {
                final w = workouts[i];
                return Dismissible(
                  key: ValueKey(w.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _confirmDelete(context, w);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.delete,
                        color:
                            Theme.of(context).colorScheme.onErrorContainer),
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const MuscleAvatarPlaceholder(),
                      title: Text(w.name ?? 'Workout',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(formatFullDate(w.date)),
                      trailing: w.completed
                          ? const Icon(Icons.check_circle,
                              color: Colors.green)
                          : Chip(
                              label: const Text('In progress'),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                            ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutDetailScreen(workoutId: w.id!),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
