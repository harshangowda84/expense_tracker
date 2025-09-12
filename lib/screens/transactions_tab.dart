import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../providers/data_provider.dart';

class TransactionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Selector<DataProvider, List<ExpenseTransaction>>(
            selector: (_, provider) => provider.transactions,
            builder: (context, transactions, _) {
              if (transactions.isEmpty)
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              return ListView.builder(
                itemCount: transactions.length,
                padding: const EdgeInsets.only(top: 8),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Dismissible(
                    key: Key(tx.id),
                    background: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(context, 'transaction'),
                    onDismissed: (_) {
                      Provider.of<DataProvider>(context, listen: false).deleteTransaction(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Transaction deleted'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onLongPress: () async {
                          if (await _confirmDelete(context, 'transaction')) {
                            if (context.mounted) {
                              Provider.of<DataProvider>(context, listen: false).deleteTransaction(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Transaction deleted'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                  duration: Duration(milliseconds: 1500),
                                ),
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Account and category info
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.accountName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tx.category.name[0].toUpperCase() + tx.category.name.substring(1),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Amount and date
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '\u20b9${tx.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(tx.date),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete button
                                  SizedBox(
                                    width: 48,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red,
                                      onPressed: () async {
                                        if (await _confirmDelete(context, 'transaction')) {
                                          if (context.mounted) {
                                            Provider.of<DataProvider>(context, listen: false).deleteTransaction(index);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Transaction deleted'),
                                                backgroundColor: Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                                margin: EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                                duration: Duration(milliseconds: 1500),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (tx.note.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tx.note,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ); // End of Dismissible
                }, // End of itemBuilder
              ); // End of ListView.builder
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Selector<DataProvider, List<Account>>(
            selector: (_, provider) => provider.accounts,
            builder: (context, accounts, _) => ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Transaction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: accounts.isEmpty ? null : () => _showAddTransactionDialog(context, accounts),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
  const TransactionsTab({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekday[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Transaction',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this $title?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  void _showAddTransactionDialog(BuildContext context, List<Account> accounts) {
    String accountName = accounts.isNotEmpty ? accounts[0].name : '';
    String amount = '';
    ExpenseCategory category = ExpenseCategory.food;
    String note = '';
    String? amountError;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  reverse: true,
                  padding: EdgeInsets.only(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 12,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Add Transaction',
                                  style: Theme.of(stateContext).textTheme.titleLarge?.copyWith(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.deepPurple, size: 28),
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  tooltip: 'Close',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<String>(
                              value: accountName.isEmpty ? null : accountName,
                              items: accounts.map((a) => DropdownMenuItem(
                                value: a.name,
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, color: Colors.deepPurple.shade300),
                                    const SizedBox(width: 8),
                                    Text(
                                      a.name,
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (v) => setState(() => accountName = v ?? ''),
                              decoration: InputDecoration(
                                labelText: 'Account',
                                prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.deepPurple.shade300),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple.shade300),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.currency_rupee, color: Colors.deepPurple.shade300),
                                errorText: amountError,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) {
                                setState(() {
                                  amount = v;
                                  amountError = null;
                                  if (amount.isEmpty) {
                                    amountError = 'Amount is required';
                                  } else if (double.tryParse(amount) == null || double.parse(amount) <= 0) {
                                    amountError = 'Enter a valid amount';
                                  } else {
                                    final selectedAccount = accounts.firstWhere(
                                      (a) => a.name == accountName,
                                      orElse: () => Account(name: '', balance: 0, balanceDate: DateTime.now()),
                                    );
                                    if (double.parse(amount) > selectedAccount.balance) {
                                      amountError = 'Amount exceeds account balance';
                                    }
                                  }
                                });
                              },
                              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 18),
                            DropdownButtonFormField<ExpenseCategory>(
                              value: category,
                              items: ExpenseCategory.values.map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(Icons.category, color: Colors.deepPurple.shade300),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.name[0].toUpperCase() + c.name.substring(1),
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (v) => setState(() => category = v ?? ExpenseCategory.food),
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category, color: Colors.deepPurple.shade300),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple.shade300),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Note',
                                prefixIcon: Icon(Icons.note, color: Colors.deepPurple.shade300),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onChanged: (v) => setState(() => note = v),
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.deepPurple,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                FloatingActionButton.extended(
                                  heroTag: 'addTxFab',
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  onPressed: (accountName.isEmpty || amountError != null || amount.isEmpty || isSubmitting)
                                      ? null
                                      : () async {
                                          setState(() => isSubmitting = true);
                                          try {
                                            final enteredAmount = double.parse(amount);
                                            await Provider.of<DataProvider>(context, listen: false).addTransaction(
                                              ExpenseTransaction(
                                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                                accountName: accountName,
                                                amount: enteredAmount,
                                                date: DateTime.now(),
                                                category: category,
                                                note: note,
                                              ),
                                            );
                                            if (dialogContext.mounted) {
                                              Navigator.of(dialogContext).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Text('Transaction added successfully!'),
                                                  backgroundColor: Colors.deepPurple,
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                                  duration: Duration(milliseconds: 1500),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            setState(() => isSubmitting = false);
                                            if (dialogContext.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error adding transaction: $e'),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                                  duration: Duration(milliseconds: 1500),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  label: isSubmitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                        )
                                      : const Text('Add'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
