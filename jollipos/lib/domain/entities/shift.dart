import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift.freezed.dart';
part 'shift.g.dart';

/// A cashier shift with cash-drawer reconciliation.
@freezed
class Shift with _$Shift {
  const Shift._();

  const factory Shift({
    required String id,
    required String cashierId,
    required int openingFloatCentavos,
    required DateTime openedAt,
    DateTime? closedAt,
    /// Counted cash at close.
    int? countedCashCentavos,
    /// Expected cash = float + cash sales (computed at close).
    int? expectedCashCentavos,
  }) = _Shift;

  factory Shift.fromJson(Map<String, dynamic> json) => _$ShiftFromJson(json);

  bool get isOpen => closedAt == null;

  /// Over/short variance (positive = over, negative = short).
  int? get varianceCentavos => (countedCashCentavos != null &&
          expectedCashCentavos != null)
      ? countedCashCentavos! - expectedCashCentavos!
      : null;
}
