import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/enums.dart';
import '../../../providers/cart_providers.dart';

/// Segmented Dine-in / Take-out / Delivery selector.
class OrderTypeSelector extends ConsumerWidget {
  const OrderTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(cartControllerProvider).orderType;
    return SegmentedButton<OrderType>(
      segments: [
        for (final t in OrderType.values)
          ButtonSegment(value: t, label: Text(t.label)),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (s) =>
          ref.read(cartControllerProvider.notifier).setOrderType(s.first),
    );
  }
}
