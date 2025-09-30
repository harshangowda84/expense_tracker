import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/data_provider.dart';

class AccountTransactionsPage extends StatelessWidget {
  final String accountName;
  const AccountTransactionsPage({Key? key, required this.accountName}) : super(key: key);

  String formatIndianAmount(double amount) {
    String sign = amount < 0 ? '-' : '';
    amount = amount.abs();
    String str = amount.toStringAsFixed(2);
    List<String> parts = str.split('.');
    String num = parts[0];
    String dec = parts[1];
    if (num.length > 3) {
      String first = num.substring(0, num.length - 3);
      String last = num.substring(num.length - 3);
      List<String> firstParts = [];
      while (first.length > 2) {
        firstParts.insert(0, first.substring(first.length - 2));
        first = first.substring(0, first.length - 2);
      }
      if (first.isNotEmpty) firstParts.insert(0, first);
      num = firstParts.join(',') + ',' + last;
    }
        return '₹$sign$num.$dec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions: $accountName'),
      ),
      body: Selector<DataProvider, List<ExpenseTransaction>>(
        selector: (_, provider) => provider.transactions,
        builder: (context, transactions, _) {
          final filtered = transactions.where((tx) => tx.accountName == accountName).toList();
          if (filtered.isEmpty) {
            return Center(
              child: Text('No transactions for this account.'),
            );
          }
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final tx = filtered[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(formatIndianAmount(tx.amount)),
                  subtitle: Text('${tx.category.name} • ${tx.note}'),
                  trailing: Text('${tx.date.day}/${tx.date.month}/${tx.date.year}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
