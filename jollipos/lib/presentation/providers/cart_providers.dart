import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/product.dart';
import 'settings_providers.dart';

const _uuid = Uuid();

/// The in-progress order being assembled at the register.
class CartState {
  const CartState({
    this.items = const [],
    this.orderType = OrderType.dineIn,
    this.discountType = DiscountType.none,
    this.promoCode = '',
    this.promoDiscountCentavos = 0,
  });

  final List<OrderItem> items;
  final OrderType orderType;
  final DiscountType discountType;
  final String promoCode;
  final int promoDiscountCentavos;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get unitCount => items.fold(0, (s, it) => s + it.quantity);

  CartState copyWith({
    List<OrderItem>? items,
    OrderType? orderType,
    DiscountType? discountType,
    String? promoCode,
    int? promoDiscountCentavos,
  }) =>
      CartState(
        items: items ?? this.items,
        orderType: orderType ?? this.orderType,
        discountType: discountType ?? this.discountType,
        promoCode: promoCode ?? this.promoCode,
        promoDiscountCentavos:
            promoDiscountCentavos ?? this.promoDiscountCentavos,
      );
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Stable signature so identical product + modifiers + note merge into one
  /// line (quantity increments instead of duplicating).
  String _signature(String productId, List<SelectedModifier> mods, String note) {
    final ids = mods.map((m) => m.modifierId).toList()..sort();
    return '$productId|${ids.join(',')}|$note';
  }

  void addProduct(
    Product product, {
    List<SelectedModifier> modifiers = const [],
    int quantity = 1,
    String note = '',
  }) {
    final sig = _signature(product.id, modifiers, note);
    final existing = state.items.firstWhereOrNull(
      (it) => _signature(it.productId, it.modifiers, it.note) == sig,
    );
    if (existing != null) {
      _replace(existing.id, existing.copyWith(quantity: existing.quantity + quantity));
      return;
    }
    final item = OrderItem(
      id: _uuid.v4(),
      productId: product.id,
      name: product.name,
      basePriceCentavos: product.basePriceCentavos,
      quantity: quantity,
      modifiers: modifiers,
      note: note,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  void increment(String itemId) {
    final it = state.items.firstWhereOrNull((e) => e.id == itemId);
    if (it != null) _replace(itemId, it.copyWith(quantity: it.quantity + 1));
  }

  void decrement(String itemId) {
    final it = state.items.firstWhereOrNull((e) => e.id == itemId);
    if (it == null) return;
    if (it.quantity <= 1) {
      remove(itemId);
    } else {
      _replace(itemId, it.copyWith(quantity: it.quantity - 1));
    }
  }

  void setNote(String itemId, String note) {
    final it = state.items.firstWhereOrNull((e) => e.id == itemId);
    if (it != null) _replace(itemId, it.copyWith(note: note));
  }

  void remove(String itemId) =>
      state = state.copyWith(items: state.items.where((e) => e.id != itemId).toList());

  void setOrderType(OrderType type) => state = state.copyWith(orderType: type);

  void setDiscount(DiscountType type, {String promoCode = '', int promoCentavos = 0}) =>
      state = state.copyWith(
        discountType: type,
        promoCode: promoCode,
        promoDiscountCentavos: promoCentavos,
      );

  void clear() => state = const CartState();

  void _replace(String id, OrderItem updated) => state = state.copyWith(
        items: [
          for (final it in state.items) it.id == id ? updated : it,
        ],
      );
}

final cartControllerProvider =
    NotifierProvider<CartController, CartState>(CartController.new);

/// Read-only draft [Order] derived from the cart + current VAT setting, so all
/// pricing (subtotal, discount, VAT, total) reuses the entity's math.
final draftOrderProvider = Provider<Order>((ref) {
  final cart = ref.watch(cartControllerProvider);
  final vatRate = ref.watch(settingsProvider).vatRate;
  return Order(
    id: 'draft',
    orderNumber: 0,
    queueNumber: 0,
    type: cart.orderType,
    items: cart.items,
    discountType: cart.discountType,
    vatRate: vatRate,
    promoDiscountCentavos: cart.promoDiscountCentavos,
    promoCode: cart.promoCode,
    createdAt: DateTime.now(),
  );
});
