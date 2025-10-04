enum ExpenseCategory {
  office,
  food,
  travel,
  bills,
  shopping,
  entertainment,
  other,
}

enum TransactionSourceType {
  bankAccount,
  creditCard,
}

class ExpenseTransaction {
  String id;
  String accountName;
  double amount;
  DateTime date;
  ExpenseCategory category;
  String note;
  TransactionSourceType sourceType;
  bool isReceivable;
  double receivableAmount;
  bool isReceivablePaid;
  double receivableAmountPaid;

  ExpenseTransaction({
    required this.id,
    required this.accountName,
    required this.amount,
    required this.date,
    required this.category,
    this.note = '',
    this.sourceType = TransactionSourceType.bankAccount,
    this.isReceivable = false,
    this.receivableAmount = 0.0,
    this.isReceivablePaid = false,
    this.receivableAmountPaid = 0.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'accountName': accountName,
        'amount': amount.toString(),
        'date': date.toIso8601String(),
        'category': category.index.toString(),
        'note': note,
        'sourceType': sourceType.index.toString(),
        'isReceivable': isReceivable.toString(),
        'receivableAmount': receivableAmount.toString(),
        'isReceivablePaid': isReceivablePaid.toString(),
        'receivableAmountPaid': receivableAmountPaid.toString(),
      };

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      accountName: map['accountName'] ?? '',
      amount: double.tryParse(map['amount'] ?? '0') ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      category: ExpenseCategory.values[int.tryParse(map['category'] ?? '0') ?? 0],
      note: map['note'] ?? '',
      sourceType: map['sourceType'] != null
          ? TransactionSourceType.values[int.tryParse(map['sourceType'] ?? '0') ?? 0]
          : TransactionSourceType.bankAccount,
      isReceivable: map['isReceivable'] == 'true',
      receivableAmount: double.tryParse(map['receivableAmount'] ?? '0') ?? 0.0,
      isReceivablePaid: map['isReceivablePaid'] == 'true',
      receivableAmountPaid: double.tryParse(map['receivableAmountPaid'] ?? '0') ?? 0.0,
    );
  }

  ExpenseTransaction copyWith({
    String? id,
    String? accountName,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? note,
    TransactionSourceType? sourceType,
    bool? isReceivable,
    double? receivableAmount,
    bool? isReceivablePaid,
    double? receivableAmountPaid,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      sourceType: sourceType ?? this.sourceType,
      isReceivable: isReceivable ?? this.isReceivable,
      receivableAmount: receivableAmount ?? this.receivableAmount,
      isReceivablePaid: isReceivablePaid ?? this.isReceivablePaid,
      receivableAmountPaid: receivableAmountPaid ?? this.receivableAmountPaid,
    );
  }
}
