import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog_exercise.dart';
import '../models/muscle_group.dart';
import '../state/gym_provider.dart';
import '../widgets/common.dart';
import '../widgets/exercise_demo.dart';
import 'exercise_detail_screen.dart';
import 'settings_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _query = '';
  MuscleGroup? _group;
  String? _equipment;
  String? _level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCustomExerciseEditor(context),
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
            final results = provider.catalog.query(
              text: _query,
              group: _group,
              equipment: _equipment,
              level: _level,
            );
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search 870+ exercises',
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
                      _chip('All', _group == null,
                          () => setState(() => _group = null)),
                      for (final g in MuscleGroup.values)
                        _chip(g.label, _group == g,
                            () => setState(() => _group = g),
                            icon: g.icon, color: g.color),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown(
                          label: 'Equipment',
                          value: _equipment,
                          options: provider.catalog.equipmentOptions,
                          onChanged: (v) => setState(() => _equipment = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterDropdown(
                          label: 'Level',
                          value: _level,
                          options: ExerciseCatalogLevels.all,
                          onChanged: (v) => setState(() => _level = v),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${results.length} exercises',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: results.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'No exercises found',
                          message: 'Try clearing a filter or your search.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: results.length,
                          itemBuilder: (context, i) =>
                              _ExerciseTile(exercise: results[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {IconData? icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        avatar: icon == null ? null : Icon(icon, size: 18, color: color),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Level options exposed for the filter (kept out of the catalog import path).
class ExerciseCatalogLevels {
  static const all = ['beginner', 'intermediate', 'expert'];
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Any')),
        for (final o in options)
          DropdownMenuItem(
            value: o,
            child: Text(
                o.isEmpty ? o : '${o[0].toUpperCase()}${o.substring(1)}',
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});

  final CatalogExercise exercise;

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: e.hasDemo
            ? ExerciseThumb(frame: e.imageUrls.first)
            : MuscleAvatar(group: e.group),
        title: Text(e.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [e.group.label, if (e.equipment != null) e.equipment!].join(' · '),
        ),
        trailing: e.isCustom
            ? IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _customMenu(context, e),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(exercise: e),
          ),
        ),
      ),
    );
  }

  void _customMenu(BuildContext context, CatalogExercise e) {
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
                showCustomExerciseEditor(context, existing: e);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<GymProvider>().deleteCustomExercise(e.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to create or edit a custom exercise.
Future<void> showCustomExerciseEditor(BuildContext context,
    {CatalogExercise? existing}) async {
  final provider = context.read<GymProvider>();
  final nameController = TextEditingController(text: existing?.name ?? '');
  final musclesController = TextEditingController(
      text: existing?.primaryMuscles.join(', ') ?? '');
  MuscleGroup group = existing?.group ?? MuscleGroup.chest;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(existing == null ? 'New exercise' : 'Edit exercise'),
        content: SingleChildScrollView(
          child: Column(
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
                decoration: const InputDecoration(labelText: 'Muscle group'),
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
              const SizedBox(height: 16),
              TextField(
                controller: musclesController,
                decoration: const InputDecoration(
                  labelText: 'Target muscles (optional)',
                  helperText: 'Comma-separated, e.g. lateral deltoid',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    ),
  );

  if (saved == true) {
    final name = nameController.text.trim();
    if (name.isNotEmpty) {
      final muscles = musclesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await provider.saveCustomExercise(CatalogExercise(
        id: existing?.id ?? provider.repository.newCustomId(),
        name: name,
        primaryMuscles: muscles,
        isCustom: true,
        groupOverride: group,
      ));
    }
  }
  nameController.dispose();
  musclesController.dispose();
}
