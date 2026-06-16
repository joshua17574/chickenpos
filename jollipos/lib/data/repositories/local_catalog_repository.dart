import '../../domain/entities/category.dart';
import '../../domain/entities/modifier.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../local/daos/product_dao.dart';

/// Drift-backed catalog repository.
class LocalCatalogRepository implements CatalogRepository {
  LocalCatalogRepository(this._dao);

  final ProductDao _dao;

  @override
  Stream<List<Category>> watchCategories() => _dao.watchCategories();

  @override
  Future<List<Category>> getCategories() => _dao.getCategories();

  @override
  Stream<List<Product>> watchProducts() => _dao.watchProducts();

  @override
  Future<List<Product>> getProducts() => _dao.getProducts();

  @override
  Stream<List<ModifierGroup>> watchModifierGroups() =>
      _dao.watchModifierGroups();

  @override
  Future<List<ModifierGroup>> getModifierGroups() => _dao.getModifierGroups();

  @override
  Future<void> upsertCategory(Category category) =>
      _dao.upsertCategory(category);

  @override
  Future<void> deleteCategory(String categoryId) =>
      _dao.deleteCategory(categoryId);

  @override
  Future<void> upsertProduct(Product product) => _dao.upsertProduct(product);

  @override
  Future<void> setAvailability(String productId, bool available) =>
      _dao.setAvailability(productId, available);

  @override
  Future<void> deleteProduct(String productId) =>
      _dao.deleteProduct(productId);

  @override
  Future<void> upsertModifierGroup(ModifierGroup group) =>
      _dao.upsertModifierGroup(group);

  @override
  Future<void> deleteModifierGroup(String groupId) =>
      _dao.deleteModifierGroup(groupId);

  @override
  Future<void> clearCatalog() => _dao.clearCatalog();
}
