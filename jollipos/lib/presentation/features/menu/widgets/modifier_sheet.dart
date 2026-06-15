import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/modifier.dart';
import '../../../../domain/entities/order_item.dart';
import '../../../../domain/entities/product.dart';
import '../../../providers/catalog_providers.dart';

/// Returned to the caller when "Add to cart" is confirmed.
class ModifierResult {
  const ModifierResult({
    required this.modifiers,
    required this.quantity,
    required this.note,
  });
  final List<SelectedModifier> modifiers;
  final int quantity;
  final String note;
}

/// Bottom sheet to pick size/drink/spice/add-ons, quantity, and a note.
class ModifierSheet extends ConsumerStatefulWidget {
  const ModifierSheet({required this.product, super.key});
  final Product product;

  @override
  ConsumerState<ModifierSheet> createState() => _ModifierSheetState();
}

class _ModifierSheetState extends ConsumerState<ModifierSheet> {
  /// groupId -> set of selected modifier ids.
  final Map<String, Set<String>> _selected = {};
  final _noteController = TextEditingController();
  int _qty = 1;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<ModifierGroup> _groupsFor(List<ModifierGroup> all) => all
      .where((g) => widget.product.modifierGroupIds.contains(g.id))
      .toList();

  void _toggle(ModifierGroup group, String modifierId) {
    setState(() {
      final set = _selected.putIfAbsent(group.id, () => {});
      if (group.selection == ModifierSelection.single) {
        set
          ..clear()
          ..add(modifierId);
      } else {
        if (set.contains(modifierId)) {
          set.remove(modifierId);
        } else if (set.length < group.max) {
          set.add(modifierId);
        }
      }
    });
  }

  String? _validate(List<ModifierGroup> groups) {
    for (final g in groups) {
      final count = _selected[g.id]?.length ?? 0;
      if (g.required && count < g.min) return 'Select ${g.name}';
    }
    return null;
  }

  int _unitPrice(List<ModifierGroup> groups) {
    var price = widget.product.basePriceCentavos;
    for (final g in groups) {
      for (final id in _selected[g.id] ?? const <String>{}) {
        final m = g.options.firstWhere((o) => o.id == id);
        price += m.priceDeltaCentavos;
      }
    }
    return price;
  }

  void _confirm(List<ModifierGroup> groups) {
    final error = _validate(groups);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final mods = <SelectedModifier>[];
    for (final g in groups) {
      for (final id in _selected[g.id] ?? const <String>{}) {
        final m = g.options.firstWhere((o) => o.id == id);
        mods.add(SelectedModifier(
          groupId: g.id,
          modifierId: m.id,
          name: m.name,
          priceDeltaCentavos: m.priceDeltaCentavos,
        ));
      }
    }
    Navigator.of(context).pop(ModifierResult(
      modifiers: mods,
      quantity: _qty,
      note: _noteController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(modifierGroupsProvider);
    return groupsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 200,
        child: Center(child: Text('Failed to load options: $e')),
      ),
      data: (all) {
        final groups = _groupsFor(all);
        final unit = _unitPrice(groups);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.product.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final g in groups) ...[
                  Row(
                    children: [
                      Text(g.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (g.required)
                        const Text(' *', style: TextStyle(color: AppColors.brandRed)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in g.options)
                        FilterChip(
                          label: Text(m.priceDeltaCentavos == 0
                              ? m.name
                              : '${m.name} (+${Money.format(m.priceDeltaCentavos)})'),
                          selected:
                              _selected[g.id]?.contains(m.id) ?? false,
                          onSelected: (_) => _toggle(g, m.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Special instructions (optional)',
                    hintText: 'e.g. no onions',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _QtyStepper(
                      qty: _qty,
                      onMinus: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
                      onPlus: () => setState(() => _qty = (_qty + 1).clamp(1, 99)),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => _confirm(groups),
                        child: Text('Add · ${Money.format(unit * _qty)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton.filledTonal(
            onPressed: onMinus,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 36,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton.filledTonal(
            onPressed: onPlus,
            icon: const Icon(Icons.add),
          ),
        ],
      );
}
