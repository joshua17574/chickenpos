import 'package:chicken_cuts_pos/models/product.dart';
import 'package:chicken_cuts_pos/models/sale.dart';
import 'package:chicken_cuts_pos/services/pos_repository.dart';
import 'package:chicken_cuts_pos/services/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Store', () {
    test('seeds the catalog and blocks unsellable products', () async {
      final store = Store();
      await store.init();

      expect(store.products.length, 10);
      expect(store.addToCart('p6'), isFalse);
      expect(store.addToCart('p4'), isFalse);
      expect(store.cartItemCount, 0);
    });

    test(
      'checkout records a sale, clears the cart, and reduces stock',
      () async {
        final store = Store();
        await store.init();

        expect(store.addToCart('p1'), isTrue);
        final sale = await store.checkout(cash: 10);

        expect(sale.total, 5);
        expect(sale.cash, 10);
        expect(sale.change, 5);
        expect(sale.items.single.name, 'MAGIC SARAP');
        expect(store.productById('p1')!.stock, 6);
        expect(store.sales.single.id, sale.id);
        expect(store.cartItemCount, 0);
      },
    );

    test('checkout rejects cash below the total', () async {
      final store = Store();
      await store.init();

      expect(store.addToCart('p1'), isTrue);

      await expectLater(
        store.checkout(cash: 4),
        throwsA(isA<CheckoutException>()),
      );
      expect(store.cartItemCount, 1);
      expect(store.productById('p1')!.stock, 7);
      expect(store.sales, isEmpty);
    });

    test('inventory updates clamp stale cart quantities', () async {
      final store = Store();
      await store.init();

      expect(store.addToCart('p1'), isTrue);
      expect(store.addToCart('p1'), isTrue);

      await store.updateProduct(
        'p1',
        name: 'Magic Sarap',
        category: 'grocery',
        sell: 5,
        buy: 3,
        stock: 1,
      );

      expect(store.cartQty('p1'), 1);

      await store.updateProduct(
        'p1',
        name: 'Magic Sarap',
        category: 'grocery',
        sell: 0,
        buy: 3,
        stock: 1,
      );

      expect(store.cartQty('p1'), 0);
    });

    test('recovers from corrupt persisted data', () async {
      SharedPreferences.setMockInitialValues({
        'pos_products_v1': 'not-json',
        'pos_sales_v1': '{"bad":true}',
      });

      final store = Store();
      await store.init();

      expect(store.products.length, 10);
      expect(store.sales, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pos_products_v1'), isNot('not-json'));
      expect(prefs.getString('pos_sales_v1'), isNot('{"bad":true}'));
    });

    test('normalizes product input and rejects blank names', () async {
      final store = Store();
      await store.init();

      await store.addProduct(
        name: '  breast   fillet  ',
        category: ' grocery ',
        sell: -12,
        buy: double.nan,
        stock: -4,
      );

      final product = store.products.last;
      expect(product.name, 'breast fillet');
      expect(product.category, 'GROCERY');
      expect(product.sell, 0);
      expect(product.buy, 0);
      expect(product.stock, 0);

      await expectLater(
        store.addProduct(
          name: '   ',
          category: 'grocery',
          sell: 1,
          buy: 1,
          stock: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('uses the injected repository for database-ready persistence',
        () async {
      final repo = _FakePosRepository(
        products: [
          Product(
            id: 'db-1',
            name: 'BREAST FILLET',
            category: 'CUTS',
            sell: 120,
            buy: 90,
            stock: 2,
          ),
        ],
        sales: [],
      );
      final store = Store(repository: repo);
      await store.init();

      expect(store.products.single.id, 'db-1');
      expect(store.sellableCount, 1);
      expect(store.totalStockUnits, 2);

      expect(store.addToCart('db-1'), isTrue);
      final sale = await store.checkout(cash: 150);

      expect(repo.committedSale?.id, sale.id);
      expect(repo.commitCount, 1);
      expect(repo.products.single.stock, 1);
      expect(repo.sales.single.id, sale.id);
    });

    test('refresh applies database stock changes and clamps the cart',
        () async {
      final repo = _FakePosRepository(
        products: [
          Product(
            id: 'db-1',
            name: 'BREAST FILLET',
            category: 'CUTS',
            sell: 120,
            buy: 90,
            stock: 4,
          ),
        ],
        sales: [],
      );
      final store = Store(repository: repo, usesRemoteData: true);
      await store.init();

      expect(store.addToCart('db-1'), isTrue);
      expect(store.addToCart('db-1'), isTrue);

      repo.products = [
        Product(
          id: 'db-1',
          name: 'BREAST FILLET',
          category: 'CUTS',
          sell: 120,
          buy: 90,
          stock: 1,
        ),
      ];

      await store.refreshFromRepository();

      expect(store.productById('db-1')!.stock, 1);
      expect(store.cartQty('db-1'), 1);
      expect(store.syncError, isNull);
      expect(store.lastSyncedAt, isNotNull);
    });
  });
}

class _FakePosRepository implements PosRepository {
  _FakePosRepository({required this.products, required this.sales});

  List<Product> products;
  List<Sale> sales;
  Sale? committedSale;
  int commitCount = 0;

  @override
  Future<PosSnapshot> load() async => PosSnapshot(
        products: products,
        sales: sales,
      );

  @override
  Future<Product> createProduct(Product product) async {
    products = [...products, product];
    return product;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    products = products.map((p) => p.id == product.id ? product : p).toList();
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    products = products.where((p) => p.id != id).toList();
  }

  @override
  Future<void> clearSales() async {
    sales = [];
  }

  @override
  Future<CheckoutCommit> commitCheckout({
    required List<Product> products,
    required List<Sale> sales,
    required Sale sale,
  }) async {
    committedSale = sale;
    commitCount++;
    this.products = List<Product>.of(products);
    this.sales = List<Sale>.of(sales);
    return CheckoutCommit(sale: sale);
  }
}
