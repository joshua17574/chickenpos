import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/payment.dart';
import '../../providers/cart_providers.dart';
import '../../providers/checkout_providers.dart';
import 'widgets/payment_sheet.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(draftOrderProvider);
    final payments = ref.watch(checkoutControllerProvider);
    final paid = payments.fold<int>(0, (s, p) => s + p.amountCentavos);
    final balance = (draft.totalCentavos - paid).clamp(0, 1 << 62);
    final fullyPaid = paid >= draft.totalCentavos && draft.totalCentavos > 0;
    final changeDue = payments
        .where((p) => p.method == PaymentMethod.cash)
        .fold<int>(0, (s, p) => s + p.changeCentavos);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(
                    subtotal: draft.subtotalCentavos,
                    discountLabel: draft.discountType.label,
                    discount: draft.discountCentavos,
                    vat: draft.vatCentavos,
                    vatRate: draft.vatRate,
                    total: draft.totalCentavos,
                    type: draft.type,
                    unitCount: draft.unitCount,
                  ),
                  const SizedBox(height: 16),
                  Text('Payments',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (payments.isEmpty)
                    const Text('No payment added yet.')
                  else
                    for (final p in payments)
                      _PaymentTile(
                        payment: p,
                        onRemove: () => ref
                            .read(checkoutControllerProvider.notifier)
                            .removePayment(p.id),
                      ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final m in PaymentMethod.values)
                        OutlinedButton.icon(
                          onPressed: balance <= 0
                              ? null
                              : () => _addPayment(context, m, balance),
                          icon: Icon(_iconFor(m)),
                          label: Text(m.label),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _PayBar(
              balance: balance,
              changeDue: changeDue,
              fullyPaid: fullyPaid,
              onComplete: () => _complete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PaymentMethod m) => switch (m) {
        PaymentMethod.cash => Icons.payments,
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.eWallet => Icons.qr_code_2,
      };

  Future<void> _addPayment(
      BuildContext context, PaymentMethod method, int balance) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PaymentSheet(method: method, balanceCentavos: balance),
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final order =
        await ref.read(checkoutControllerProvider.notifier).finalizeOrder();
    if (context.mounted) {
      context.pushReplacement('/receipt', extra: order);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.subtotal,
    required this.discountLabel,
    required this.discount,
    required this.vat,
    required this.vatRate,
    required this.total,
    required this.type,
    required this.unitCount,
  });

  final int subtotal, discount, vat, total, unitCount;
  final String discountLabel;
  final double vatRate;
  final OrderType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget line(String l, int c, {bool emph = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l,
                  style: emph
                      ? theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)
                      : null),
              Text(Money.format(c),
                  style: emph
                      ? theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandRed)
                      : null),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type.label, style: theme.textTheme.titleMedium),
                Text('$unitCount item(s)'),
              ],
            ),
            const Divider(),
            line('Subtotal', subtotal),
            if (discount > 0) line(discountLabel, -discount),
            line('VAT (${(vatRate * 100).round()}%)', vat),
            const Divider(),
            line('TOTAL', total, emph: true),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.onRemove});
  final Payment payment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: AppColors.success),
          title: Text(
              '${payment.method.label} · ${Money.format(payment.amountCentavos)}'),
          subtitle: payment.reference.isNotEmpty
              ? Text('Ref: ${payment.reference}')
              : (payment.changeCentavos > 0
                  ? Text('Tendered ${Money.format(payment.tenderedCentavos)} · '
                      'Change ${Money.format(payment.changeCentavos)}')
                  : null),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ),
      );
}

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.balance,
    required this.changeDue,
    required this.fullyPaid,
    required this.onComplete,
  });

  final int balance;
  final int changeDue;
  final bool fullyPaid;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fullyPaid ? 'Change due' : 'Balance due',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  Money.format(fullyPaid ? changeDue : balance),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: fullyPaid
                            ? AppColors.success
                            : AppColors.brandRed,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: fullyPaid ? onComplete : null,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Complete Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
