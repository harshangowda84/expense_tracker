import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/credit_card.dart';
import '../providers/data_provider.dart';

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

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
      num = '${firstParts.join(',')},${last}';
    }
    return '₹$sign$num.$dec';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    String timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0) {
      return 'Today, $dateStr $timeStr';
    } else if (diff.inDays == 1) {
      return 'Yesterday, $dateStr $timeStr';
    } else if (diff.inDays < 7) {
      final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekday[date.weekday - 1]}, $dateStr $timeStr';
    } else {
      return '$dateStr $timeStr';
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
              colors: [Color(0xFFEF4444), Color(0xFFEC4899)], // Modern red to pink for delete
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

  void _showEditTransactionDialog(BuildContext context, List<Account> accounts, ExpenseTransaction tx, int txIndex) {
    String accountName = tx.accountName;
    ExpenseCategory category = tx.category;
    String? amountError;
    bool isSubmitting = false;
    final amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
    final noteController = TextEditingController(text: tx.note);
    TransactionSourceType sourceType = tx.sourceType;

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
                                  'Edit Transaction',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6366F1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Color(0xFF6366F1), size: 28),
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  tooltip: 'Close',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: Material(
                                    color: sourceType == TransactionSourceType.bankAccount
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey[200],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          sourceType = TransactionSourceType.bankAccount;
                                          accountName = accounts.isNotEmpty ? accounts[0].name : '';
                                          amountError = null;
                                        });
                                      },
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.account_balance_wallet,
                                              color: sourceType == TransactionSourceType.bankAccount
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Account',
                                              style: TextStyle(
                                                color: sourceType == TransactionSourceType.bankAccount
                                                    ? Colors.white
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Material(
                                    color: sourceType == TransactionSourceType.creditCard
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey[200],
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        final creditCards = Provider.of<DataProvider>(context, listen: false).creditCards;
                                        setState(() {
                                          sourceType = TransactionSourceType.creditCard;
                                          accountName = creditCards.isNotEmpty ? creditCards[0].name : '';
                                          amountError = null;
                                        });
                                      },
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.credit_card,
                                              color: sourceType == TransactionSourceType.creditCard
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Credit Card',
                                              style: TextStyle(
                                                color: sourceType == TransactionSourceType.creditCard
                                                    ? Colors.white
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: accountName.isEmpty ? null : accountName,
                              items: (sourceType == TransactionSourceType.bankAccount
                                      ? accounts.cast<dynamic>()
                                      : Provider.of<DataProvider>(context, listen: false).creditCards.cast<dynamic>())
                                  .map<DropdownMenuItem<String>>((a) => DropdownMenuItem<String>(
                                    value: a.name,
                                    child: Row(
                                      children: [
                                        Icon(
                                          sourceType == TransactionSourceType.bankAccount
                                              ? Icons.account_balance_wallet
                                              : Icons.credit_card,
                                          color: const Color(0xFF8B5CF6)
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          a.name,
                                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                              onChanged: (v) => setState(() {
                                accountName = v ?? '';
                                amountError = null; // Reset error when source changes
                              }),
                              decoration: InputDecoration(
                                labelText: sourceType == TransactionSourceType.bankAccount ? 'Account' : 'Credit Card',
                                prefixIcon: Icon(
                                  sourceType == TransactionSourceType.bankAccount
                                      ? Icons.account_balance_wallet
                                      : Icons.credit_card,
                                  color: const Color(0xFF8B5CF6)
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.currency_rupee, color: const Color(0xFF8B5CF6)),
                                errorText: amountError,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              controller: amountController,
                              onChanged: (v) {
                                setState(() {
                                  amountError = null;
                                  if (v.isEmpty) {
                                    amountError = 'Amount is required';
                                  } else if (double.tryParse(v) == null || double.parse(v) <= 0) {
                                    amountError = 'Enter a valid amount';
                                  } else if (sourceType == TransactionSourceType.bankAccount) {
                                    final selectedAccount = accounts.firstWhere(
                                      (a) => a.name == accountName,
                                      orElse: () => Account(name: '', balance: 0, balanceDate: DateTime.now()),
                                    );
                                    if (double.parse(v) > selectedAccount.balance + tx.amount) {
                                      amountError = 'Amount exceeds account balance';
                                    }
                                  } else {
                                    final selectedCard = Provider.of<DataProvider>(context, listen: false)
                                        .creditCards
                                        .firstWhere(
                                          (c) => c.name == accountName,
                                          orElse: () => CreditCard(
                                            name: '',
                                            limit: 0,
                                            dueDate: 1,
                                            addedDate: DateTime.now(),
                                          ),
                                        );
                                    if (double.parse(v) > selectedCard.availableBalance + tx.amount) {
                                      amountError = 'Amount exceeds available credit limit';
                                    }
                                  }
                                });
                              },
                              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 18),
                            DropdownButtonFormField<ExpenseCategory>(
                              initialValue: category,
                              items: ExpenseCategory.values.map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(Icons.category, color: const Color(0xFF8B5CF6)),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.name[0].toUpperCase() + c.name.substring(1),
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (v) => setState(() => category = v ?? ExpenseCategory.office),
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category, color: const Color(0xFF8B5CF6)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Note',
                                prefixIcon: Icon(Icons.note, color: const Color(0xFF8B5CF6)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              controller: noteController,
                              onChanged: (v) => setState(() {}),
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
                                    foregroundColor: const Color(0xFF6366F1),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                FloatingActionButton.extended(
                                  heroTag: 'editTxFab',
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  onPressed: (accountName.isEmpty || amountError != null || amountController.text.isEmpty || isSubmitting)
                                      ? null
                                      : () async {
                                          setState(() => isSubmitting = true);
                                          try {
                                            final enteredAmount = double.parse(amountController.text);
                                            final updatedTx = ExpenseTransaction(
                                              id: tx.id,
                                              accountName: accountName,
                                              amount: enteredAmount,
                                              date: tx.date,
                                              category: category,
                                              note: noteController.text,
                                              sourceType: sourceType,
                                            );
                                            await Provider.of<DataProvider>(context, listen: false).updateTransaction(txIndex, updatedTx, tx.amount, tx.accountName);
                                            if (dialogContext.mounted) {
                                              Navigator.of(dialogContext).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Text('Transaction updated successfully!'),
                                                  backgroundColor: const Color(0xFF6366F1),
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                                  duration: const Duration(milliseconds: 1500),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            setState(() => isSubmitting = false);
                                            if (dialogContext.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error updating transaction: $e'),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                                  duration: const Duration(milliseconds: 1500),
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
                                      : const Text('Save'),
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

  void _showAddTransactionDialog(BuildContext context, List<Account> accounts) {
    String accountName = accounts.isNotEmpty ? accounts[0].name : '';
    String amount = '';
    ExpenseCategory category = ExpenseCategory.office;
    String note = '';
    String? amountError;
    bool isSubmitting = false;
    TransactionSourceType sourceType = TransactionSourceType.bankAccount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
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
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6366F1), // Modern indigo
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF6366F1), size: 28),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Material(
                              color: sourceType == TransactionSourceType.bankAccount
                                  ? const Color(0xFF6366F1) // Modern indigo
                                  : Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    sourceType = TransactionSourceType.bankAccount;
                                    accountName = accounts.isNotEmpty ? accounts[0].name : '';
                                    amountError = null;
                                  });
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: sourceType == TransactionSourceType.bankAccount
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Account',
                                        style: TextStyle(
                                          color: sourceType == TransactionSourceType.bankAccount
                                              ? Colors.white
                                              : Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Material(
                              color: sourceType == TransactionSourceType.creditCard
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () {
                                  final creditCards = Provider.of<DataProvider>(context, listen: false).creditCards;
                                  setState(() {
                                    sourceType = TransactionSourceType.creditCard;
                                    accountName = creditCards.isNotEmpty ? creditCards[0].name : '';
                                    amountError = null;
                                  });
                                },
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.credit_card,
                                        color: sourceType == TransactionSourceType.creditCard
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Credit Card',
                                        style: TextStyle(
                                          color: sourceType == TransactionSourceType.creditCard
                                              ? Colors.white
                                              : Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: accountName.isEmpty ? null : accountName,
                        items: (sourceType == TransactionSourceType.bankAccount
                                ? accounts.cast<dynamic>()
                                : Provider.of<DataProvider>(context, listen: false).creditCards.cast<dynamic>())
                            .map<DropdownMenuItem<String>>((a) {
                              final isAvailable = Provider.of<DataProvider>(context, listen: false)
                                  .canAddTransactionToAccount(a.name, sourceType);
                              double availableAmount = 0;
                              if (sourceType == TransactionSourceType.bankAccount) {
                                availableAmount = (a as Account).balance;
                              } else {
                                availableAmount = (a as CreditCard).availableBalance;
                              }
                              
                              return DropdownMenuItem<String>(
                                value: a.name,
                                enabled: isAvailable,
                                child: Row(
                                  children: [
                                    Icon(
                                      sourceType == TransactionSourceType.bankAccount
                                          ? Icons.account_balance_wallet
                                          : Icons.credit_card,
                                      color: isAvailable 
                                          ? const Color(0xFF8B5CF6)
                                          : Colors.grey.shade400,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${a.name} (₹${availableAmount.toStringAsFixed(0)})',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isAvailable ? Colors.black87 : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                        onChanged: (v) => setState(() {
                          accountName = v ?? '';
                          amountError = null;
                        }),
                        decoration: InputDecoration(
                          labelText: sourceType == TransactionSourceType.bankAccount ? 'Account' : 'Credit Card',
                          prefixIcon: Icon(
                            sourceType == TransactionSourceType.bankAccount
                                ? Icons.account_balance_wallet
                                : Icons.credit_card,
                            color: const Color(0xFF8B5CF6),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.currency_rupee, color: const Color(0xFF8B5CF6)),
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
                            } else if (sourceType == TransactionSourceType.bankAccount) {
                              final selectedAccount = accounts.firstWhere(
                                (a) => a.name == accountName,
                                orElse: () => Account(name: '', balance: 0, balanceDate: DateTime.now()),
                              );
                              if (double.parse(amount) > selectedAccount.balance) {
                                amountError = 'Amount exceeds account balance';
                              }
                            } else {
                              final selectedCard = Provider.of<DataProvider>(context, listen: false)
                                  .creditCards
                                  .firstWhere(
                                    (c) => c.name == accountName,
                                    orElse: () => CreditCard(
                                      name: '',
                                      limit: 0,
                                      dueDate: 1,
                                      addedDate: DateTime.now(),
                                    ),
                                  );
                              if (double.parse(amount) > selectedCard.availableBalance) {
                                amountError = 'Amount exceeds available credit limit';
                              }
                            }
                          });
                        },
                        style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<ExpenseCategory>(
                        initialValue: category,
                        items: ExpenseCategory.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Icon(Icons.category, color: const Color(0xFF8B5CF6)),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.name[0].toUpperCase() + c.name.substring(1),
                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => category = v ?? ExpenseCategory.office),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category, color: const Color(0xFF8B5CF6)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Note',
                          prefixIcon: Icon(Icons.note, color: const Color(0xFF8B5CF6)),
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
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                            ),
                            child: const Text('Cancel'),
                          ),
                          FloatingActionButton.extended(
                            heroTag: 'addTxFab',
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            onPressed: (accountName.isEmpty || amountError != null || amount.isEmpty || isSubmitting)
                                ? null
                                : () async {
                                    setState(() => isSubmitting = true);
                                    try {
                                      final enteredAmount = double.parse(amount);
                                      
                                      // Validate if account/card exists and has sufficient balance
                                      final dataProvider = Provider.of<DataProvider>(context, listen: false);
                                      if (!dataProvider.canAddTransactionToAccount(accountName, sourceType)) {
                                        throw Exception('Selected ${sourceType == TransactionSourceType.bankAccount ? 'account' : 'credit card'} does not exist');
                                      }
                                      
                                      if (!dataProvider.hasSufficientBalance(accountName, sourceType, enteredAmount)) {
                                        final message = sourceType == TransactionSourceType.bankAccount 
                                            ? 'Insufficient balance in bank account'
                                            : 'Amount exceeds available credit limit';
                                        throw Exception(message);
                                      }
                                      
                                      await dataProvider.addTransaction(
                                        ExpenseTransaction(
                                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                                          accountName: accountName,
                                          amount: enteredAmount,
                                          date: DateTime.now(),
                                          category: category,
                                          note: note,
                                          sourceType: sourceType,
                                        ),
                                      );
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Transaction added successfully!'),
                                            backgroundColor: Color(0xFF6366F1),
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.only(bottom: 72, left: 16, right: 16),
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
                                            duration: const Duration(milliseconds: 1500),
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Selector<DataProvider, List<ExpenseTransaction>>(
            selector: (_, provider) => provider.transactions,
            builder: (context, transactions, _) {
              if (transactions.isEmpty) {
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
              }
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
                          duration: const Duration(milliseconds: 1500),
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
                                  duration: const Duration(milliseconds: 1500),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Account and category info
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              tx.sourceType == TransactionSourceType.bankAccount
                                                  ? Icons.account_balance_wallet
                                                  : Icons.credit_card,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              tx.accountName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
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
                                  // Amount and date (center)
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            formatIndianAmount(tx.amount),
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
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Edit and Delete icons
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        color: const Color(0xFF6366F1),
                                        tooltip: 'Edit Transaction',
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                        onPressed: () {
                                          final accounts = Provider.of<DataProvider>(context, listen: false).accounts;
                                          _showEditTransactionDialog(context, accounts, tx, index);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        color: Colors.red,
                                        tooltip: 'Delete Transaction',
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                        onPressed: () async {
                                          if (await _confirmDelete(context, 'transaction')) {
                                            if (context.mounted) {
                                              Provider.of<DataProvider>(context, listen: false).deleteTransaction(index);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Text('Transaction deleted'),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                                  duration: const Duration(milliseconds: 1500),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
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
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<DataProvider>(
            builder: (context, provider, _) {
              final bool hasAccounts = provider.accounts.isNotEmpty;
              final bool hasCreditCards = provider.creditCards.isNotEmpty;
              final bool canAddTransaction = hasAccounts || hasCreditCards;
              
              return ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: canAddTransaction ? () => _showAddTransactionDialog(context, provider.accounts) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Modern indigo
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}