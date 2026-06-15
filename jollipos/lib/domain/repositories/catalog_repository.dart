import '../entities/category.dart';
import '../entities/modifier.dart';
import '../entities/product.dart';

/// Catalog data boundary. Backed by Drift locally; can be swapped for a remote
/// source without touching the UI.
abstract interface class CatalogRepository {
  Stream<List<Category>> watchCategories();
  Future<List<Category>> getCategories();

  Stream<List<Product>> watchProducts();
  Future<List<Product>> getProducts();

  Future<List<ModifierGroup>> getModifierGroups();

  Future<void> upsertCategory(Category category);
  Future<void> upsertProduct(Product product);
  Future<void> setAvailability(String productId, bool available);
  Future<void> deleteProduct(String productId);
}
