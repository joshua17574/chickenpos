import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../services/format.dart';
import '../services/store.dart';
import '../theme.dart';
import 'ui.dart';

class CartPanel extends StatefulWidget {
  final ValueChanged<Sale>? onCompleted;
  const CartPanel({super.key, this.onCompleted});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final _cashCtrl = TextEditingController();
  bool _checkingOut = false;

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final cs = Theme.of(context).colorScheme;
    final cashText = _cashCtrl.text.trim();
    final parsedCash = cashText.isEmpty ? 0.0 : double.tryParse(cashText);
    final cash = parsedCash ?? 0;
    final change = cash - store.cartTotal;
    final hasInvalidCash = parsedCash == null;
    final hasShortCash = cash > 0 && cash < store.cartTotal;

    return Container(
      color: cs.surface,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.header.withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Sale',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${store.cartItemCount} item${store.cartItemCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  peso(store.cartTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 4),
                if (store.cart.isNotEmpty)
                  TextButton(
                    onPressed: store.clearCart,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: store.cart.isEmpty
                ? _emptyCart(cs)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: store.cart.keys.map((id) {
                      final p = store.productById(id)!;
                      final qty = store.cart[id]!;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            InitialsAvatar(
                              name: p.name,
                              category: p.category,
                              size: 38,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${peso(p.sell)} x $qty = ${peso(p.sell * qty)}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            QtyStepper(
                              qty: qty,
                              onMinus: () => store.setQty(id, qty - 1),
                              onPlus: () => store.addToCart(id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          // summary
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                _row('Subtotal', peso(store.cartTotal), muted: true, cs: cs),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      peso(store.cartTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                    labelText: 'Cash received (PHP)',
                    errorText: hasInvalidCash ? 'Enter a valid amount' : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: (change >= 0 ? AppColors.success : AppColors.danger)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: change >= 0
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                      Text(
                        peso(change >= 0 ? change : 0),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: change >= 0
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: _checkingOut ? 'Completing...' : 'Complete Sale',
                  icon: Icons.check_circle,
                  onPressed: store.cartItemCount == 0 ||
                          _checkingOut ||
                          hasInvalidCash ||
                          hasShortCash
                      ? null
                      : () => _checkout(context, store, cash),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCart(ColorScheme cs) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyStateArt(size: 72),
            const SizedBox(height: 8),
            Text(
              'Your cart is empty',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a product to add it',
              style: TextStyle(color: cs.outline, fontSize: 12),
            ),
          ],
        ),
      );

  Future<void> _checkout(BuildContext context, Store store, double cash) async {
    final messenger = ScaffoldMessenger.of(context);
    if (cash > 0 && cash < store.cartTotal) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cash is less than total.')),
      );
      return;
    }
    setState(() => _checkingOut = true);
    try {
      final sale = await store.checkout(cash: cash);
      if (!mounted) return;
      _cashCtrl.clear();
      if (widget.onCompleted != null) {
        widget.onCompleted!(sale);
      } else {
        showReceiptDialog(this.context, sale);
      }
    } on CheckoutException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Widget _row(
    String l,
    String r, {
    bool muted = false,
    required ColorScheme cs,
  }) {
    final style = TextStyle(
      fontSize: 14,
      color: muted ? cs.onSurfaceVariant : null,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: style),
        Text(r, style: style),
      ],
    );
  }
}

void showReceiptDialog(BuildContext context, Sale sale) {
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 40),
                  SizedBox(height: 6),
                  Text(
                    'Payment complete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: Colors.black87,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: Text(
                        'CHICKEN CUTS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Center(child: Text(formatDate(sale.ts))),
                    Center(child: Text('Txn ${sale.id}')),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    ...sale.items.map(
                      (it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: Text('${it.name} x${it.qty}')),
                            Text(peso(it.subtotal)),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _rRow('TOTAL', peso(sale.total), bold: true),
                    _rRow('Cash', peso(sale.cash)),
                    _rRow('Change', peso(sale.change)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: 'New Sale',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _rRow(String l, String r, {bool bold = false}) {
  final style = TextStyle(
    color: Colors.black,
    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
  );
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: style),
        Text(r, style: style),
      ],
    ),
  );
}
