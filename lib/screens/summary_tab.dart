import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import 'package:fl_chart/fl_chart.dart';

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

class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key});

  List<BarChartGroupData> _buildMonthlyBarData(List<ExpenseTransaction> transactions) {
    final now = DateTime.now();
    final Map<String, double> monthTotals = {};
    final List<String> last6Months = [];

    // Get the last 6 months in chronological order
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthTotals[monthKey] = 0.0;
      last6Months.add(monthKey);
    }
    
    // Calculate totals for each month
    for (var tx in transactions) {
      final monthKey = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      if (monthTotals.containsKey(monthKey)) {
        monthTotals[monthKey] = (monthTotals[monthKey] ?? 0) + tx.amount;
      }
    }

    // Find max value for scaling
    final maxAmount = monthTotals.values.fold<double>(0.0, (max, value) => value > max ? value : max);
    
    // Create bar chart data
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < last6Months.length; i++) {
      final monthKey = last6Months[i];
      final amount = monthTotals[monthKey] ?? 0.0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxAmount > 0 ? maxAmount : 100,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return barGroups;
  }

  List<PieChartSectionData> _buildCategorySections(List<ExpenseTransaction> transactions) {
    final Map<ExpenseCategory, double> categoryTotals = {};
    final total = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
    
    // Calculate totals for each category
    for (var tx in transactions) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }
    
    final colors = {
      ExpenseCategory.food: Colors.orange,
      ExpenseCategory.travel: Colors.blue,
      ExpenseCategory.bills: Colors.red,
      ExpenseCategory.shopping: Colors.green,
      ExpenseCategory.entertainment: Colors.purple,
      ExpenseCategory.other: Colors.grey,
    };

    return categoryTotals.entries.map((e) {
      final percent = total > 0 ? (e.value / total * 100) : 0;
      return PieChartSectionData(
        color: colors[e.key] ?? Colors.grey,
        value: e.value,
        title: '${e.key.name}\n${percent.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, data, _) {
        final transactions = data.transactions;
        final accounts = data.accounts;
        
        // Calculate summary data
        final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);
        final totalSpent = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
        
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Balance',
                        formatIndianAmount(totalBalance),
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Spent',
                        formatIndianAmount(totalSpent),
                        Icons.money_off,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spending by Category',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: transactions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.pie_chart_outline,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No transaction data available',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : PieChart(
                                  PieChartData(
                                    sections: _buildCategorySections(transactions),
                                    centerSpaceRadius: 0,
                                    sectionsSpace: 2,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}