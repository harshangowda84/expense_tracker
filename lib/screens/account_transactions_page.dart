import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/income_transaction.dart';
import '../providers/data_provider.dart';
import '../utils/income_category_utils.dart';

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

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.office:
        return Icons.work;
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.travel:
        return Icons.directions_car;
      case ExpenseCategory.bills:
        return Icons.receipt;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.office:
        return const Color(0xFF9B59B6);
      case ExpenseCategory.food:
        return const Color(0xFFFF6B6B);
      case ExpenseCategory.travel:
        return const Color(0xFF4ECDC4);
      case ExpenseCategory.bills:
        return const Color(0xFFFFE66D);
      case ExpenseCategory.shopping:
        return const Color(0xFF95E1D3);
      case ExpenseCategory.entertainment:
        return const Color(0xFFAB83A1);
      case ExpenseCategory.other:
        return const Color(0xFF6C7CE0);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    String timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0) {
      return 'Today, $timeStr';
    } else if (diff.inDays == 1) {
      return 'Yesterday, $timeStr';
    } else if (diff.inDays < 7) {
      final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekday[date.weekday - 1]}, $timeStr';
    } else {
      return '$dateStr $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$accountName Transactions'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Consumer<DataProvider>(
          builder: (context, provider, _) {
            // Combine expense and income transactions for this account
            final expenseTransactions = provider.transactions
                .where((tx) => tx.accountName == accountName)
                .toList();
                
            final incomeTransactions = provider.incomeTransactions
                .where((tx) => tx.accountName == accountName)
                .toList();
            
            // Create a combined list with transaction type info
            final List<Map<String, dynamic>> allTransactions = [];
            
            // Add expense transactions
            for (final tx in expenseTransactions) {
              allTransactions.add({
                'type': 'expense',
                'transaction': tx,
                'date': tx.date,
              });
            }
            
            // Add income transactions
            for (final tx in incomeTransactions) {
              allTransactions.add({
                'type': 'income',
                'transaction': tx,
                'date': tx.date,
              });
            }
            
            // Sort by date (newest first)
            allTransactions.sort((a, b) => b['date'].compareTo(a['date']));
            
            if (allTransactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transactions for $accountName will appear here',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            // Calculate totals (without net balance)
            final totalSpent = allTransactions
                .where((item) => item['type'] == 'expense')
                .fold<double>(0, (sum, item) => sum + (item['transaction'] as ExpenseTransaction).amount);
                
            final totalIncome = allTransactions
                .where((item) => item['type'] == 'income')
                .fold<double>(0, (sum, item) => sum + (item['transaction'] as IncomeTransaction).amount);
            
            final totalTransactions = allTransactions.length;
            
            // Check if this is a credit card or bank account
            final isCreditCard = provider.creditCards.any((card) => card.name == accountName);
            
            return Column(
              children: [
                // Summary Card (without Net Balance)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isCreditCard 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Spent',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatIndianAmount(totalSpent),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Transactions',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalTransactions.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Income',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatIndianAmount(totalIncome),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Total Spent',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatIndianAmount(totalSpent),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Transactions',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalTransactions.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                ),
                // Transactions List
                Expanded(
                  child: ListView.builder(
                    itemCount: allTransactions.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final item = allTransactions[index];
                      final isIncome = item['type'] == 'income';
                      
                      if (isIncome) {
                        final tx = item['transaction'] as IncomeTransaction;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: Icon(
                                IncomeCategoryUtils.getCategoryIcon(tx.category),
                                color: IncomeCategoryUtils.getCategoryColor(tx.category),
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  IncomeCategoryUtils.getCategoryName(tx.category),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'INCOME',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tx.source.isNotEmpty) 
                                  Text(
                                    tx.source,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                if (tx.note.isNotEmpty) 
                                  Text(
                                    tx.note,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                Text(
                                  _formatDate(tx.date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '+${formatIndianAmount(tx.amount)}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      } else {
                        final tx = item['transaction'] as ExpenseTransaction;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getCategoryColor(tx.category).withOpacity(0.1),
                              child: Icon(
                                _getCategoryIcon(tx.category),
                                color: _getCategoryColor(tx.category),
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  tx.category.name[0].toUpperCase() + tx.category.name.substring(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'EXPENSE',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tx.note.isNotEmpty) 
                                  Text(
                                    tx.note,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                Text(
                                  _formatDate(tx.date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '-${formatIndianAmount(tx.amount)}',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
