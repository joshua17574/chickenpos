import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../domain/entities/enums.dart';
import '../../../providers/cart_providers.dart';
import 'cart_line_tile.dart';
import 'order_type_selector.dart';

/// The live order panel. Hosted in the tablet side rail and the phone bottom
/// sheet. [onCheckout] is invoked when the order is ready to pay.
class CartPanel extends ConsumerWidget {
  const CartPanel({required this.onCheckout, super.key});
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final draft = ref.watch(draftOrderProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Text('Current Order', style: theme.textTheme.titleLarge),
              const Spacer(),
              if (cart.isNotEmpty)
                TextButton.icon(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear'),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const OrderTypeSelector(),
        ),
        const Divider(height: 20),
        Expanded(
          child: cart.isEmpty
              ? const _EmptyCart()
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final item in cart.items)
                      CartLineTile(item: item),
                  ],
                ),
        ),
        if (cart.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DiscountRow(
                  discountType: cart.discountType,
                  onPick: () => _pickDiscount(context, ref),
                ),
                const SizedBox(height: 8),
                _line(theme, 'Subtotal', draft.subtotalCentavos),
                if (draft.discountCentavos > 0)
                  _line(theme, draft.discountType.label,
                      -draft.discountCentavos),
                _line(theme, 'VAT (${(draft.vatRate * 100).round()}%)',
                    draft.vatCentavos,
                    muted: true),
                const SizedBox(height: 4),
                _line(theme, 'TOTAL', draft.totalCentavos, emphasize: true),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: onCheckout,
                    icon: const Icon(Icons.point_of_sale),
                    label: Text('Charge ${Money.format(draft.totalCentavos)}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _line(ThemeData theme, String label, int centavos,
      {bool emphasize = false, bool muted = false}) {
    final style = emphasize
        ? theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800, color: AppColors.brandRed)
        : theme.textTheme.bodyMedium?.copyWith(
            color: muted ? theme.hintColor : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(Money.format(centavos), style: style),
        ],
      ),
    );
  }

  Future<void> _pickDiscount(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(cartControllerProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('No discount'),
              onTap: () {
                controller.setDiscount(DiscountType.none);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.elderly),
              title: const Text('Senior / PWD (VAT-exempt + 20%)'),
              onTap: () {
                controller.setDiscount(DiscountType.seniorPwd);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer),
              title: const Text('Promo code'),
              onTap: () {
                Navigator.pop(context);
                _promoDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promoDialog(BuildContext context, WidgetRef ref) async {
    final codeCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apply promo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Promo code'),
            ),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Discount amount (₱)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply')),
        ],
      ),
    );
    if (ok == true) {
      final pesos = double.tryParse(amtCtrl.text) ?? 0;
      ref.read(cartControllerProvider.notifier).setDiscount(
            DiscountType.promo,
            promoCode: codeCtrl.text.trim(),
            promoCentavos: Money.toCentavos(pesos),
          );
    }
  }
}

class _DiscountRow extends StatelessWidget {
  const _DiscountRow({required this.discountType, required this.onPick});
  final DiscountType discountType;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.discount_outlined, size: 18),
        label: Text(discountType == DiscountType.none
            ? 'Add discount'
            : 'Discount: ${discountType.label}'),
      );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 56, color: Theme.of(context).hintColor),
            const SizedBox(height: 8),
            Text('Cart is empty',
                style: Theme.of(context).textTheme.bodyLarge),
            const Text('Tap items to add them'),
          ],
        ),
      );
}
