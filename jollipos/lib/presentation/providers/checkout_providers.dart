import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/payment.dart';
import '../../core/di/providers.dart';
import 'auth_providers.dart';
import 'cart_providers.dart';

const _uuid = Uuid();

/// Holds the payments tendered for the order being checked out (supports split
/// payment across multiple methods).
class CheckoutController extends Notifier<List<Payment>> {
  @override
  List<Payment> build() => const [];

  void addPayment(Payment payment) => state = [...state, payment];

  void removePayment(String id) =>
      state = state.where((p) => p.id != id).toList();

  void reset() => state = const [];

  int get paidCentavos => state.fold(0, (s, p) => s + p.amountCentavos);

  /// Convenience builders.
  Payment cash({required int amountCentavos, required int tenderedCentavos}) =>
      Payment(
        id: _uuid.v4(),
        method: PaymentMethod.cash,
        amountCentavos: amountCentavos,
        tenderedCentavos: tenderedCentavos,
      );

  Payment card({required int amountCentavos, String reference = ''}) => Payment(
        id: _uuid.v4(),
        method: PaymentMethod.card,
        amountCentavos: amountCentavos,
        reference: reference,
      );

  Payment eWallet({required int amountCentavos, String reference = ''}) =>
      Payment(
        id: _uuid.v4(),
        method: PaymentMethod.eWallet,
        amountCentavos: amountCentavos,
        reference: reference.isEmpty
            ? 'EW${DateTime.now().millisecondsSinceEpoch % 1000000}'
            : reference,
      );

  /// Persists the order (header + items + payments) atomically, assigns the
  /// store order number + daily queue number, clears the cart, and returns the
  /// saved order for the receipt screen.
  Future<Order> finalizeOrder() async {
    final draft = ref.read(draftOrderProvider);
    final repo = ref.read(orderRepositoryProvider);
    final cashier = ref.read(authControllerProvider);
    final now = DateTime.now();

    final order = draft.copyWith(
      id: _uuid.v4(),
      orderNumber: await repo.nextOrderNumber(),
      queueNumber: await repo.nextQueueNumber(now),
      status: OrderStatus.pending,
      payments: List<Payment>.from(state),
      cashierId: cashier?.id ?? '',
      createdAt: now,
    );

    await repo.saveOrder(order);
    ref.read(cartControllerProvider.notifier).clear();
    reset();
    return order;
  }
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, List<Payment>>(CheckoutController.new);
