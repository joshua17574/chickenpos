import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'modifier.freezed.dart';
part 'modifier.g.dart';

/// A single selectable add-on, e.g. "Large (+₱20)" or "Extra Rice".
@freezed
class Modifier with _$Modifier {
  const factory Modifier({
    required String id,
    required String name,
    @Default(0) int priceDeltaCentavos,
  }) = _Modifier;

  factory Modifier.fromJson(Map<String, dynamic> json) =>
      _$ModifierFromJson(json);
}

/// A group of related modifiers attached to a product, e.g. "Size", "Drink",
/// "Spice level". [required] groups force at least [min] selections.
@freezed
class ModifierGroup with _$ModifierGroup {
  const factory ModifierGroup({
    required String id,
    required String name,
    required ModifierSelection selection,
    @Default(false) bool required,
    @Default(1) int min,
    @Default(1) int max,
    @Default(<Modifier>[]) List<Modifier> options,
  }) = _ModifierGroup;

  factory ModifierGroup.fromJson(Map<String, dynamic> json) =>
      _$ModifierGroupFromJson(json);
}
