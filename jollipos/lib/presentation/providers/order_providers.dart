import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/order.dart';

/// Live feed of not-yet-completed orders for the Kitchen Display.
final activeOrdersProvider = StreamProvider<List<Order>>(
  (ref) => ref.watch(orderRepositoryProvider).watchActiveOrders(),
);
