class Product {
  String id;
  String name;
  String category;
  double sell;
  double buy;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sell,
    required this.buy,
    required this.stock,
  });

  bool get sellable => sell > 0 && stock > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'sell': sell,
        'buy': buy,
        'stock': stock,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        category: (j['category'] ?? 'OTHER') as String,
        sell: (j['sell'] as num).toDouble(),
        buy: (j['buy'] as num).toDouble(),
        stock: (j['stock'] as num).toInt(),
      );
}
