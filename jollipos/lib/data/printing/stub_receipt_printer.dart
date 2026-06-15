import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/money.dart';
import '../../domain/entities/order.dart';
import 'receipt_printer.dart';

/// No-hardware printer. It builds **real ESC/POS bytes** (so swapping in a
/// physical transport is trivial) but discards them, logging the byte count.
class StubReceiptPrinter implements ReceiptPrinter {
  @override
  bool get isAvailable => false;

  @override
  Future<void> printOrder(Order order, {required String storeName}) async {
    final bytes = await buildReceiptBytes(order, storeName: storeName);
    // A real implementation would write these to a socket / Bluetooth char.
    debugPrint('[StubReceiptPrinter] ${bytes.length} ESC/POS bytes generated '
        'for order #${order.orderNumber} (not sent — no hardware).');
  }

  /// Generates 80mm ESC/POS bytes for [order]. Reusable by any transport.
  static Future<List<int>> buildReceiptBytes(
    Order order, {
    required String storeName,
  }) async {
    final profile = await CapabilityProfile.load();
    final g = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    bytes.addAll(g.text(storeName,
        styles: const PosStyles(
            align: PosAlign.center, height: PosTextSize.size2, bold: true)));
    bytes.addAll(g.text('Official Receipt',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.hr());
    bytes.addAll(g.text('Order #${order.orderNumber}   Queue ${order.queueNumber}'));
    bytes.addAll(g.text('Type: ${order.type.label}'));
    bytes.addAll(g.text(order.createdAt.toString().split('.').first));
    bytes.addAll(g.hr());

    for (final it in order.items) {
      bytes.addAll(g.row([
        PosColumn(text: '${it.quantity}x ${it.name}', width: 8),
        PosColumn(
            text: Money.format(it.lineTotalCentavos),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]));
      for (final m in it.modifiers) {
        bytes.addAll(g.text('   + ${m.name}',
            styles: const PosStyles(fontType: PosFontType.fontB)));
      }
    }

    bytes.addAll(g.hr());
    bytes.addAll(_kv(g, 'Subtotal', order.subtotalCentavos));
    if (order.discountCentavos > 0) {
      bytes.addAll(_kv(g, order.discountType.label, -order.discountCentavos));
    }
    bytes.addAll(_kv(g, 'VAT', order.vatCentavos));
    bytes.addAll(_kv(g, 'TOTAL', order.totalCentavos, bold: true));
    bytes.addAll(g.hr());

    for (final p in order.payments) {
      bytes.addAll(_kv(g, p.method.label, p.amountCentavos));
      if (p.changeCentavos > 0) {
        bytes.addAll(_kv(g, 'Change', p.changeCentavos));
      }
    }

    bytes.addAll(g.feed(1));
    bytes.addAll(g.text('This serves as your official receipt.',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.text('Thank you, come again!',
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(g.feed(2));
    bytes.addAll(g.cut());
    return bytes;
  }

  static List<int> _kv(Generator g, String label, int centavos,
          {bool bold = false}) =>
      g.row([
        PosColumn(text: label, width: 6, styles: PosStyles(bold: bold)),
        PosColumn(
            text: Money.format(centavos),
            width: 6,
            styles: PosStyles(align: PosAlign.right, bold: bold)),
      ]);
}
