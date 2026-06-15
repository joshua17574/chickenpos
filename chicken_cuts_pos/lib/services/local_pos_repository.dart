import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/sale.dart';
import 'pos_repository.dart';

class LocalPosRepository implements PosRepository {
  LocalPosRepository({SharedPreferences? prefs}) : _prefs = prefs;

  static const _kProducts = 'pos_products_v1';
  static const _kSales = 'pos_sales_v1';

  SharedPreferences? _prefs;

  static List<Product> seedProducts() => [
        Product(
          id: 'p1',
          name: 'MAGIC SARAP',
          category: 'GROCERY',
          sell: 5,
          buy: 3,
          stock: 7,
        ),
        Product(
          id: 'p2',
          name: 'C10',
          category: 'WC',
          sell: 377,
          buy: 0,
          stock: 650,
        ),
        Product(
          id: 'p3',
          name: 'OS1',
          category: 'WC',
          sell: 158,
          buy: 153,
          stock: 1,
        ),
        Product(
            id: 'p4', name: 'OS2', category: 'WC', sell: 158, buy: 0, stock: 0),
        Product(
          id: 'p5',
          name: 'OS4',
          category: 'WC',
          sell: 158,
          buy: 153,
          stock: 150,
        ),
        Product(
            id: 'p6', name: 'PS1', category: 'WC', sell: 0, buy: 0, stock: 75),
        Product(
            id: 'p7', name: 'C59', category: 'WC', sell: 0, buy: 0, stock: 0),
        Product(
            id: 'p8', name: 'C99', category: 'WC', sell: 0, buy: 0, stock: 0),
        Product(
          id: 'p9',
          name: 'WHOLE CHICKEN',
          category: 'WC',
          sell: 0,
          buy: 0,
          stock: 0,
        ),
        Product(
          id: 'p10',
          name: 'LECHON',
          category: 'WC',
          sell: 0,
          buy: 0,
          stock: 0,
        ),
      ];

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<PosSnapshot> load() async {
    final prefs = await _getPrefs();
    final productsResult = _restoreProducts(prefs.getString(_kProducts));
    final salesResult = _restoreSales(prefs.getString(_kSales));
    final snapshot = PosSnapshot(
      products: productsResult.value,
      sales: salesResult.value,
      recovered: productsResult.recovered || salesResult.recovered,
    );

    if (snapshot.recovered) {
      await _saveProducts(snapshot.products);
      await _saveSales(snapshot.sales);
    }
    return snapshot;
  }

  _RestoreResult<Product> _restoreProducts(String? raw) {
    if (raw == null) return _RestoreResult(seedProducts(), recovered: false);

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Expected a list');
      return _RestoreResult(
        decoded.map((e) {
          if (e is! Map<String, dynamic>) {
            throw const FormatException('Expected a product map');
          }
          return Product.fromJson(e);
        }).toList(),
        recovered: false,
      );
    } catch (_) {
      return _RestoreResult(seedProducts(), recovered: true);
    }
  }

  _RestoreResult<Sale> _restoreSales(String? raw) {
    if (raw == null) return const _RestoreResult([], recovered: false);

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Expected a list');
      return _RestoreResult(
        decoded.map((e) {
          if (e is! Map<String, dynamic>) {
            throw const FormatException('Expected a sale map');
          }
          return Sale.fromJson(e);
        }).toList(),
        recovered: false,
      );
    } catch (_) {
      return const _RestoreResult([], recovered: true);
    }
  }

  Future<void> _saveProducts(List<Product> products) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _kProducts,
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveSales(List<Sale> sales) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _kSales,
      jsonEncode(sales.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<Product> createProduct(Product product) async {
    final snapshot = await load();
    await _saveProducts([...snapshot.products, product]);
    return product;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final snapshot = await load();
    final updated = snapshot.products
        .map((item) => item.id == product.id ? product : item)
        .toList();
    await _saveProducts(updated);
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    final snapshot = await load();
    await _saveProducts(snapshot.products.where((p) => p.id != id).toList());
  }

  @override
  Future<void> clearSales() async {
    await _saveSales(const []);
  }

  @override
  Future<CheckoutCommit> commitCheckout({
    required List<Product> products,
    required List<Sale> sales,
    required Sale sale,
  }) async {
    await _saveProducts(products);
    await _saveSales(sales);
    return CheckoutCommit(sale: sale);
  }
}

class _RestoreResult<T> {
  final List<T> value;
  final bool recovered;

  const _RestoreResult(this.value, {required this.recovered});
}
