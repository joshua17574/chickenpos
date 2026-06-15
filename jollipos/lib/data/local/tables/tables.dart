import 'package:drift/drift.dart';

/// Drift table definitions. Money columns are integer **centavos**.
/// List/snapshot fields (modifier links, selected modifiers) are JSON text.

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get iconName => text().withDefault(const Constant('category'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get basePriceCentavos => integer()();
  TextColumn get imageAsset => text().withDefault(const Constant(''))();
  BoolColumn get available => boolean().withDefault(const Constant(true))();
  BoolColumn get isCombo => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // JSON array of modifier group ids.
  TextColumn get modifierGroupIds => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ModifierGroupRow')
class ModifierGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get selection => integer()(); // ModifierSelection index
  BoolColumn get required => boolean().withDefault(const Constant(false))();
  IntColumn get minSel => integer().withDefault(const Constant(1))();
  IntColumn get maxSel => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ModifierRow')
class Modifiers extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(ModifierGroups, #id)();
  TextColumn get name => text()();
  IntColumn get priceDeltaCentavos => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get role => integer()(); // UserRole index
  TextColumn get pinHash => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ShiftRow')
class Shifts extends Table {
  TextColumn get id => text()();
  TextColumn get cashierId => text()();
  IntColumn get openingFloatCentavos => integer()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get countedCashCentavos => integer().nullable()();
  IntColumn get expectedCashCentavos => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderRow')
class Orders extends Table {
  TextColumn get id => text()();
  IntColumn get orderNumber => integer()();
  IntColumn get queueNumber => integer()();
  IntColumn get type => integer()(); // OrderType index
  IntColumn get status => integer()(); // OrderStatus index
  IntColumn get discountType => integer().withDefault(const Constant(0))();
  RealColumn get vatRate => real().withDefault(const Constant(0.12))();
  IntColumn get promoDiscountCentavos =>
      integer().withDefault(const Constant(0))();
  TextColumn get promoCode => text().withDefault(const Constant(''))();
  TextColumn get cashierId => text().withDefault(const Constant(''))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderItemRow')
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get productId => text()();
  TextColumn get name => text()();
  IntColumn get basePriceCentavos => integer()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get note => text().withDefault(const Constant(''))();
  // JSON array of SelectedModifier.
  TextColumn get modifiersJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  IntColumn get method => integer()(); // PaymentMethod index
  IntColumn get amountCentavos => integer()();
  IntColumn get tenderedCentavos => integer().withDefault(const Constant(0))();
  TextColumn get reference => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
