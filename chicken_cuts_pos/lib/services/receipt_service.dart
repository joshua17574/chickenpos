import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sale.dart';
import '../theme.dart';
import 'format.dart';

/// Builds and displays sales receipts.
///
/// This keeps printing platform-safe for Android, desktop, and web. It creates
/// a clean thermal-printer-width receipt, previews it, and copies the text so
/// the cashier can paste/send it to any Bluetooth/USB/network printer app.
class ReceiptService {
  static const storeName = 'Chicken Cuts POS';
  static const storeSubtitle = 'Sales Receipt';
  static const lineWidth = 32;

  static String buildReceiptText(Sale sale) {
    final buffer = StringBuffer();

    buffer.writeln(_center(storeName));
    buffer.writeln(_center(storeSubtitle));
    buffer.writeln(_line());
    buffer.writeln('Receipt: ${_shortId(sale.id)}');
    buffer.writeln('Date: ${formatDate(sale.ts)}');
    buffer.writeln(_line());
    buffer.writeln(_columns('ITEM', 'AMOUNT'));

    for (final item in sale.items) {
      buffer.writeln(_truncate(item.name));
      buffer.writeln(
        _columns('  ${item.qty} x ${peso(item.price)}', peso(item.subtotal)),
      );
    }

    buffer.writeln(_line());
    buffer.writeln(_columns('TOTAL', peso(sale.total)));
    buffer.writeln(_columns('CASH', peso(sale.cash)));
    buffer.writeln(_columns('CHANGE', peso(sale.change)));
    buffer.writeln(_line());
    buffer.writeln(_center('Thank you!'));
    buffer.writeln(_center('Please come again.'));

    return buffer.toString();
  }

  static Future<void> copyReceipt(BuildContext context, Sale sale) async {
    await Clipboard.setData(ClipboardData(text: buildReceiptText(sale)));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt copied. Paste it into your printer app.'),
      ),
    );
  }

  static Future<void> showReceiptDialog(BuildContext context, Sale sale) {
    final receipt = buildReceiptText(sale);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Receipt'),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              receipt,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print / Copy'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async => copyReceipt(dialogContext, sale),
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) {
    final value = id.length <= 8 ? id : id.substring(0, 8);
    return value.toUpperCase();
  }

  static String _line() => '-' * lineWidth;

  static String _center(String value) {
    if (value.length >= lineWidth) return value;
    final leftPadding = ((lineWidth - value.length) / 2).floor();
    return '${' ' * leftPadding}$value';
  }

  static String _columns(String left, String right) {
    final availableSpace = lineWidth - left.length - right.length;
    if (availableSpace <= 1) return '$left $right';
    return '$left${' ' * availableSpace}$right';
  }

  static String _truncate(String value) {
    if (value.length <= lineWidth) return value;
    return value.substring(0, lineWidth - 1);
  }
}

Future<void> showReceiptDialog(BuildContext context, Sale sale) {
  return ReceiptService.showReceiptDialog(context, sale);
}
