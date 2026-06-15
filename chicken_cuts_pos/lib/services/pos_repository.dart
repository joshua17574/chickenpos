import '../models/product.dart';
import '../models/sale.dart';

class PosSnapshot {
  final List<Product> products;
  final List<Sale> sales;
  final bool recovered;

  const PosSnapshot({
    required this.products,
    required this.sales,
    this.recovered = false,
  });
}

class CheckoutCommit {
  final Sale sale;
  final PosSnapshot? snapshot;

  const CheckoutCommit({
    required this.sale,
    this.snapshot,
  });
}

class PosRepositoryException implements Exception {
  final String message;
  const PosRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Storage boundary for POS data.
///
/// A cloud/database implementation should keep [commitCheckout] atomic:
/// stock changes and sale insertion must succeed or fail together.
abstract class PosRepository {
  Future<PosSnapshot> load();

  Future<Product> createProduct(Product product);

  Future<Product> updateProduct(Product product);

  Future<void> deleteProduct(String id);

  Future<void> clearSales();

  Future<CheckoutCommit> commitCheckout({
    required List<Product> products,
    required List<Sale> sales,
    required Sale sale,
  });
}
