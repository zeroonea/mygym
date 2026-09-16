import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/body_entry.dart';
import '../models/profile.dart';
import '../utils/format.dart';

double? _parse(TextEditingController c) {
  final t = c.text.trim();
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

List<TextInputFormatter> get _decimal =>
    [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

/// Dialog to edit the user's profile. Returns the new [Profile] or null.
Future<Profile?> showProfileEditor(BuildContext context, Profile initial) {
  final birthYear =
      TextEditingController(text: initial.birthYear?.toString() ?? '');
  final height = TextEditingController(
      text: initial.heightCm == null ? '' : formatNumber(initial.heightCm!));
  final target = TextEditingController(
      text:
          initial.targetWeight == null ? '' : formatNumber(initial.targetWeight!));
  var sex = initial.sex;
  var activity = initial.activity;
  var goal = initial.goal;

  return showDialog<Profile>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Your profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Sex>(
                initialValue: sex,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: [
                  for (final s in Sex.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => sex = v ?? sex),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: birthYear,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Birth year', hintText: 'e.g. 1990'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: height,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _decimal,
                decoration:
                    const InputDecoration(labelText: 'Height', suffixText: 'cm'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ActivityLevel>(
                initialValue: activity,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Activity level'),
                items: [
                  for (final a in ActivityLevel.values)
                    DropdownMenuItem(value: a, child: Text(a.label)),
                ],
                onChanged: (v) => setState(() => activity = v ?? activity),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Goal>(
                initialValue: goal,
                decoration: const InputDecoration(labelText: 'Goal'),
                items: [
                  for (final g in Goal.values)
                    DropdownMenuItem(value: g, child: Text(g.label)),
                ],
                onChanged: (v) => setState(() => goal = v ?? goal),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: target,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _decimal,
                decoration: const InputDecoration(
                  labelText: 'Target weight (optional)',
                  suffixText: 'kg',
                  helperText: 'Leave blank to use a healthy-BMI suggestion',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final year = int.tryParse(birthYear.text.trim());
              Navigator.pop(
                ctx,
                initial.copyWith(
                  sex: sex,
                  birthYear: year,
                  heightCm: _parse(height),
                  activity: activity,
                  goal: goal,
                  targetWeight: _parse(target),
                  clearTargetWeight: target.text.trim().isEmpty,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    birthYear.dispose();
    height.dispose();
    target.dispose();
  });
}

/// Bottom sheet to add or edit a body-measurement entry. Returns the entry or
/// null if cancelled.
Future<BodyEntry?> showBodyEntryEditor(BuildContext context,
    {BodyEntry? existing, double? previousWeight}) {
  return showModalBottomSheet<BodyEntry>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _BodyEntryEditor(
          existing: existing, previousWeight: previousWeight),
    ),
  );
}

class _BodyEntryEditor extends StatefulWidget {
  const _BodyEntryEditor({this.existing, this.previousWeight});

  final BodyEntry? existing;
  final double? previousWeight;

  @override
  State<_BodyEntryEditor> createState() => _BodyEntryEditorState();
}

class _BodyEntryEditorState extends State<_BodyEntryEditor> {
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late final Map<String, TextEditingController> _c = {
    'weight': TextEditingController(
        text: _init(widget.existing?.weight ?? widget.previousWeight)),
    'bodyFat': TextEditingController(text: _init(widget.existing?.bodyFat)),
    'neck': TextEditingController(text: _init(widget.existing?.neck)),
    'chest': TextEditingController(text: _init(widget.existing?.chest)),
    'waist': TextEditingController(text: _init(widget.existing?.waist)),
    'hip': TextEditingController(text: _init(widget.existing?.hip)),
    'arm': TextEditingController(text: _init(widget.existing?.arm)),
    'thigh': TextEditingController(text: _init(widget.existing?.thigh)),
    'calf': TextEditingController(text: _init(widget.existing?.calf)),
  };

  static String _init(double? v) => v == null ? '' : formatNumber(v);

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _save() {
    final weight = _parse(_c['weight']!);
    if (weight == null || weight <= 0) return;
    final entry = BodyEntry(
      id: widget.existing?.id,
      date: _date,
      weight: weight,
      bodyFat: _parse(_c['bodyFat']!),
      neck: _parse(_c['neck']!),
      chest: _parse(_c['chest']!),
      waist: _parse(_c['waist']!),
      hip: _parse(_c['hip']!),
      arm: _parse(_c['arm']!),
      thigh: _parse(_c['thigh']!),
      calf: _parse(_c['calf']!),
    );
    Navigator.pop(context, entry);
  }

  Widget _field(String key, String label,
      {String suffix = 'cm', bool autofocus = false}) {
    return TextField(
      controller: _c[key],
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _decimal,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? 'Log measurements' : 'Edit entry',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(formatShortDate(_date)),
                onPressed: _pickDate,
              ),
            ),
            const SizedBox(height: 16),
            _field('weight', 'Weight', suffix: 'kg', autofocus: true),
            const SizedBox(height: 12),
            _field('bodyFat', 'Body fat (optional)', suffix: '%'),
            const SizedBox(height: 20),
            Text('Measurements (optional)',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Neck, waist & hip enable a body-fat estimate.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('neck', 'Neck')),
              const SizedBox(width: 10),
              Expanded(child: _field('chest', 'Chest')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('waist', 'Waist')),
              const SizedBox(width: 10),
              Expanded(child: _field('hip', 'Hip')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('arm', 'Arm')),
              const SizedBox(width: 10),
              Expanded(child: _field('thigh', 'Thigh')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('calf', 'Calf')),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
