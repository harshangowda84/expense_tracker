class CreditCard {
  final String name;
  final double limit;
  final int dueDate;
  final DateTime addedDate;
  final double? usedAmount;

  CreditCard({
    required this.name,
    required this.limit,
    required this.dueDate,
    required this.addedDate,
    this.usedAmount,
  });

  CreditCard copyWith({
    String? name,
    double? limit,
    int? dueDate,
    DateTime? addedDate,
    double? usedAmount,
  }) {
    return CreditCard(
      name: name ?? this.name,
      limit: limit ?? this.limit,
      dueDate: dueDate ?? this.dueDate,
      addedDate: addedDate ?? this.addedDate,
      usedAmount: usedAmount ?? this.usedAmount,
    );
  }

  double get availableBalance => limit - (usedAmount ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'limit': limit.toString(),
      'dueDate': dueDate.toString(),
      'addedDate': addedDate.toIso8601String(),
      'usedAmount': (usedAmount ?? 0).toString(),
    };
  }

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      name: map['name'] ?? '',
      limit: double.tryParse(map['limit'] ?? '0') ?? 0,
      dueDate: int.tryParse(map['dueDate'] ?? '1') ?? 1,
      addedDate: DateTime.tryParse(map['addedDate'] ?? '') ?? DateTime.now(),
      usedAmount: double.tryParse(map['usedAmount'] ?? '0'),
    );
  }
}
