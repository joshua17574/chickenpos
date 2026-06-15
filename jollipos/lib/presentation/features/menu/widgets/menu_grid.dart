import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/product.dart';
import '../../../providers/catalog_providers.dart';
import '../../../providers/cart_providers.dart';
import 'modifier_sheet.dart';
import 'product_card.dart';

/// Responsive product grid. Column count scales with available width.
class MenuGrid extends ConsumerWidget {
  const MenuGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    if (ref.watch(productsProvider).isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (products.isEmpty) {
      return const Center(child: Text('No items match your filter.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = (constraints.maxWidth / 180).floor().clamp(2, 6);
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) {
            final product = products[i];
            return ProductCard(
              product: product,
              onTap: () => _onTap(context, ref, product),
            );
          },
        );
      },
    );
  }

  Future<void> _onTap(
      BuildContext context, WidgetRef ref, Product product) async {
    if (!product.hasModifiers) {
      ref.read(cartControllerProvider.notifier).addProduct(product);
      _toast(context, '${product.name} added');
      return;
    }
    final result = await showModalBottomSheet<ModifierResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ModifierSheet(product: product),
    );
    if (result != null && context.mounted) {
      ref.read(cartControllerProvider.notifier).addProduct(
            product,
            modifiers: result.modifiers,
            quantity: result.quantity,
            note: result.note,
          );
      _toast(context, '${product.name} added');
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)));
  }
}
