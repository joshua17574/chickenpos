import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/entities/order.dart';
import '../../providers/printer_providers.dart';
import '../../providers/settings_providers.dart';
import 'widgets/receipt_view.dart';

/// Shows the finalized order receipt with print + new-order actions.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({required this.order, super.key});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeName = ref.watch(settingsProvider).storeName;

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt · Order #${order.orderNumber}'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ReceiptView(order: order, storeName: storeName),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _print(context, ref, storeName),
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go(Routes.menu),
                  icon: const Icon(Icons.add),
                  label: const Text('New Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _print(
      BuildContext context, WidgetRef ref, String storeName) async {
    final printer = ref.read(receiptPrinterProvider);
    try {
      await printer.printOrder(order, storeName: storeName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(printer.isAvailable
                ? 'Receipt sent to printer'
                : 'No printer connected — receipt rendered (ESC/POS stub)'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Print failed: $e')));
      }
    }
  }
}
