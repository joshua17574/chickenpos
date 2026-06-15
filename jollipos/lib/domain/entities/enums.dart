/// Domain enums shared across orders, payments, and users.
library;

enum OrderType {
  dineIn,
  takeOut,
  delivery;

  String get label => switch (this) {
        OrderType.dineIn => 'Dine-in',
        OrderType.takeOut => 'Take-out',
        OrderType.delivery => 'Delivery',
      };
}

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  voided;

  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.completed => 'Completed',
        OrderStatus.voided => 'Voided',
      };

  /// Valid forward transition in the KDS flow (null when terminal).
  OrderStatus? get next => switch (this) {
        OrderStatus.pending => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.completed,
        OrderStatus.completed => null,
        OrderStatus.voided => null,
      };
}

enum PaymentMethod {
  cash,
  card,
  eWallet;

  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Card',
        PaymentMethod.eWallet => 'E-Wallet',
      };
}

enum DiscountType {
  none,
  seniorPwd,
  promo;

  String get label => switch (this) {
        DiscountType.none => 'No discount',
        DiscountType.seniorPwd => 'Senior/PWD',
        DiscountType.promo => 'Promo code',
      };
}

enum UserRole { admin, cashier }

/// How many options a modifier group allows.
enum ModifierSelection { single, multiple }
