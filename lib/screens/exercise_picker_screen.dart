import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog_exercise.dart';
import '../state/gym_provider.dart';
import '../widgets/common.dart';
import '../widgets/exercise_demo.dart';

/// Full-screen picker returning the exercises the user selected to add.
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String _query = '';
  final Map<String, CatalogExercise> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add exercises')),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pop(context, _selected.values.toList()),
              icon: const Icon(Icons.check),
              label: Text('Add ${_selected.length}'),
            ),
      body: SafeArea(
        top: false,
        child: Consumer<GymProvider>(
          builder: (context, provider, _) {
            final results = provider.catalog.query(text: _query);
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
                  child: results.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'No exercises found',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: results.length,
                          itemBuilder: (context, i) {
                            final e = results[i];
                            final checked = _selected.containsKey(e.id);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                value: checked,
                                secondary: e.hasDemo
                                    ? ExerciseThumb(frame: e.imageUrls.first)
                                    : MuscleAvatar(group: e.group),
                                title: Text(e.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(e.group.label),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selected[e.id] = e;
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
