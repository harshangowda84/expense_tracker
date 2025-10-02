enum IncomeCategory {
  salary,
  freelance,
  business,
  investment,
  bonus,
  refund,
  gift,
  other,
}

class IncomeTransaction {
  String id;
  String accountName;
  double amount;
  DateTime date;
  IncomeCategory category;
  String note;
  String source; // Who/where the income came from

  IncomeTransaction({
    required this.id,
    required this.accountName,
    required this.amount,
    required this.date,
    required this.category,
    this.note = '',
    this.source = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'accountName': accountName,
        'amount': amount.toString(),
        'date': date.toIso8601String(),
        'category': category.index.toString(),
        'note': note,
        'source': source,
      };

  factory IncomeTransaction.fromMap(Map<String, dynamic> map) {
    return IncomeTransaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      accountName: map['accountName'] ?? '',
      amount: double.tryParse(map['amount'] ?? '0') ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      category: IncomeCategory.values[int.tryParse(map['category'] ?? '0') ?? 0],
      note: map['note'] ?? '',
      source: map['source'] ?? '',
    );
  }

  IncomeTransaction copyWith({
    String? id,
    String? accountName,
    double? amount,
    DateTime? date,
    IncomeCategory? category,
    String? note,
    String? source,
  }) {
    return IncomeTransaction(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      source: source ?? this.source,
    );
  }
}