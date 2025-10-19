import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/data_provider.dart';

class ReceivableTransactionsPage extends StatelessWidget {
  const ReceivableTransactionsPage({Key? key}) : super(key: key);

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
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);
    
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayStr = weekday[date.weekday - 1];
    String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${(date.year % 100).toString().padLeft(2, '0')}';
    
    // Convert to 12-hour format
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    String timeStr = '$hour:${date.minute.toString().padLeft(2, '0')} $period';
    
    if (txDate == today) {
      return 'Today, $dateStr, $timeStr';
    } else if (txDate == yesterday) {
      return 'Yesterday, $dateStr, $timeStr';
    } else {
      return '$dayStr, $dateStr, $timeStr';
    }
  }

  void _showReceivablePaymentDialog(BuildContext context, ExpenseTransaction tx, int txIndex) {
    final TextEditingController amountController = TextEditingController();
    final double remainingAmount = tx.receivableAmount - tx.receivableAmountPaid;
    
    // Pre-fill with remaining amount but without .00
    amountController.text = remainingAmount.toInt().toString();

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payments,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Record Payment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'From ${tx.accountName}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Amount info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Receivable:',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '₹${tx.receivableAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (tx.receivableAmountPaid > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Already Paid:',
                                style: TextStyle(
                                  color: Colors.green.shade200,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '₹${tx.receivableAmountPaid.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.green.shade200,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining:',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${remainingAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Custom amount input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Input field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter amount',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.currency_rupee,
                                  color: Color(0xFF8B5CF6),
                                  size: 22,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8B5CF6),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Action buttons
                  Column(
                    children: [
                      // Record Payment and Mark as Fully Paid buttons
                      Column(
                        children: [
                          // First row: Record Payment and Fully Paid
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final double? amount = double.tryParse(amountController.text);
                                      if (amount != null && amount > 0 && amount <= remainingAmount) {
                                        final newTotalPaid = tx.receivableAmountPaid + amount;
                                        Provider.of<DataProvider>(context, listen: false)
                                            .updateReceivablePayment(tx.id, newTotalPaid);
                                        Navigator.of(context).pop();
                                        _showPaymentConfirmation(context, amount, false);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Please enter a valid amount between ₹1 and ₹${remainingAmount.toStringAsFixed(2)}'),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.purple,
                                      elevation: 6,
                                      shadowColor: Colors.purple.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.payment,
                                          size: 18,
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Record',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Provider.of<DataProvider>(context, listen: false)
                                          .updateReceivablePayment(tx.id, tx.receivableAmount);
                                      Navigator.of(context).pop();
                                      _showPaymentConfirmation(context, remainingAmount, true);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.purple,
                                      elevation: 6,
                                      shadowColor: Colors.purple.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 18,
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Fully Paid',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Wide Cancel button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            elevation: 6,
                            shadowColor: Colors.purple.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.close,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
        ),
      ),
    );
  }

  void _showPaymentConfirmation(BuildContext context, double amount, bool isFullPayment) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${isFullPayment ? 'Full' : 'Partial'} payment of ₹${amount.toStringAsFixed(2)} received!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: provider.canUndoReceivablePayment
            ? SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () {
                  provider.undoLastReceivablePayment();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment undone'),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receivable Transactions'),
        backgroundColor: const Color(0xFF8B5CF6), // Purple theme for receivables
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
            // Filter only receivable transactions
            final receivableTransactions = provider.transactions
                .where((tx) => tx.isReceivable && tx.receivableAmount > 0)
                .toList();

            // Sort by date (newest first)
            receivableTransactions.sort((a, b) => b.date.compareTo(a.date));

            if (receivableTransactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.purple.shade300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Receivable Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Split bill transactions will appear here',
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
            
            // Calculate totals
            final totalReceivable = receivableTransactions
                .fold<double>(0, (sum, tx) => sum + tx.receivableAmount);
            
            final totalPaid = receivableTransactions
                .fold<double>(0, (sum, tx) => sum + tx.receivableAmountPaid);
                
            final totalPending = receivableTransactions
                .fold<double>(0, (sum, tx) => sum + (tx.receivableAmount - tx.receivableAmountPaid));
                
            
            
            return Column(
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF9333EA)], // Purple gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Receivable',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatIndianAmount(totalReceivable),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
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
                              'Paid',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatIndianAmount(totalPaid),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
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
                              'Pending',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatIndianAmount(totalPending),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Instructions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the receivable card to record payments with custom amounts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Transactions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: receivableTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = receivableTransactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(tx.category).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(tx.category),
                                      size: 20,
                                      color: _getCategoryColor(tx.category),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Transaction details
                                  Expanded(
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
                                            Expanded(
                                              child: Text(
                                                tx.accountName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(tx.date),
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                          softWrap: false,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Amount info
                                  Container(
                                    width: 120,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${tx.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: tx.isReceivablePaid 
                                              ? Colors.green.shade100 
                                              : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: tx.isReceivablePaid 
                                                ? Colors.green.shade300 
                                                : Colors.orange.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              tx.isReceivablePaid ? Icons.check_circle : Icons.schedule,
                                              size: 12,
                                              color: tx.isReceivablePaid 
                                                  ? Colors.green.shade700 
                                                  : Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              tx.isReceivablePaid ? 'PAID' : 'PENDING',
                                              style: TextStyle(
                                                color: tx.isReceivablePaid 
                                                    ? Colors.green.shade700 
                                                    : Colors.orange.shade700,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ],
                              ),
                              
              // Receivable info
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Prevent payment dialog for fully paid transactions
                  if (tx.receivableAmountPaid >= tx.receivableAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('This transaction is already fully paid'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(milliseconds: 2000),
                      ),
                    );
                    return;
                  }
                  _showReceivablePaymentDialog(context, tx, index);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: tx.isReceivablePaid 
                        ? Colors.green.shade50 
                        : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tx.isReceivablePaid 
                          ? Colors.green.shade200 
                          : Colors.purple.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tx.isReceivablePaid ? Icons.check_circle : Icons.people,
                        size: 16,
                        color: tx.isReceivablePaid 
                            ? Colors.green.shade600 
                            : Colors.purple.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tx.isReceivablePaid 
                                        ? 'Received: ₹${tx.receivableAmountPaid.toStringAsFixed(2)}'
                                        : 'Split Bill: ₹${tx.receivableAmount.toStringAsFixed(2)} receivable',
                                    style: TextStyle(
                                      color: tx.isReceivablePaid 
                                          ? Colors.green.shade700 
                                          : Colors.purple.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tx.isReceivablePaid 
                                        ? Colors.green.shade100 
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tx.isReceivablePaid ? 'PAID' : 'PENDING',
                                    style: TextStyle(
                                      color: tx.isReceivablePaid 
                                          ? Colors.green.shade700 
                                          : Colors.orange.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Your actual expense: ₹${(tx.amount - tx.receivableAmount).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!tx.isReceivablePaid && tx.receivableAmountPaid > 0)
                                  Text(
                                    'Partial: ₹${tx.receivableAmountPaid.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.touch_app,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),                              // Note if present
                              if (tx.note.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sticky_note_2_outlined,
                                        size: 14,
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tx.note,
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
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