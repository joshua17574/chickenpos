import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/payment.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'order_dao.g.dart';

/// Order persistence: transactional create, KDS streaming, reports.
@DriftAccessor(tables: [Orders, OrderItems, Payments])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(super.db);

  /// Persists header + items + payments atomically so a crash mid-write never
  /// leaves a partial order.
  Future<void> saveOrder(Order order) async {
    await transaction(() async {
      await into(orders).insertOnConflictUpdate(_orderCompanion(order));
      await (delete(orderItems)..where((i) => i.orderId.equals(order.id))).go();
      await (delete(payments)..where((p) => p.orderId.equals(order.id))).go();
      for (final it in order.items) {
        await into(orderItems).insert(_itemCompanion(order.id, it));
      }
      for (final pay in order.payments) {
        await into(payments).insert(_paymentCompanion(order.id, pay));
      }
    });
  }

  Future<void> updateStatus(String orderId, OrderStatus status) =>
      (update(orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(
          status: Value(status.index),
          completedAt: status == OrderStatus.completed
              ? Value(DateTime.now())
              : const Value.absent(),
        ),
      );

  Future<void> markSynced(String orderId) =>
      (update(orders)..where((o) => o.id.equals(orderId)))
          .write(const OrdersCompanion(synced: Value(true)));

  /// Live KDS feed: everything not yet completed/voided, oldest first.
  Stream<List<Order>> watchActiveOrders() {
    final query = select(orders)
      ..where((o) => o.status.isIn([
            OrderStatus.pending.index,
            OrderStatus.preparing.index,
            OrderStatus.ready.index,
          ]))
      ..orderBy([(o) => OrderingTerm(expression: o.createdAt)]);
    return query.watch().asyncMap(_hydrateAll);
  }

  Future<List<Order>> getOrdersBetween(DateTime start, DateTime end) async {
    final rows = await (select(orders)
          ..where((o) => o.createdAt.isBetweenValues(start, end))
          ..orderBy([(o) => OrderingTerm(expression: o.createdAt)]))
        .get();
    return _hydrateAll(rows);
  }

  Future<List<Order>> getUnsynced() async {
    final rows =
        await (select(orders)..where((o) => o.synced.equals(false))).get();
    return _hydrateAll(rows);
  }

  Future<int> nextOrderNumber() async {
    final row = await (selectOnly(orders)
          ..addColumns([orders.orderNumber.max()]))
        .getSingleOrNull();
    return (row?.read(orders.orderNumber.max()) ?? 0) + 1;
  }

  /// Queue numbers cycle 1–999 per day for the kitchen display.
  Future<int> nextQueueNumber(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final row = await (selectOnly(orders)
          ..addColumns([orders.queueNumber.max()])
          ..where(orders.createdAt.isBetweenValues(start, end)))
        .getSingleOrNull();
    final last = row?.read(orders.queueNumber.max()) ?? 0;
    return last >= 999 ? 1 : last + 1;
  }

  // ---------------- Hydration ----------------
  Future<List<Order>> _hydrateAll(List<OrderRow> rows) async {
    return Future.wait(rows.map(_hydrate));
  }

  Future<Order> _hydrate(OrderRow r) async {
    final itemRows =
        await (select(orderItems)..where((i) => i.orderId.equals(r.id))).get();
    final payRows =
        await (select(payments)..where((p) => p.orderId.equals(r.id))).get();
    return Order(
      id: r.id,
      orderNumber: r.orderNumber,
      queueNumber: r.queueNumber,
      type: OrderType.values[r.type],
      status: OrderStatus.values[r.status],
      discountType: DiscountType.values[r.discountType],
      vatRate: r.vatRate,
      promoDiscountCentavos: r.promoDiscountCentavos,
      promoCode: r.promoCode,
      cashierId: r.cashierId,
      synced: r.synced,
      createdAt: r.createdAt,
      completedAt: r.completedAt,
      items: itemRows.map(_toItem).toList(),
      payments: payRows.map(_toPayment).toList(),
    );
  }

  OrderItem _toItem(OrderItemRow r) => OrderItem(
        id: r.id,
        productId: r.productId,
        name: r.name,
        basePriceCentavos: r.basePriceCentavos,
        quantity: r.quantity,
        note: r.note,
        modifiers: (jsonDecode(r.modifiersJson) as List)
            .map((e) =>
                SelectedModifier.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Payment _toPayment(PaymentRow r) => Payment(
        id: r.id,
        method: PaymentMethod.values[r.method],
        amountCentavos: r.amountCentavos,
        tenderedCentavos: r.tenderedCentavos,
        reference: r.reference,
      );

  // ---------------- Companions ----------------
  OrdersCompanion _orderCompanion(Order o) => OrdersCompanion.insert(
        id: o.id,
        orderNumber: o.orderNumber,
        queueNumber: o.queueNumber,
        type: o.type.index,
        status: o.status.index,
        discountType: Value(o.discountType.index),
        vatRate: Value(o.vatRate),
        promoDiscountCentavos: Value(o.promoDiscountCentavos),
        promoCode: Value(o.promoCode),
        cashierId: Value(o.cashierId),
        synced: Value(o.synced),
        createdAt: o.createdAt,
        completedAt: Value(o.completedAt),
      );

  OrderItemsCompanion _itemCompanion(String orderId, OrderItem it) =>
      OrderItemsCompanion.insert(
        id: it.id,
        orderId: orderId,
        productId: it.productId,
        name: it.name,
        basePriceCentavos: it.basePriceCentavos,
        quantity: Value(it.quantity),
        note: Value(it.note),
        modifiersJson:
            Value(jsonEncode(it.modifiers.map((m) => m.toJson()).toList())),
      );

  PaymentsCompanion _paymentCompanion(String orderId, Payment p) =>
      PaymentsCompanion.insert(
        id: p.id,
        orderId: orderId,
        method: p.method.index,
        amountCentavos: p.amountCentavos,
        tenderedCentavos: Value(p.tenderedCentavos),
        reference: Value(p.reference),
      );
}
