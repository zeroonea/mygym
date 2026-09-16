import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aggregates.dart';
import '../models/catalog_exercise.dart';
import '../models/exercise_set.dart';
import '../state/gym_provider.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/exercise_demo.dart';
import '../widgets/set_editor.dart';
import 'exercise_detail_screen.dart';
import 'exercise_picker_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final int workoutId;

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  WorkoutDetail? _detail;
  bool _loading = true;

  GymProvider get _provider => context.read<GymProvider>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail =
        await _provider.repository.getWorkoutDetail(widget.workoutId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  Future<void> _reload() async {
    await _load();
    await _provider.notifyWorkoutChanged();
  }

  Future<void> _addExercises() async {
    final selected = await Navigator.of(context).push<List<CatalogExercise>>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (selected == null || selected.isEmpty) return;
    for (final e in selected) {
      await _provider.repository.addExerciseToWorkout(widget.workoutId, e);
    }
    await _reload();
  }

  Future<void> _removeExercise(int workoutExerciseId) async {
    await _provider.repository.removeWorkoutExercise(workoutExerciseId);
    await _reload();
  }

  Future<void> _addSet(SetGroup group) async {
    double? weight = group.sets.isNotEmpty ? group.sets.last.weight : null;
    int? reps = group.sets.isNotEmpty ? group.sets.last.reps : null;
    var again = true;
    while (again) {
      if (!mounted) return;
      final result = await showSetEditor(
        context,
        weight: weight,
        reps: reps,
        allowAddAnother: true,
        exerciseName: group.exercise.name,
      );
      if (result == null) break;
      await _provider.repository.addSet(
        group.workoutExercise.id!,
        weight: result.weight,
        reps: result.reps,
      );
      weight = result.weight;
      reps = result.reps;
      again = result.again;
    }
    await _reload();
  }

  Future<void> _editSet(ExerciseSet set) async {
    final result = await showSetEditor(
      context,
      weight: set.weight,
      reps: set.reps,
      allowAddAnother: false,
    );
    if (result == null) return;
    await _provider.repository
        .updateSet(set.copyWith(weight: result.weight, reps: result.reps));
    await _reload();
  }

  Future<void> _deleteSet(int id) async {
    await _provider.repository.deleteSet(id);
    await _reload();
  }

  Future<void> _renameWorkout() async {
    final controller =
        TextEditingController(text: _detail?.workout.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Workout name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Push Day'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    final workout = _detail!.workout;
    await _provider.saveWorkout(
        workout.copyWith(name: name.isEmpty ? null : name));
    await _reload();
  }

  Future<void> _changeDate() async {
    final workout = _detail!.workout;
    final picked = await showDatePicker(
      context: context,
      initialDate: workout.date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    await _provider.saveWorkout(workout.copyWith(
        date: DateTime(picked.year, picked.month, picked.day,
            workout.date.hour, workout.date.minute)));
    await _reload();
  }

  Future<void> _toggleComplete() async {
    final workout = _detail!.workout;
    await _provider
        .saveWorkout(workout.copyWith(completed: !workout.completed));
    await _reload();
  }

  Future<void> _deleteWorkout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('This removes the workout and all its sets.'),
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
    if (ok != true) return;
    await _provider.deleteWorkout(widget.workoutId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.workout.name ?? 'Workout'),
        actions: [
          if (detail != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    _renameWorkout();
                  case 'date':
                    _changeDate();
                  case 'delete':
                    _deleteWorkout();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'date', child: Text('Change date')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      bottomNavigationBar: detail == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  style: detail.workout.completed
                      ? FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary)
                      : null,
                  onPressed: _toggleComplete,
                  icon: Icon(detail.workout.completed
                      ? Icons.lock_open
                      : Icons.check),
                  label: Text(detail.workout.completed
                      ? 'Reopen workout'
                      : 'Finish workout'),
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Workout not found',
                )
              : _buildBody(detail),
    );
  }

  Widget _buildBody(WorkoutDetail detail) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.event, size: 18),
              label: Text(formatFullDate(detail.workout.date)),
              onPressed: _changeDate,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: StatTile(
                    value: '${detail.exerciseCount}',
                    label: 'Exercises',
                    icon: Icons.list_alt)),
            const SizedBox(width: 10),
            Expanded(
                child: StatTile(
                    value: '${detail.totalSets}',
                    label: 'Sets',
                    icon: Icons.repeat)),
            const SizedBox(width: 10),
            Expanded(
                child: StatTile(
                    value: formatVolume(detail.totalVolume),
                    unit: 'kg',
                    label: 'Volume',
                    icon: Icons.monitor_weight_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        if (detail.groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: EmptyState(
              icon: Icons.add_task,
              title: 'No exercises yet',
              message: 'Add exercises, then log your sets.',
              action: FilledButton.icon(
                onPressed: _addExercises,
                icon: const Icon(Icons.add),
                label: const Text('Add exercises'),
              ),
            ),
          )
        else ...[
          for (final group in detail.groups) _ExerciseCard(
            group: group,
            onAddSet: () => _addSet(group),
            onEditSet: _editSet,
            onDeleteSet: _deleteSet,
            onRemove: () => _removeExercise(group.workoutExercise.id!),
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ExerciseDetailScreen(exercise: group.exercise),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addExercises,
            icon: const Icon(Icons.add),
            label: const Text('Add exercises'),
          ),
        ],
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.group,
    required this.onAddSet,
    required this.onEditSet,
    required this.onDeleteSet,
    required this.onRemove,
    required this.onOpen,
  });

  final SetGroup group;
  final VoidCallback onAddSet;
  final void Function(ExerciseSet set) onEditSet;
  final void Function(int id) onDeleteSet;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  Widget _leadingVisual() {
    final e = group.exercise;
    if (e.hasDemo) return ExerciseThumb(frame: e.imageUrls.first, size: 38);
    return MuscleAvatar(group: e.group, size: 38);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          _leadingVisual(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(group.exercise.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                Text(group.exercise.group.label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Icon(Icons.info_outline,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove exercise',
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (group.sets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text('No sets logged yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              )
            else
              ...group.sets.map((set) => _SetRow(
                    set: set,
                    onTap: () => onEditSet(set),
                    onDelete: () => onDeleteSet(set.id!),
                  )),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.onTap,
    required this.onDelete,
  });

  final ExerciseSet set;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text('${set.setNumber}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSecondaryContainer)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyLarge,
                  children: [
                    TextSpan(
                        text: formatWeight(set.weight),
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(
                        text: ' kg  ×  ',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                    TextSpan(
                        text: '${set.reps}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(
                        text: ' reps',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            Text('1RM ${formatWeight(set.estimatedOneRepMax)}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
