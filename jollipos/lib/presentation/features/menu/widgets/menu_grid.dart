import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../domain/entities/product.dart';
import '../../../providers/catalog_providers.dart';
import '../../../providers/cart_providers.dart';
import 'modifier_sheet.dart';
import 'product_card.dart';

/// Responsive product grid. Column count scales with available width.
/// Renders entirely from the user-encoded catalog — nothing is hardcoded.
class MenuGrid extends ConsumerWidget {
  const MenuGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    if (productsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final products = ref.watch(filteredProductsProvider);

    // Catalog completely empty -> guide the user to Menu Management.
    if (ref.watch(catalogIsEmptyProvider)) {
      return _EmptyCatalog(onManage: () => context.push(Routes.menuManagement));
    }

    // Catalog has items but none match the current category/search filter.
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
      ..showSnackBar(SnackBar(
          content: Text(msg), duration: const Duration(milliseconds: 900)));
  }
}

/// Shown when the user has not encoded any products yet.
class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.onManage});
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('No products yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Add your items in Menu Management to start taking orders.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.add),
              label: const Text('Open Menu Management'),
            ),
          ],
        ),
      ),
    );
  }
}
