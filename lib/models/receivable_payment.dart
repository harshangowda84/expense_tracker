class ReceivablePayment {
  final String id;
  final String transactionId;
  final double amount;
  final DateTime date;

  ReceivablePayment({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'transactionId': transactionId,
        'amount': amount.toString(),
        'date': date.toIso8601String(),
      };

  factory ReceivablePayment.fromMap(Map<String, dynamic> map) {
    return ReceivablePayment(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      transactionId: map['transactionId'] ?? '',
      amount: double.tryParse(map['amount'] ?? '0') ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }
}
