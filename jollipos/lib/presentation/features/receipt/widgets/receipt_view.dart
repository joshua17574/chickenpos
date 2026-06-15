import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money.dart';
import '../../../../domain/entities/order.dart';

/// On-screen receipt — a narrow, monospace-styled card that mirrors the printed
/// ESC/POS layout.
class ReceiptView extends StatelessWidget {
  const ReceiptView({required this.order, required this.storeName, super.key});

  final Order order;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final mono = const TextStyle(fontFamily: 'monospace', fontSize: 13);
    final df = DateFormat('yyyy-MM-dd HH:mm');

    Widget kv(String l, int c, {bool bold = false}) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: mono.copyWith(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text(Money.format(c),
                style: mono.copyWith(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(storeName,
                    textAlign: TextAlign.center,
                    style: mono.copyWith(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Official Receipt',
                    textAlign: TextAlign.center, style: mono),
                const Divider(),
                Text('Order #${order.orderNumber}', style: mono),
                Text('Queue ${order.queueNumber}', style: mono),
                Text('Type: ${order.type.label}', style: mono),
                Text(df.format(order.createdAt), style: mono),
                const Divider(),
                for (final it in order.items) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Text('${it.quantity}x ${it.name}',
                              style: mono)),
                      Text(Money.format(it.lineTotalCentavos), style: mono),
                    ],
                  ),
                  for (final m in it.modifiers)
                    Text('   + ${m.name}',
                        style: mono.copyWith(fontSize: 11)),
                  if (it.note.isNotEmpty)
                    Text('   * ${it.note}',
                        style: mono.copyWith(
                            fontSize: 11, fontStyle: FontStyle.italic)),
                ],
                const Divider(),
                kv('Subtotal', order.subtotalCentavos),
                if (order.discountCentavos > 0)
                  kv(order.discountType.label, -order.discountCentavos),
                kv('VAT (${(order.vatRate * 100).round()}%)', order.vatCentavos),
                kv('TOTAL', order.totalCentavos, bold: true),
                const Divider(),
                for (final p in order.payments) ...[
                  kv(p.method.label, p.amountCentavos),
                  if (p.changeCentavos > 0) kv('Change', p.changeCentavos),
                ],
                const SizedBox(height: 12),
                Text('Thank you, come again!',
                    textAlign: TextAlign.center,
                    style: mono.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
