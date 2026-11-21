class ProductSale {
  final int? id;
  final String name;
  final int qty;
  final double buy;
  final double sell;
  final String date;

  ProductSale({
    this.id,
    required this.name,
    required this.qty,
    required this.buy,
    required this.sell,
    required this.date,
  });

  double get totalSell => sell * qty;
  double get profit => (sell - buy) * qty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'qty': qty,
        'buy': buy,
        'sell': sell,
        'date': date,
      };

  factory ProductSale.fromMap(Map<String, dynamic> m) => ProductSale(
        id: m['id'] as int?,
        name: m['name'] as String,
        qty: (m['qty'] as num).toInt(),
        buy: (m['buy'] as num).toDouble(),
        sell: (m['sell'] as num).toDouble(),
        date: m['date'] as String,
      );
}
