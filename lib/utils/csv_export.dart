import 'package:csv/csv.dart';
import '../models/transaction.dart';

String exportTransactionsToCsv(List<ExpenseTransaction> transactions) {
  List<List<dynamic>> rows = [
    ['ID', 'Account', 'Amount', 'Date', 'Category', 'Note'],
  ];
  for (var tx in transactions) {
    rows.add([
      tx.id,
      tx.accountName,
      tx.amount,
      tx.date.toIso8601String(),
      tx.category.toString().split('.').last,
      tx.note,
    ]);
  }
  return const ListToCsvConverter().convert(rows);
}
