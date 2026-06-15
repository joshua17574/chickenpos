import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

/// A modifier captured at the moment of sale (snapshot — independent of any
/// later menu edits).
@freezed
class SelectedModifier with _$SelectedModifier {
  const factory SelectedModifier({
    required String groupId,
    required String modifierId,
    required String name,
    @Default(0) int priceDeltaCentavos,
  }) = _SelectedModifier;

  factory SelectedModifier.fromJson(Map<String, dynamic> json) =>
      _$SelectedModifierFromJson(json);
}

@freezed
class OrderItem with _$OrderItem {
  const OrderItem._();

  const factory OrderItem({
    required String id,
    required String productId,
    required String name,
    required int basePriceCentavos,
    @Default(1) int quantity,
    @Default(<SelectedModifier>[]) List<SelectedModifier> modifiers,
    @Default('') String note,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  /// Price of one unit including its selected modifiers.
  int get unitPriceCentavos =>
      basePriceCentavos +
      modifiers.fold(0, (sum, m) => sum + m.priceDeltaCentavos);

  /// Total for this line (unit price × quantity).
  int get lineTotalCentavos => unitPriceCentavos * quantity;
}
