class Machine {
  final int? id;
  final String name;
  final double balance;
  final double limit;

  Machine({
    this.id,
    required this.name,
    required this.balance,
    required this.limit,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'balance': balance,
        'limit_val': limit,
      };

  factory Machine.fromMap(Map<String, dynamic> m) => Machine(
        id: m['id'] as int?,
        name: m['name'] as String,
        balance: (m['balance'] as num).toDouble(),
        limit: (m['limit_val'] as num).toDouble(),
      );

  Machine copyWith({
    int? id,
    String? name,
    double? balance,
    double? limit,
  }) =>
      Machine(
        id: id ?? this.id,
        name: name ?? this.name,
        balance: balance ?? this.balance,
        limit: limit ?? this.limit,
      );
}
