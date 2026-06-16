import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/modifier.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';

const _uuid = Uuid();

/// Generates a stable unique id for newly-encoded catalog entities.
String newId(String prefix) => '${prefix}_${_uuid.v4()}';

// ---------------------------------------------------------------------------
// Live reads — every catalog edit in Menu Management flows through these
// streams to the ordering screen with NO app rebuild.
// ---------------------------------------------------------------------------

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchCategories(),
);

final productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchProducts(),
);

final modifierGroupsProvider = StreamProvider<List<ModifierGroup>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchModifierGroups(),
);

/// Convenience: a map of modifier-group-id -> group, for fast lookups when
/// rendering a product's attached groups.
final modifierGroupMapProvider = Provider<Map<String, ModifierGroup>>((ref) {
  final groups = ref.watch(modifierGroupsProvider).valueOrNull ?? const [];
  return {for (final g in groups) g.id: g};
});

/// Currently selected category id on the Menu screen (null = All).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Free-text product search query.
final menuSearchProvider = StateProvider<String>((ref) => '');

/// True when the user has not encoded any products yet.
final catalogIsEmptyProvider = Provider<bool>((ref) {
  final products = ref.watch(productsProvider).valueOrNull;
  return products != null && products.isEmpty;
});

/// Products filtered by selected category + search query. Sold-out / inactive
/// products are hidden from the ordering grid (still visible in Admin).
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider).valueOrNull ?? const [];
  final catId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(menuSearchProvider).trim().toLowerCase();
  return products.where((p) {
    if (!p.available) return false;
    final matchesCat = catId == null || p.categoryId == catId;
    final matchesQuery = query.isEmpty || p.name.toLowerCase().contains(query);
    return matchesCat && matchesQuery;
  }).toList();
});

// ---------------------------------------------------------------------------
// Writes — thin controller used by Menu Management. Keeps repository calls in
// one place and frees the UI from generating ids / wiring the repo directly.
// ---------------------------------------------------------------------------

class CatalogEditor {
  CatalogEditor(this._ref);
  final Ref _ref;

  CatalogRepository get _repo => _ref.read(catalogRepositoryProvider);

  Future<void> saveCategory(Category c) => _repo.upsertCategory(c);
  Future<void> deleteCategory(String id) => _repo.deleteCategory(id);

  Future<void> saveProduct(Product p) => _repo.upsertProduct(p);
  Future<void> deleteProduct(String id) => _repo.deleteProduct(id);
  Future<void> setAvailability(String id, bool available) =>
      _repo.setAvailability(id, available);

  /// Duplicates a product under a fresh id with a "(copy)" suffix.
  Future<void> duplicateProduct(Product p) => _repo.upsertProduct(
        p.copyWith(id: newId('p'), name: '${p.name} (copy)'),
      );

  Future<void> saveModifierGroup(ModifierGroup g) =>
      _repo.upsertModifierGroup(g);
  Future<void> deleteModifierGroup(String id) => _repo.deleteModifierGroup(id);

  Future<void> clearCatalog() => _repo.clearCatalog();
}

final catalogEditorProvider =
    Provider<CatalogEditor>((ref) => CatalogEditor(ref));
