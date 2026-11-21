class TxnItem {
  final int? id;
  final String title;
  final double amount;
  final double profit;
  final String type;
  final String date;

  TxnItem({
    this.id,
    required this.title,
    required this.amount,
    required this.profit,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'profit': profit,
        'type': type,
        'date': date,
      };

  factory TxnItem.fromMap(Map<String, dynamic> m) => TxnItem(
        id: m['id'] as int?,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        profit: (m['profit'] as num? ?? 0).toDouble(),
        type: (m['type'] as String?) ?? 'عام',
        date: m['date'] as String,
      );
}
