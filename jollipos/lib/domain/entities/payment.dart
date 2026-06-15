import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
class Payment with _$Payment {
  const Payment._();

  const factory Payment({
    required String id,
    required PaymentMethod method,
    required int amountCentavos,
    /// Cash tendered (cash only); 0 otherwise.
    @Default(0) int tenderedCentavos,
    /// Reference number for card / e-wallet (mock).
    @Default('') String reference,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  int get changeCentavos => method == PaymentMethod.cash
      ? (tenderedCentavos - amountCentavos).clamp(0, 1 << 62)
      : 0;
}
