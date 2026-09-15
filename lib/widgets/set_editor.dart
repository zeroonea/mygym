import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/format.dart';

/// The outcome of the set editor: the entered weight/reps plus whether the
/// user asked to immediately log another set.
typedef SetEditorResult = ({double weight, int reps, bool again});

/// Shows a fast set-entry sheet with +/- steppers and keyboard entry.
///
/// [allowAddAnother] adds a "Save & next" action for rapid multi-set logging.
Future<SetEditorResult?> showSetEditor(
  BuildContext context, {
  double? weight,
  int? reps,
  bool allowAddAnother = true,
  String? exerciseName,
}) {
  return showModalBottomSheet<SetEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _SetEditor(
        initialWeight: weight,
        initialReps: reps,
        allowAddAnother: allowAddAnother,
        exerciseName: exerciseName,
      ),
    ),
  );
}

class _SetEditor extends StatefulWidget {
  const _SetEditor({
    this.initialWeight,
    this.initialReps,
    required this.allowAddAnother,
    this.exerciseName,
  });

  final double? initialWeight;
  final int? initialReps;
  final bool allowAddAnother;
  final String? exerciseName;

  @override
  State<_SetEditor> createState() => _SetEditorState();
}

class _SetEditorState extends State<_SetEditor> {
  late double _weight = widget.initialWeight ?? 20;
  late int _reps = widget.initialReps ?? 10;
  late final TextEditingController _weightController =
      TextEditingController(text: formatWeight(_weight));
  late final TextEditingController _repsController =
      TextEditingController(text: '$_reps');

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _setWeight(double value) {
    _weight = value < 0 ? 0 : value;
    _weightController.text = formatWeight(_weight);
    setState(() {});
  }

  void _setReps(int value) {
    _reps = value < 0 ? 0 : value;
    _repsController.text = '$_reps';
    setState(() {});
  }

  void _submit({required bool again}) {
    final w = double.tryParse(_weightController.text.trim()) ?? _weight;
    final r = int.tryParse(_repsController.text.trim()) ?? _reps;
    if (r <= 0) return;
    Navigator.pop<SetEditorResult>(
        context, (weight: w < 0 ? 0 : w, reps: r, again: again));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exerciseName ?? 'Log set',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          _StepperField(
            label: 'Weight',
            unit: 'kg',
            controller: _weightController,
            allowDecimal: true,
            onDecrement: () => _setWeight(_weight - 2.5),
            onIncrement: () => _setWeight(_weight + 2.5),
            onChanged: (v) => _weight = double.tryParse(v) ?? _weight,
          ),
          const SizedBox(height: 16),
          _StepperField(
            label: 'Reps',
            controller: _repsController,
            allowDecimal: false,
            onDecrement: () => _setReps(_reps - 1),
            onIncrement: () => _setReps(_reps + 1),
            onChanged: (v) => _reps = int.tryParse(v) ?? _reps,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submit(again: false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save'),
                ),
              ),
              if (widget.allowAddAnother) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _submit(again: true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Save & next'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    this.unit,
    required this.controller,
    required this.allowDecimal,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChanged,
  });

  final String label;
  final String? unit;
  final TextEditingController controller;
  final bool allowDecimal;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: [
            _RoundIconButton(icon: Icons.remove, onPressed: onDecrement),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.numberWithOptions(
                    decimal: allowDecimal),
                inputFormatters: [
                  if (allowDecimal)
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  else
                    FilteringTextInputFormatter.digitsOnly,
                ],
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                decoration: InputDecoration(suffixText: unit),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            _RoundIconButton(icon: Icons.add, onPressed: onIncrement),
          ],
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
