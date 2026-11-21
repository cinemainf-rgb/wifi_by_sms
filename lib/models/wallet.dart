class Wallet {
  final int? id;
  final String name;
  final double balance;
  final double outLimit;

  Wallet({
    this.id,
    required this.name,
    required this.balance,
    required this.outLimit,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'balance': balance,
        'outLimit': outLimit,
      };

  factory Wallet.fromMap(Map<String, dynamic> m) => Wallet(
        id: m['id'] as int?,
        name: m['name'] as String,
        balance: (m['balance'] as num).toDouble(),
        outLimit: (m['outLimit'] as num).toDouble(),
      );

  Wallet copyWith({
    int? id,
    String? name,
    double? balance,
    double? outLimit,
  }) =>
      Wallet(
        id: id ?? this.id,
        name: name ?? this.name,
        balance: balance ?? this.balance,
        outLimit: outLimit ?? this.outLimit,
      );
}
