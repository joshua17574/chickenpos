import '../entities/category.dart';
import '../entities/modifier.dart';
import '../entities/product.dart';

/// Catalog data boundary. Backed by Drift locally; can be swapped for a remote
/// source without touching the UI. Every read is a live [Stream] so Menu
/// Management edits reflect on the ordering screen instantly.
abstract interface class CatalogRepository {
  Stream<List<Category>> watchCategories();
  Future<List<Category>> getCategories();

  Stream<List<Product>> watchProducts();
  Future<List<Product>> getProducts();

  Stream<List<ModifierGroup>> watchModifierGroups();
  Future<List<ModifierGroup>> getModifierGroups();

  // -------- Writes (Menu Management) --------
  Future<void> upsertCategory(Category category);
  Future<void> deleteCategory(String categoryId);

  Future<void> upsertProduct(Product product);
  Future<void> setAvailability(String productId, bool available);
  Future<void> deleteProduct(String productId);

  Future<void> upsertModifierGroup(ModifierGroup group);
  Future<void> deleteModifierGroup(String groupId);

  /// Wipes the entire user catalog (products, modifiers, categories).
  Future<void> clearCatalog();
}
