import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/sale.dart';
import 'local_pos_repository.dart';
import 'pos_repository.dart';

class CheckoutException implements Exception {
  final String message;
  const CheckoutException(this.message);

  @override
  String toString() => message;
}

/// Central app state: product catalog, cart, sales history.
/// Persists through [PosRepository], which can be backed by local storage or a
/// remote database.
class Store extends ChangeNotifier {
  static const lowStockThreshold = 5;

  final PosRepository repository;
  final bool usesRemoteData;
  final Duration? refreshInterval;
  final List<Product> products = [];
  final List<Sale> sales = [];
  bool isSyncing = false;
  DateTime? lastSyncedAt;
  String? syncError;

  /// productId -> quantity in the current cart
  final Map<String, int> cart = {};

  Timer? _refreshTimer;

  Store({
    PosRepository? repository,
    this.usesRemoteData = false,
    this.refreshInterval,
  }) : repository = repository ?? LocalPosRepository();

  Future<void> init() async {
    try {
      await refreshFromRepository();
    } catch (_) {
      // The app should still open when a remote database is temporarily
      // unreachable; the header exposes sync status and retry.
    }
    _startAutoRefresh();
  }

  Future<void> refreshFromRepository() async {
    if (isSyncing) return;
    isSyncing = true;
    notifyListeners();

    try {
      final snapshot = await repository.load();
      _applySnapshot(snapshot);
      _markSynced();
    } catch (error) {
      _markSyncFailure(error);
      rethrow;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshSilently() async {
    try {
      await refreshFromRepository();
    } catch (_) {
      // The visible sync status is enough; background refreshes should not
      // interrupt selling.
    }
  }

  void _startAutoRefresh() {
    final interval = refreshInterval;
    if (interval == null) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      interval,
      (_) => unawaited(_refreshSilently()),
    );
  }

  void _applySnapshot(PosSnapshot snapshot) {
    products
      ..clear()
      ..addAll(snapshot.products);
    sales
      ..clear()
      ..addAll(snapshot.sales);
    _syncCartWithCatalog();
  }

  void _markSynced() {
    syncError = null;
    lastSyncedAt = DateTime.now();
  }

  void _markSyncFailure(Object error) {
    syncError = error is PosRepositoryException
        ? error.message
        : 'Could not sync with the database.';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  static String _normalizeName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String _normalizeCategory(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.isEmpty ? 'OTHER' : normalized.toUpperCase();
  }

  static double _nonNegativeAmount(double value) =>
      value.isFinite && value > 0 ? value : 0;

  static int _nonNegativeStock(int value) => value > 0 ? value : 0;

  static Product _copyProduct(Product p) => Product(
        id: p.id,
        name: p.name,
        category: p.category,
        sell: p.sell,
        buy: p.buy,
        stock: p.stock,
      );

  static void _applyProduct(Product target, Product source) {
    target.name = source.name;
    target.category = source.category;
    target.sell = source.sell;
    target.buy = source.buy;
    target.stock = source.stock;
  }

  // ---------------- Catalog helpers ----------------
  List<String> get categories {
    final set = <String>{};
    for (final p in products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    final values = set.toList()..sort();
    return ['ALL', ...values];
  }

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  int get lowStockCount =>
      products.where((p) => p.stock > 0 && p.stock <= lowStockThreshold).length;
  int get outOfStockCount => products.where((p) => p.stock <= 0).length;
  int get sellableCount => products.where((p) => p.sellable).length;
  int get needsPriceCount => products.where((p) => p.sell <= 0).length;
  int get totalStockUnits => products.fold(0, (a, p) => a + p.stock);

  int categoryCount(String category) {
    if (category == 'ALL') return products.length;
    return products.where((p) => p.category == category).length;
  }

  // ---------------- Cart ----------------
  int cartQty(String id) => cart[id] ?? 0;
  int get cartItemCount => cart.values.fold(0, (a, b) => a + b);

  double get cartTotal {
    double t = 0;
    cart.forEach((id, qty) {
      final p = productById(id);
      if (p != null) t += p.sell * qty;
    });
    return t;
  }

  /// Returns false if there is not enough stock.
  bool addToCart(String id) {
    final p = productById(id);
    if (p == null || !p.sellable) return false;
    final cur = cart[id] ?? 0;
    if (cur + 1 > p.stock) return false;
    cart[id] = cur + 1;
    notifyListeners();
    return true;
  }

  void setQty(String id, int qty) {
    final p = productById(id);
    if (p == null) return;
    if (!p.sellable || qty <= 0) {
      cart.remove(id);
      notifyListeners();
      return;
    }
    final clamped = qty.clamp(0, p.stock);
    if (clamped == 0) {
      cart.remove(id);
    } else {
      cart[id] = clamped;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  // ---------------- Checkout ----------------
  Future<Sale> checkout({required double cash}) async {
    if (cart.isEmpty) {
      throw const CheckoutException('Cart is empty.');
    }
    if (!cash.isFinite || cash < 0) {
      throw const CheckoutException('Cash received is invalid.');
    }

    final checkedItems = <MapEntry<Product, int>>[];
    final items = <SaleItem>[];
    cart.forEach((id, qty) {
      if (qty <= 0) return;
      final p = productById(id);
      if (p == null) {
        throw const CheckoutException('A cart item no longer exists.');
      }
      if (!p.sellable) {
        throw CheckoutException('${p.name} is not available for sale.');
      }
      if (qty > p.stock) {
        throw CheckoutException('Only ${p.stock} ${p.name} left in stock.');
      }
      checkedItems.add(MapEntry(p, qty));
      items.add(
        SaleItem(
          productId: id,
          name: p.name,
          price: p.sell,
          cost: p.buy,
          qty: qty,
        ),
      );
    });

    if (items.isEmpty) {
      throw const CheckoutException('Cart is empty.');
    }
    final total = items.fold(0.0, (a, i) => a + i.subtotal);
    final paid = cash > 0 ? cash : total;
    if (paid < total) {
      throw const CheckoutException('Cash is less than total.');
    }

    final productsAfterCheckout = products.map(_copyProduct).toList();
    for (final entry in checkedItems) {
      final product = productsAfterCheckout.firstWhere(
        (p) => p.id == entry.key.id,
      );
      product.stock -= entry.value;
    }

    final now = DateTime.now();
    final sale = Sale(
      id: 'S${now.millisecondsSinceEpoch}',
      ts: now,
      items: items,
      total: total,
      cash: paid,
      change: paid - total,
    );
    final salesAfterCheckout = [sale, ...sales];
    final CheckoutCommit commit;
    try {
      commit = await repository.commitCheckout(
        products: productsAfterCheckout,
        sales: salesAfterCheckout,
        sale: sale,
      );
    } on PosRepositoryException catch (e) {
      throw CheckoutException(e.message);
    } catch (_) {
      throw const CheckoutException(
        'Could not complete sale. Check the connection and try again.',
      );
    }

    if (commit.snapshot != null) {
      products
        ..clear()
        ..addAll(commit.snapshot!.products);
      sales
        ..clear()
        ..addAll(commit.snapshot!.sales);
      _syncCartWithCatalog();
    } else {
      products
        ..clear()
        ..addAll(productsAfterCheckout);
      sales
        ..clear()
        ..addAll([commit.sale, ...salesAfterCheckout.skip(1)]);
    }
    cart.clear();
    _markSynced();
    notifyListeners();
    return commit.sale;
  }

  // ---------------- Inventory CRUD ----------------
  Future<void> addProduct({
    required String name,
    required String category,
    required double sell,
    required double buy,
    required int stock,
  }) async {
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Product name is required.');
    }
    final created = await repository.createProduct(
      Product(
          id: 'p${DateTime.now().microsecondsSinceEpoch}',
          name: normalizedName,
          category: _normalizeCategory(category),
          sell: _nonNegativeAmount(sell),
          buy: _nonNegativeAmount(buy),
          stock: _nonNegativeStock(stock)),
    );
    products.add(created);
    _markSynced();
    notifyListeners();
  }

  Future<void> updateProduct(
    String id, {
    required String name,
    required String category,
    required double sell,
    required double buy,
    required int stock,
  }) async {
    final p = productById(id);
    if (p == null) return;
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Product name is required.');
    }
    final updated = await repository.updateProduct(
      Product(
        id: id,
        name: normalizedName,
        category: _normalizeCategory(category),
        sell: _nonNegativeAmount(sell),
        buy: _nonNegativeAmount(buy),
        stock: _nonNegativeStock(stock),
      ),
    );

    _applyProduct(p, updated);
    _syncCartForProduct(p);
    _markSynced();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await repository.deleteProduct(id);
    products.removeWhere((p) => p.id == id);
    cart.remove(id);
    _markSynced();
    notifyListeners();
  }

  void _syncCartForProduct(Product p) {
    final qty = cart[p.id];
    if (qty == null) return;
    if (!p.sellable) {
      cart.remove(p.id);
      return;
    }
    if (qty > p.stock) {
      cart[p.id] = p.stock;
    }
  }

  void _syncCartWithCatalog() {
    for (final entry in cart.entries.toList()) {
      final product = productById(entry.key);
      if (product == null || !product.sellable) {
        cart.remove(entry.key);
        continue;
      }
      if (entry.value > product.stock) {
        cart[entry.key] = product.stock;
      }
    }
  }

  // ---------------- Reports ----------------
  double get totalRevenue => sales.fold(0.0, (a, s) => a + s.total);
  double get totalProfit => sales.fold(0.0, (a, s) => a + s.profit);
  int get totalUnits => sales.fold(0, (a, s) => a + s.unitCount);

  /// name -> (qty, revenue), sorted by revenue desc.
  List<MapEntry<String, List<double>>> topProducts({int limit = 10}) {
    final tally = <String, List<double>>{};
    for (final s in sales) {
      for (final it in s.items) {
        final e = tally.putIfAbsent(it.name, () => [0, 0]);
        e[0] += it.qty;
        e[1] += it.subtotal;
      }
    }
    final entries = tally.entries.toList()
      ..sort((a, b) => b.value[1].compareTo(a.value[1]));
    return entries.take(limit).toList();
  }

  Future<void> clearHistory() async {
    await repository.clearSales();
    sales.clear();
    _markSynced();
    notifyListeners();
  }
}
