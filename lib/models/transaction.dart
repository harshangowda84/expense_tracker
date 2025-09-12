enum ExpenseCategory {
  food,
  travel,
  bills,
  shopping,
  entertainment,
  other,
}

class ExpenseTransaction {
  String id;
  String accountName;
  double amount;
  DateTime date;
  ExpenseCategory category;
  String note;

  ExpenseTransaction({
    required this.id,
    required this.accountName,
    required this.amount,
    required this.date,
    required this.category,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'accountName': accountName,
        'amount': amount.toString(),
        'date': date.toIso8601String(),
        'category': category.index.toString(),
        'note': note,
      };

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      accountName: map['accountName'] ?? '',
      amount: double.tryParse(map['amount'] ?? '0') ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      category: ExpenseCategory.values[int.tryParse(map['category'] ?? '0') ?? 0],
      note: map['note'] ?? '',
    );
  }
}
