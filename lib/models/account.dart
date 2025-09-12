class Account {
  String name;
  double balance;
  DateTime balanceDate;

  Account({
    required this.name,
    required this.balance,
    required this.balanceDate,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'balance': balance.toString(),
        'balanceDate': balanceDate.toIso8601String(),
      };

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      name: map['name'] ?? '',
      balance: double.tryParse(map['balance'] ?? '0') ?? 0.0,
      balanceDate: DateTime.tryParse(map['balanceDate'] ?? '') ?? DateTime.now(),
    );
  }

  Account copyWith({
    String? name,
    double? balance,
    DateTime? balanceDate,
  }) {
    return Account(
      name: name ?? this.name,
      balance: balance ?? this.balance,
      balanceDate: balanceDate ?? this.balanceDate,
    );
  }
}
