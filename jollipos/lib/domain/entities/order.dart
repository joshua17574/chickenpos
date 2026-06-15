import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'order_item.dart';
import 'payment.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class Order with _$Order {
  const Order._();

  const factory Order({
    required String id,
    required int orderNumber,
    required int queueNumber,
    required OrderType type,
    @Default(OrderStatus.pending) OrderStatus status,
    @Default(<OrderItem>[]) List<OrderItem> items,
    @Default(<Payment>[]) List<Payment> payments,
    @Default(DiscountType.none) DiscountType discountType,
    /// VAT rate applied to this order (snapshot of config at sale time).
    @Default(0.12) double vatRate,
    /// Manual promo discount in centavos (used when [discountType] is promo).
    @Default(0) int promoDiscountCentavos,
    @Default('') String promoCode,
    @Default('') String cashierId,
    @Default(false) bool synced,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// Sum of all line totals before discount/VAT.
  int get subtotalCentavos =>
      items.fold(0, (sum, it) => sum + it.lineTotalCentavos);

  /// Discount amount in centavos based on [discountType].
  /// Senior/PWD is VAT-exempt + 20% off the net of VAT (statutory rule).
  int get discountCentavos => switch (discountType) {
        DiscountType.none => 0,
        DiscountType.promo => promoDiscountCentavos.clamp(0, subtotalCentavos),
        DiscountType.seniorPwd => _seniorPwdDiscount(),
      };

  int _seniorPwdDiscount() {
    // Net of VAT, then 20% off.
    final net = (subtotalCentavos / (1 + vatRate)).round();
    return (net * 0.20).round();
  }

  /// VAT amount. Senior/PWD orders are VAT-exempt.
  int get vatCentavos {
    if (discountType == DiscountType.seniorPwd) return 0;
    final taxable = subtotalCentavos - discountCentavos;
    return (taxable - (taxable / (1 + vatRate)).round()).clamp(0, 1 << 62);
  }

  /// Final amount due.
  int get totalCentavos =>
      (subtotalCentavos - discountCentavos).clamp(0, 1 << 62);

  int get paidCentavos =>
      payments.fold(0, (sum, p) => sum + p.amountCentavos);

  int get balanceCentavos => (totalCentavos - paidCentavos).clamp(0, 1 << 62);

  bool get isFullyPaid => paidCentavos >= totalCentavos;

  int get unitCount => items.fold(0, (sum, it) => sum + it.quantity);
}
