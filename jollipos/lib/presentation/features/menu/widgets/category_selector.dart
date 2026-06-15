import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/catalog_providers.dart';

/// Horizontal, fast-switching category chips ("All" + each category).
class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () =>
                ref.read(selectedCategoryProvider.notifier).state = null,
          ),
          for (final c in categories)
            _Chip(
              label: c.name,
              selected: selected == c.id,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = c.id,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
