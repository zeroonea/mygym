import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../state/gym_provider.dart';
import '../widgets/common.dart';
import 'exercises_screen.dart';

/// Full-screen picker returning the ids of the exercises the user selected.
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String _query = '';
  final Set<int> _selected = {};

  List<Exercise> _apply(List<Exercise> all) {
    if (_query.isEmpty) return all;
    return all
        .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create new',
            onPressed: () => showExerciseEditor(context),
          ),
        ],
      ),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pop(context, _selected.toList()),
              icon: const Icon(Icons.check),
              label: Text('Add ${_selected.length}'),
            ),
      body: SafeArea(
        top: false,
        child: Consumer<GymProvider>(
          builder: (context, provider, _) {
            final exercises = _apply(provider.exercises);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search exercises',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: exercises.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'No exercises found',
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: exercises.length,
                          itemBuilder: (context, i) {
                            final e = exercises[i];
                            final checked = _selected.contains(e.id);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                value: checked,
                                secondary: MuscleAvatar(group: e.group),
                                title: Text(e.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(e.group.label),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selected.add(e.id!);
                                  } else {
                                    _selected.remove(e.id);
                                  }
                                }),
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
}
