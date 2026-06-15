class SaleItem {
  final String productId;
  final String name;
  final double price;
  final double cost;
  final int qty;

  SaleItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.cost,
    required this.qty,
  });

  double get subtotal => price * qty;
  double get profit => (price - cost) * qty;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'cost': cost,
        'qty': qty,
      };

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        productId: j['productId'] as String,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        cost: (j['cost'] as num).toDouble(),
        qty: (j['qty'] as num).toInt(),
      );
}

class Sale {
  final String id;
  final DateTime ts;
  final List<SaleItem> items;
  final double total;
  final double cash;
  final double change;

  Sale({
    required this.id,
    required this.ts,
    required this.items,
    required this.total,
    required this.cash,
    required this.change,
  });

  int get unitCount => items.fold(0, (a, i) => a + i.qty);
  double get profit => items.fold(0.0, (a, i) => a + i.profit);

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': ts.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'cash': cash,
        'change': change,
      };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j['id'] as String,
        ts: DateTime.parse(j['ts'] as String),
        items: (j['items'] as List)
            .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (j['total'] as num).toDouble(),
        cash: (j['cash'] as num).toDouble(),
        change: (j['change'] as num).toDouble(),
      );
}
