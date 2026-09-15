import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/media_helpers.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../state/gym_provider.dart';
import '../widgets/common.dart';
import '../widgets/exercise_demo.dart';
import 'exercise_detail_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _query = '';
  MuscleGroup? _filter;

  List<Exercise> _apply(List<Exercise> all) {
    return all.where((e) {
      final matchesQuery = _query.isEmpty ||
          e.name.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = _filter == null || e.group == _filter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExerciseEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<GymProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final exercises = _apply(provider.exercises);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search exercises',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                      ),
                      for (final g in MuscleGroup.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            avatar: Icon(g.icon, size: 18, color: g.color),
                            label: Text(g.label),
                            selected: _filter == g,
                            onSelected: (_) =>
                                setState(() => _filter = g),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: exercises.isEmpty
                      ? const EmptyState(
                          icon: Icons.fitness_center,
                          title: 'No exercises found',
                          message: 'Try a different search or add a new one.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: exercises.length,
                          itemBuilder: (context, i) {
                            final e = exercises[i];
                            final media = mediaFor(e.name);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading:
                                    media != null && media.frames.isNotEmpty
                                        ? ExerciseThumb(frame: media.frames.first)
                                        : MuscleAvatar(group: e.group),
                                title: Text(e.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(e.group.label),
                                trailing: e.isCustom
                                    ? IconButton(
                                        icon: const Icon(Icons.more_vert),
                                        onPressed: () =>
                                            _showExerciseMenu(context, e),
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ExerciseDetailScreen(exercise: e),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showExerciseMenu(BuildContext context, Exercise exercise) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                showExerciseEditor(context, existing: exercise);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(ctx);
                await context
                    .read<GymProvider>()
                    .deleteExercise(exercise.id!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a dialog to create or edit a (custom) exercise.
Future<void> showExerciseEditor(BuildContext context,
    {Exercise? existing}) async {
  final provider = context.read<GymProvider>();
  final nameController = TextEditingController(text: existing?.name ?? '');
  MuscleGroup group = existing?.group ?? MuscleGroup.chest;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(existing == null ? 'New exercise' : 'Edit exercise'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MuscleGroup>(
                  initialValue: group,
                  decoration:
                      const InputDecoration(labelText: 'Muscle group'),
                  items: [
                    for (final g in MuscleGroup.values)
                      DropdownMenuItem(
                        value: g,
                        child: Row(
                          children: [
                            Icon(g.icon, size: 18, color: g.color),
                            const SizedBox(width: 8),
                            Text(g.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => group = v ?? group),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save')),
            ],
          );
        },
      );
    },
  );

  if (saved == true) {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    if (existing == null) {
      await provider.addExercise(
        Exercise(name: name, muscleGroup: group.name, isCustom: true),
      );
    } else {
      await provider.updateExercise(
        existing.copyWith(name: name, muscleGroup: group.name),
      );
    }
  }
  nameController.dispose();
}
