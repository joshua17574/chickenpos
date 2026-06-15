import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/format.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (store.lowStockCount > 0 || store.outOfStockCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${store.lowStockCount} low-stock - ${store.outOfStockCount} out of stock',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: store.products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = store.products[i];
                final low = p.stock > 0 && p.stock <= Store.lowStockThreshold;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.header.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 62,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.category(p.category).withValues(
                            alpha: 0.07,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ProductVisual(
                          name: p.name,
                          category: p.category,
                          height: 52,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sell ${peso(p.sell)} - Buy ${peso(p.buy)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (p.stock <= 0)
                            const StatusPill(
                              text: 'Out',
                              color: AppColors.danger,
                            )
                          else if (low)
                            StatusPill(
                              text: '${p.stock} left',
                              color: AppColors.warning,
                            )
                          else
                            StatusPill(
                              text: '${p.stock} pcs',
                              color: AppColors.success,
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _iconBtn(
                                Icons.edit_outlined,
                                AppColors.primary,
                                () => _editDialog(context, store, p),
                              ),
                              _iconBtn(
                                Icons.delete_outline,
                                AppColors.danger,
                                () => _confirmDelete(context, store, p),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _editDialog(context, store, null),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData i, Color c, VoidCallback f) => IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(i, color: c, size: 20),
        onPressed: f,
      );

  void _confirmDelete(BuildContext context, Store store, Product p) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete product?'),
        content: Text('Remove "${p.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              try {
                await store.deleteProduct(p.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editDialog(BuildContext context, Store store, Product? p) {
    final name = TextEditingController(text: p?.name ?? '');
    final cat = TextEditingController(text: p?.category ?? '');
    final sell = TextEditingController(text: p == null ? '' : '${p.sell}');
    final buy = TextEditingController(text: p == null ? '' : '${p.buy}');
    final stock = TextEditingController(text: p == null ? '' : '${p.stock}');

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          p == null ? 'Add Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, 'Name'),
              _field(cat, 'Category'),
              _field(sell, 'Selling Price (PHP)', number: true),
              _field(buy, 'Buying Price (PHP)', number: true),
              _field(stock, 'Stock', number: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final s = double.tryParse(sell.text) ?? 0;
              final b = double.tryParse(buy.text) ?? 0;
              final st = int.tryParse(stock.text) ?? 0;
              try {
                if (p == null) {
                  await store.addProduct(
                    name: name.text,
                    category: cat.text,
                    sell: s,
                    buy: b,
                    stock: st,
                  );
                } else {
                  await store.updateProduct(
                    p.id,
                    name: name.text,
                    category: cat.text,
                    sell: s,
                    buy: b,
                    stock: st,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                final message = e is ArgumentError
                    ? e.message?.toString() ?? 'Product details are invalid.'
                    : e.toString();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }
}
