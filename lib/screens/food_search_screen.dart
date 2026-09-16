import 'dart:async';

import 'package:flutter/material.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Searches food macro data (Open Food Facts + bundled staples) and shows
/// kcal / protein / carbs / fat, with a per-serving breakdown on tap.
class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _repo = FoodRepository();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<FoodItem> _results = [];
  bool _loading = true;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _run(''); // show common foods initially
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(value));
  }

  Future<void> _run(String query) async {
    final id = ++_requestId;
    setState(() => _loading = true);
    final results = query.trim().isEmpty
        ? await _repo.searchCommon('')
        : await _repo.search(query);
    if (!mounted || id != _requestId) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food search')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search foods (e.g. chicken, oats)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _run('');
                          },
                        ),
                ),
                onChanged: (v) {
                  setState(() {});
                  _onChanged(v);
                },
                onSubmitted: _run,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const EmptyState(
                          icon: Icons.no_meals,
                          title: 'No foods found',
                          message: 'Try a different search term.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _results.length,
                          itemBuilder: (context, i) => _FoodTile(
                            food: _results[i],
                            onTap: () => _showDetail(_results[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(FoodItem food) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FoodDetailSheet(food: food),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.onTap});

  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(food.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              if (food.brand != null) food.brand!,
              '${food.kcal.round()} kcal',
              'P ${formatNumber(food.protein)}',
              'C ${formatNumber(food.carbs)}',
              'F ${formatNumber(food.fat)}',
            ].join('  ·  '),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        trailing: Text('/100g', style: theme.textTheme.labelSmall),
      ),
    );
  }
}

class _FoodDetailSheet extends StatefulWidget {
  const _FoodDetailSheet({required this.food});

  final FoodItem food;

  @override
  State<_FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<_FoodDetailSheet> {
  late final TextEditingController _grams = TextEditingController(
      text: (widget.food.servingGrams ?? 100).round().toString());

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = widget.food;
    final grams = double.tryParse(_grams.text.trim()) ?? 0;
    final m = food.per(grams);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(food.name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (food.brand != null)
            Text(food.brand!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _grams,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount', suffixText: 'g'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              for (final preset in const [100, 150, 200])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ActionChip(
                    label: Text('$preset'),
                    onPressed: () {
                      _grams.text = '$preset';
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: m.kcal.round().toString(),
                      unit: 'kcal',
                      label: 'Energy',
                      icon: Icons.local_fire_department_outlined)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: formatNumber(m.protein),
                      unit: 'g',
                      label: 'Protein',
                      icon: Icons.egg_outlined)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: formatNumber(m.carbs),
                      unit: 'g',
                      label: 'Carbs',
                      icon: Icons.grain)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: formatNumber(m.fat),
                      unit: 'g',
                      label: 'Fat',
                      icon: Icons.opacity)),
            ],
          ),
        ],
      ),
    );
  }
}
