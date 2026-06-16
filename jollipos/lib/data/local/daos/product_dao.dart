import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/modifier.dart';
import '../../../domain/entities/product.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'product_dao.g.dart';

/// Catalog persistence: categories, products, modifier groups + modifiers.
@DriftAccessor(
  tables: [Categories, Products, ModifierGroups, Modifiers],
)
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  // ---------------- Categories ----------------
  Stream<List<Category>> watchCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
          .map(_toCategory)
          .watch();

  Future<List<Category>> getCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
          .map(_toCategory)
          .get();

  Future<void> upsertCategory(Category c) =>
      into(categories).insertOnConflictUpdate(CategoriesCompanion.insert(
        id: c.id,
        name: c.name,
        sortOrder: Value(c.sortOrder),
        iconName: Value(c.iconName),
      ));

  /// Deletes a category and all of its products atomically so the ordering
  /// screen never shows products pointing at a missing category.
  Future<void> deleteCategory(String id) => transaction(() async {
        await (delete(products)..where((p) => p.categoryId.equals(id))).go();
        await (delete(categories)..where((c) => c.id.equals(id))).go();
      });

  // ---------------- Products ----------------
  Stream<List<Product>> watchProducts() =>
      (select(products)..orderBy([(p) => OrderingTerm(expression: p.sortOrder)]))
          .map(_toProduct)
          .watch();

  Future<List<Product>> getProducts() =>
      (select(products)..orderBy([(p) => OrderingTerm(expression: p.sortOrder)]))
          .map(_toProduct)
          .get();

  Future<void> upsertProduct(Product prod) =>
      into(products).insertOnConflictUpdate(ProductsCompanion.insert(
        id: prod.id,
        categoryId: prod.categoryId,
        name: prod.name,
        basePriceCentavos: prod.basePriceCentavos,
        description: Value(prod.description),
        imageAsset: Value(prod.imageAsset),
        available: Value(prod.available),
        isCombo: Value(prod.isCombo),
        sortOrder: Value(prod.sortOrder),
        modifierGroupIds: Value(jsonEncode(prod.modifierGroupIds)),
      ));

  Future<void> setAvailability(String id, bool available) =>
      (update(products)..where((p) => p.id.equals(id)))
          .write(ProductsCompanion(available: Value(available)));

  Future<void> deleteProduct(String id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  // ---------------- Modifiers ----------------
  Future<List<ModifierGroup>> getModifierGroups() async {
    final groups = await select(modifierGroups).get();
    final mods = await select(modifiers).get();
    return groups.map((g) {
      final opts = (mods.where((m) => m.groupId == g.id).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
          .map((m) => Modifier(
                id: m.id,
                name: m.name,
                priceDeltaCentavos: m.priceDeltaCentavos,
              ))
          .toList();
      return ModifierGroup(
        id: g.id,
        name: g.name,
        selection: ModifierSelection.values[g.selection],
        required: g.required,
        min: g.minSel,
        max: g.maxSel,
        options: opts,
      );
    }).toList();
  }

  Future<void> upsertModifierGroup(ModifierGroup g) async {
    await into(modifierGroups).insertOnConflictUpdate(
      ModifierGroupsCompanion.insert(
        id: g.id,
        name: g.name,
        selection: g.selection.index,
        required: Value(g.required),
        minSel: Value(g.min),
        maxSel: Value(g.max),
      ),
    );
    for (var i = 0; i < g.options.length; i++) {
      final m = g.options[i];
      await into(modifiers).insertOnConflictUpdate(ModifiersCompanion.insert(
        id: m.id,
        groupId: g.id,
        name: m.name,
        priceDeltaCentavos: Value(m.priceDeltaCentavos),
        sortOrder: Value(i),
      ));
    }
  }

  /// Live modifier groups (with their options) for Menu Management.
  ///
  /// Re-queries whenever the [modifierGroups] table changes. Every edit path
  /// ([upsertModifierGroup], [deleteModifierGroup]) writes the group row, so a
  /// single watch on that table is sufficient to keep the UI in sync.
  Stream<List<ModifierGroup>> watchModifierGroups() async* {
    await for (final _ in select(modifierGroups).watch()) {
      yield await getModifierGroups();
    }
  }

  /// Deletes a modifier group and its options atomically.
  Future<void> deleteModifierGroup(String id) => transaction(() async {
        await (delete(modifiers)..where((m) => m.groupId.equals(id))).go();
        await (delete(modifierGroups)..where((g) => g.id.equals(id))).go();
      });

  /// Wipes the entire user-encoded catalog (products, modifiers, modifier
  /// groups, categories) in one atomic transaction. Orders + users untouched.
  Future<void> clearCatalog() => transaction(() async {
        await delete(products).go();
        await delete(modifiers).go();
        await delete(modifierGroups).go();
        await delete(categories).go();
      });

  // ---------------- Mappers ----------------
  Category _toCategory(CategoryRow r) => Category(
        id: r.id,
        name: r.name,
        sortOrder: r.sortOrder,
        iconName: r.iconName,
      );

  Product _toProduct(ProductRow r) => Product(
        id: r.id,
        categoryId: r.categoryId,
        name: r.name,
        basePriceCentavos: r.basePriceCentavos,
        description: r.description,
        imageAsset: r.imageAsset,
        available: r.available,
        isCombo: r.isCombo,
        sortOrder: r.sortOrder,
        modifierGroupIds: (jsonDecode(r.modifierGroupIds) as List)
            .map((e) => e as String)
            .toList(),
      );
}
