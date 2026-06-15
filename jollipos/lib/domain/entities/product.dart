import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const Product._();

  const factory Product({
    required String id,
    required String categoryId,
    required String name,
    required int basePriceCentavos,
    @Default('') String description,
    @Default('') String imageAsset,
    @Default(true) bool available,
    @Default(false) bool isCombo,
    @Default(0) int sortOrder,
    /// IDs of [ModifierGroup]s applicable to this product.
    @Default(<String>[]) List<String> modifierGroupIds,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  bool get hasModifiers => modifierGroupIds.isNotEmpty;
}
