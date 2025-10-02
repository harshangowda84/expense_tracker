import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/data_provider.dart';
import 'account_transactions_page.dart';

class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key});

  // Get account transaction statistics
  Map<String, dynamic> _getAccountStats(String accountName, List<ExpenseTransaction> transactions) {
    final accountTransactions = transactions
        .where((tx) => tx.accountName == accountName && tx.sourceType == TransactionSourceType.bankAccount)
        .toList();
    
    final totalSpent = accountTransactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final lastTransaction = accountTransactions.isNotEmpty 
        ? accountTransactions.first.date 
        : null;
    final transactionCount = accountTransactions.length;
    
    // Calculate monthly spending (current month)
    final now = DateTime.now();
    final monthlyTransactions = accountTransactions
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList();
    final monthlySpent = monthlyTransactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    
    return {
      'totalSpent': totalSpent,
      'lastTransaction': lastTransaction,
      'transactionCount': transactionCount,
      'monthlySpent': monthlySpent,
    };
  }

  String _formatIndianAmount(double amount) {
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

  void _showAddAccountDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Modern indigo to purple
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Account',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.close, size: 16),
                          SizedBox(width: 4),
                          Text('Cancel', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                      onPressed: () async {
                      if (nameController.text.isNotEmpty && balanceController.text.isNotEmpty) {
                        await Provider.of<DataProvider>(context, listen: false)
                            .addAccount(Account(
                              name: nameController.text,
                              balance: double.parse(balanceController.text),
                              balanceDate: DateTime.now(),
                            ));
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Account added successfully!'),
                            backgroundColor: Colors.blue,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                            duration: Duration(milliseconds: 1500),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAccountDialog(BuildContext context, Account account, int index) {
    final TextEditingController nameController = TextEditingController(text: account.name);
    final TextEditingController balanceController = TextEditingController(text: account.balance.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // Constrain width
            padding: const EdgeInsets.all(20), // Reduced padding from 32
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Modern indigo to purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Account',
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 22, // Reduced from 24
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20), // Reduced from 24
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                  ),
                ),
                const SizedBox(height: 14), // Reduced from 16
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Balance',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                  ),
                ),
                const SizedBox(height: 20), // Reduced from 24
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.close, size: 18), // Smaller icon
                            SizedBox(width: 6),
                            Text('Cancel', style: TextStyle(fontSize: 14)), // Smaller font
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // Reduced from 16
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                        ),
                        onPressed: () async {
                        if (nameController.text.isNotEmpty && balanceController.text.isNotEmpty) {
                          final originalAccount = account; // Store original for undo
                          final updatedAccount = Account(
                            name: nameController.text,
                            balance: double.parse(balanceController.text),
                            balanceDate: DateTime.now(),
                          );
                          
                          final provider = Provider.of<DataProvider>(context, listen: false);
                          await provider.updateAccount(index, updatedAccount);
                          
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Account updated successfully!'),
                                backgroundColor: Colors.blue,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    // Restore the original account
                                    provider.updateAccount(index, originalAccount);
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save, size: 18), // Smaller icon
                          SizedBox(width: 6),
                          Text('Save', style: TextStyle(fontSize: 14)), // Smaller font
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditBalanceDialog(BuildContext context, Account account) {
    String amount = account.balance.toStringAsFixed(2);
    final controller = TextEditingController(text: amount);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Balance'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Balance'),
          controller: controller,
          onChanged: (v) => amount = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBalance = double.tryParse(amount);
              if (newBalance != null) {
                final provider = Provider.of<DataProvider>(context, listen: false);
                final oldBalance = account.balance;
                await provider.setAccountBalance(account.name, newBalance);
                Navigator.of(dialogContext).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Balance updated!'),
                    backgroundColor: Colors.deepPurple,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'UNDO',
                      textColor: Colors.white,
                      onPressed: () {
                        // Restore the old balance
                        provider.setAccountBalance(account.name, oldBalance);
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String accountName) async {
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
                'Delete Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete $accountName?\nThis will also delete all associated transactions.',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)], // Modern subtle gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Consumer<DataProvider>(
              builder: (context, provider, _) {
                final accounts = provider.accounts;
                final transactions = provider.transactions;
                
                if (accounts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No accounts yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: accounts.length,
                  padding: const EdgeInsets.only(top: 8),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final stats = _getAccountStats(account.name, transactions);
                    
                    return Dismissible(
                      key: Key(account.name),
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
                      confirmDismiss: (_) => _confirmDelete(context, account.name),
                      onDismissed: (_) {
                        final deletedAccount = account;
                        final deletedIndex = index;
                        Provider.of<DataProvider>(context, listen: false).deleteAccount(index);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${account.name} deleted'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'UNDO',
                              textColor: Colors.white,
                              onPressed: () {
                                Provider.of<DataProvider>(context, listen: false).insertAccountAt(deletedIndex, deletedAccount);
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    AccountTransactionsPage(accountName: account.name),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    )),
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Account info
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account.name,
                                            style: TextStyle(fontFamily: 'Inter', 
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Last updated:',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            account.balanceDate.toString().substring(0, 16),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Balance right-aligned
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatIndianAmount(account.balance),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: account.balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), // Green/Red
                                            ),
                                          ),
                                          Text(
                                            'Current Balance',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (stats['lastTransaction'] != null)
                                            Text(
                                              'Last Txn: ${stats['lastTransaction'].toString().substring(0, 10)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Transaction statistics
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              '${stats['transactionCount']}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF6366F1), // Modern indigo
                                              ),
                                            ),
                                            Text(
                                              'Transactions',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.grey.shade300,
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              _formatIndianAmount(stats['totalSpent']),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: stats['totalSpent'] > 0 ? Colors.orange : Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'Total Spent',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.grey.shade300,
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              _formatIndianAmount(stats['monthlySpent']),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: stats['monthlySpent'] > 0 ? Colors.red : Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'This Month',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Action buttons
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Calculate button width based on available space
                                    final buttonWidth = (constraints.maxWidth - 16) / 3; // 3 buttons with 2 gaps of 8px
                                    final useVerticalLayout = buttonWidth < 80; // Switch to vertical if too narrow
                                    
                                    if (useVerticalLayout) {
                                      return Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: () => _showEditAccountDialog(context, account, index),
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Edit'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF6366F1),
                                                side: const BorderSide(color: Color(0xFF6366F1)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showEditBalanceDialog(context, account),
                                              icon: const Icon(Icons.account_balance_wallet, size: 16),
                                              label: const Text('Balance'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                if (await _confirmDelete(context, account.name)) {
                                                  if (context.mounted) {
                                                    final deletedAccount = account;
                                                    final deletedIndex = index;
                                                    Provider.of<DataProvider>(context, listen: false).deleteAccount(index);
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('${account.name} deleted'),
                                                        backgroundColor: const Color(0xFFEF4444),
                                                        behavior: SnackBarBehavior.floating,
                                                        margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                                        duration: const Duration(seconds: 5),
                                                        action: SnackBarAction(
                                                          label: 'UNDO',
                                                          textColor: Colors.white,
                                                          onPressed: () {
                                                            Provider.of<DataProvider>(context, listen: false).insertAccountAt(deletedIndex, deletedAccount);
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.delete_outline, size: 16),
                                              label: const Text('Delete'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFFEF4444),
                                                side: const BorderSide(color: Color(0xFFEF4444)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Row(
                                        children: [
                                          Flexible(
                                            flex: 1,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showEditAccountDialog(context, account, index),
                                                icon: const Icon(Icons.edit, size: 16),
                                                label: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: const Text('Edit'),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF6366F1),
                                                  side: const BorderSide(color: Color(0xFF6366F1)),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            flex: 1,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showEditBalanceDialog(context, account),
                                                icon: const Icon(Icons.account_balance_wallet, size: 16),
                                                label: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: const Text('Balance'),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF10B981),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            flex: 1,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () async {
                                                  if (await _confirmDelete(context, account.name)) {
                                                    if (context.mounted) {
                                                      final deletedAccount = account;
                                                      final deletedIndex = index;
                                                      Provider.of<DataProvider>(context, listen: false).deleteAccount(index);
                                                      
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('${account.name} deleted'),
                                                          backgroundColor: const Color(0xFFEF4444),
                                                          behavior: SnackBarBehavior.floating,
                                                          margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                                          duration: const Duration(seconds: 5),
                                                          action: SnackBarAction(
                                                            label: 'UNDO',
                                                            textColor: Colors.white,
                                                            onPressed: () {
                                                              Provider.of<DataProvider>(context, listen: false).insertAccountAt(deletedIndex, deletedAccount);
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const Icon(Icons.delete_outline, size: 16),
                                                label: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: const Text('Delete'),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFFEF4444),
                                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  },
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
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(
                'Add Account',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showAddAccountDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), // Modern indigo
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
