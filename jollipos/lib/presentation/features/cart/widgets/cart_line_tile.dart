import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../domain/entities/order_item.dart';
import '../../../providers/cart_providers.dart';

/// A single cart line: name, modifier summary, note, qty stepper, line total.
class CartLineTile extends ConsumerWidget {
  const CartLineTile({required this.item, super.key});
  final OrderItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cartControllerProvider.notifier);
    final theme = Theme.of(context);
    final mods = item.modifiers.map((m) => m.name).join(', ');

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => controller.remove(item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (mods.isNotEmpty)
                    Text(mods, style: theme.textTheme.bodySmall),
                  if (item.note.isNotEmpty)
                    Text('Note: ${item.note}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                  Text(Money.format(item.lineTotalCentavos),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
            _QtyStepper(
              qty: item.quantity,
              onMinus: () => controller.decrement(item.id),
              onPlus: () => controller.increment(item.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: 18),
          ),
          SizedBox(
            width: 28,
            child: Text('$qty', textAlign: TextAlign.center),
          ),
          IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            onPressed: onPlus,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      );
}
