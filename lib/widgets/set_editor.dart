import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/format.dart';

/// The outcome of the set editor: the entered weight/reps, an optional
/// bodyweight snapshot (for bodyweight exercises), plus whether the user asked
/// to immediately log another set.
typedef SetEditorResult = ({
  double weight,
  int reps,
  double? bodyWeight,
  bool again
});

/// Shows a fast set-entry sheet with +/- steppers and keyboard entry.
///
/// [allowAddAnother] adds a "Save & next" action for rapid multi-set logging.
/// For a bodyweight exercise, pass [isBodyweight] and the current [bodyWeight]
/// so volume/1RM can count the lifter's bodyweight toward the load.
Future<SetEditorResult?> showSetEditor(
  BuildContext context, {
  double? weight,
  int? reps,
  bool allowAddAnother = true,
  String? exerciseName,
  bool isBodyweight = false,
  double? bodyWeight,
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
        isBodyweight: isBodyweight,
        bodyWeight: bodyWeight,
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
    this.isBodyweight = false,
    this.bodyWeight,
  });

  final double? initialWeight;
  final int? initialReps;
  final bool allowAddAnother;
  final String? exerciseName;
  final bool isBodyweight;
  final double? bodyWeight;

  @override
  State<_SetEditor> createState() => _SetEditorState();
}

class _SetEditorState extends State<_SetEditor> {
  late double _weight =
      widget.initialWeight ?? (widget.isBodyweight ? 0 : 20);
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
      context,
      (
        weight: w < 0 ? 0 : w,
        reps: r,
        bodyWeight: widget.isBodyweight ? widget.bodyWeight : null,
        again: again,
      ),
    );
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
          if (widget.isBodyweight) ...[
            _BodyweightBanner(bodyWeight: widget.bodyWeight),
            const SizedBox(height: 16),
          ],
          _StepperField(
            label: widget.isBodyweight ? 'Added weight' : 'Weight',
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

class _BodyweightBanner extends StatelessWidget {
  const _BodyweightBanner({this.bodyWeight});

  final double? bodyWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = bodyWeight != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.accessibility_new,
              size: 20, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              known
                  ? 'Bodyweight ${formatWeight(bodyWeight!)} kg counts toward '
                      'volume. Add extra load below if any.'
                  : 'Bodyweight exercise. Log your weight in the Body tab to '
                      'count it toward volume.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            ),
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
