import 'package:flutter/foundation.dart';class CreditCard {

  final String id;

class CreditCard {  final String cardHolder;

  final String id;  final String cardNumber; // Masked or encrypted if needed

  final String cardHolder;  final String expiryDate;

  final String cardNumber;  final String bankName;

  final String expiryDate;  final double creditLimit;

  final String bankName;  double balance; // Current due

  final double creditLimit;  DateTime dueDate;

  final double balance;  String? note;

  final String dueDate;

  final String note;  CreditCard({

    required this.id,

  CreditCard({    required this.cardHolder,

    required this.id,    required this.cardNumber,

    required this.cardHolder,    required this.expiryDate,

    required this.cardNumber,    required this.bankName,

    required this.expiryDate,    required this.creditLimit,

    required this.bankName,    required this.balance,

    required this.creditLimit,    required this.dueDate,

    required this.balance,    this.note,

    required this.dueDate,  });

    required this.note,}

  });

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'] ?? '',
      cardHolder: map['cardHolder'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      bankName: map['bankName'] ?? '',
      creditLimit: (map['creditLimit'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      dueDate: map['dueDate'] ?? '',
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardHolder': cardHolder,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'bankName': bankName,
      'creditLimit': creditLimit,
      'balance': balance,
      'dueDate': dueDate,
      'note': note,
    };
  }
}
