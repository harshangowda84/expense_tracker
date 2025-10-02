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

class SummaryTab extends StatefulWidget {
  const SummaryTab({super.key});

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String selectedPeriod = 'This Month';
  final List<String> periods = ['This Week', 'This Month', 'Last 3 Months', 'This Year'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<ExpenseTransaction> _getFilteredTransactions(List<ExpenseTransaction> transactions) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (selectedPeriod) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }
    
    return transactions.where((tx) => tx.date.isAfter(startDate) || tx.date.isAtSameMomentAs(startDate)).toList();
  }

  List<ExpenseTransaction> _getPreviousPeriodTransactions(List<ExpenseTransaction> transactions) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    
    switch (selectedPeriod) {
      case 'This Week':
        endDate = now.subtract(Duration(days: now.weekday));
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case 'This Month':
        endDate = DateTime(now.year, now.month, 1);
        startDate = DateTime(now.year, now.month - 1, 1);
        break;
      case 'Last 3 Months':
        endDate = DateTime(now.year, now.month - 2, 1);
        startDate = DateTime(now.year, now.month - 5, 1);
        break;
      case 'This Year':
        endDate = DateTime(now.year, 1, 1);
        startDate = DateTime(now.year - 1, 1, 1);
        break;
      default:
        endDate = DateTime(now.year, now.month, 1);
        startDate = DateTime(now.year, now.month - 1, 1);
    }
    
    return transactions.where((tx) => 
      tx.date.isAfter(startDate) && tx.date.isBefore(endDate)
    ).toList();
  }

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
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 18, // Reduced width for better spacing
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxAmount > 0 ? maxAmount : 100,
                color: Colors.grey.withOpacity(0.08),
              ),
            ),
          ],
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
      ExpenseCategory.food: const Color(0xFFFF6B6B),
      ExpenseCategory.travel: const Color(0xFF4ECDC4),
      ExpenseCategory.bills: const Color(0xFFFFE66D),
      ExpenseCategory.shopping: const Color(0xFF95E1D3),
      ExpenseCategory.entertainment: const Color(0xFFAB83A1),
      ExpenseCategory.office: const Color(0xFF9B59B6), // Purple color for office
      ExpenseCategory.other: const Color(0xFF6C7CE0),
    };

    return categoryTotals.entries.map((e) {
      final percent = total > 0 ? (e.value / total * 100) : 0;
      return PieChartSectionData(
        color: colors[e.key] ?? const Color(0xFF6C7CE0),
        value: e.value,
        title: '${e.key.name.toUpperCase()}\n${percent.toStringAsFixed(1)}%',
        radius: 110,
        titleStyle: TextStyle(fontFamily: 'Inter', 
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            const Shadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
        titlePositionPercentageOffset: 0.65,
      );
    }).toList();
  }

  Widget _buildEnhancedPeriodSelector() {
    // Define icons for each period
    final Map<String, IconData> periodIcons = {
      'This Week': Icons.calendar_view_week_rounded,
      'This Month': Icons.calendar_view_month_rounded,
      'Last 3 Months': Icons.calendar_view_month_outlined,
      'This Year': Icons.calendar_today_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPeriod,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 8,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              selectedItemBuilder: (BuildContext context) {
                return periods.map((String period) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          periodIcons[period] ?? Icons.calendar_today,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        period,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: periods.map((period) {
                final isSelected = period == selectedPeriod;
                return DropdownMenuItem(
                  value: period,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? const Color(0xFF6366F1).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            periodIcons[period] ?? Icons.calendar_today,
                            color: isSelected 
                              ? const Color(0xFF6366F1)
                              : Colors.grey[600],
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                period,
                                style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected 
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                _getPeriodDescription(period),
                                style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 12,
                                  color: isSelected 
                                    ? const Color(0xFF6366F1).withOpacity(0.7)
                                    : Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPeriod = value;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getPeriodDescription(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return '${startOfWeek.day}/${startOfWeek.month} - ${now.day}/${now.month}';
      case 'This Month':
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${monthNames[now.month - 1]} ${now.year}';
      case 'Last 3 Months':
        final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${monthNames[threeMonthsAgo.month - 1]} - ${monthNames[now.month - 1]}';
      case 'This Year':
        return '${now.year}';
      default:
        return '';
    }
  }

  Widget _buildCompactPeriodSelector() {
    // Better period names for compact display
    final Map<String, String> shortPeriodNames = {
      'This Week': 'Week',
      'This Month': 'Month',
      'Last 3 Months': '3 Months',
      'This Year': 'Year',
    };

    final Map<String, IconData> periodIcons = {
      'This Week': Icons.calendar_view_week_rounded,
      'This Month': Icons.calendar_view_month_rounded,
      'Last 3 Months': Icons.calendar_view_month_outlined,
      'This Year': Icons.calendar_today_rounded,
    };

    return Container(
      height: 40, // Increased height
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 180), // Much bigger
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), // Increased padding
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPeriod,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 8,
              isDense: false, // Allow more space
              menuMaxHeight: 250,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 13, // Larger font
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              icon: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              selectedItemBuilder: (BuildContext context) {
                return periods.map((String period) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          periodIcons[period] ?? Icons.calendar_today,
                          color: Colors.white,
                          size: 16, // Larger icon
                        ),
                        const SizedBox(width: 8), // More spacing
                        Text(
                          shortPeriodNames[period] ?? period,
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 13, // Larger font
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              items: periods.map((period) {
                final isSelected = period == selectedPeriod;
                return DropdownMenuItem(
                  value: period,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? const Color(0xFF6366F1).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            periodIcons[period] ?? Icons.calendar_today,
                            color: isSelected 
                              ? const Color(0xFF6366F1)
                              : Colors.grey[600],
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            period,
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: Color(0xFF6366F1),
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPeriod = value;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSummaryCard(String title, String value, String subtitle, IconData icon, Color startColor, Color endColor, {bool showTrend = false, double? trendValue}) {
    return Card(
      elevation: 8,
      shadowColor: startColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: IntrinsicHeight(
        child: Container(
          constraints: const BoxConstraints(minHeight: 200), // Further increased height for 2-line subtitle
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with icon and trend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  // Always reserve space for trend, show it conditionally
                  if (showTrend && trendValue != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trendValue >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trendValue >= 0 ? Icons.trending_up : Icons.trending_down,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${trendValue >= 0 ? '+' : ''}${trendValue.toStringAsFixed(0)}%',
                            style: TextStyle(fontFamily: 'Inter', 
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Content section
              Text(
                title,
                style: TextStyle(fontFamily: 'Inter', 
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle at bottom
              Text(
                subtitle,
                style: TextStyle(fontFamily: 'Inter', 
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2, // Allow 2 lines for longer text
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInsightCard(ExpenseCategory category, double amount, double percentage, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name.toUpperCase(),
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatIndianAmount(amount),
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, data, _) {
        final allTransactions = data.transactions;
        final filteredTransactions = _getFilteredTransactions(allTransactions);
        final accounts = data.accounts;
        final creditCards = data.creditCards;
        
        // Calculate comprehensive analytics
        final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);
        final totalCreditLimit = creditCards.fold(0.0, (sum, cc) => sum + cc.limit);
        final totalCreditUsed = creditCards.fold(0.0, (sum, cc) => sum + (cc.usedAmount ?? 0.0));
        final totalSpent = filteredTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
        final totalTransactions = filteredTransactions.length;
        final avgTransactionAmount = totalTransactions > 0 ? totalSpent / totalTransactions : 0.0;
        
        // Calculate category breakdown
        final Map<ExpenseCategory, double> categoryTotals = {};
        for (var tx in filteredTransactions) {
          categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
        }
        
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // Calculate trend (simplified - comparing with previous period)
        final previousPeriodTransactions = _getPreviousPeriodTransactions(allTransactions);
        final previousSpent = previousPeriodTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
        final spendingTrend = previousSpent > 0 ? ((totalSpent - previousSpent) / previousSpent * 100) : 0.0;
        
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stylish Header with period selector
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF8FAFC),
                          Color(0xFFFFFFFF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.dashboard_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Welcome back!',
                              style: TextStyle(fontFamily: 'Inter', 
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Main title and period selector row
                        Row(
                          children: [
                            Expanded(
                              flex: 3, // Give title most space but not all
                              child: Text(
                                'Financial Dashboard',
                                style: TextStyle(fontFamily: 'Montserrat', 
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16), // More spacing
                            // Compact period selector
                            _buildCompactPeriodSelector(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Main summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernSummaryCard(
                          'Total Balance',
                          formatIndianAmount(totalBalance),
                          'Available in accounts',
                          Icons.account_balance_wallet,
                          const Color(0xFF10B981),
                          const Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModernSummaryCard(
                          'Total Spent',
                          formatIndianAmount(totalSpent),
                          selectedPeriod.toLowerCase(),
                          Icons.trending_down,
                          const Color(0xFFEF4444),
                          const Color(0xFF991B1B),
                          showTrend: true,
                          trendValue: spendingTrend,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Credit summary card
                  _buildModernSummaryCard(
                    'Credit Utilization',
                    totalCreditLimit > 0 ? '${((totalCreditUsed / totalCreditLimit) * 100).toStringAsFixed(1)}%' : '0%',
                    '${formatIndianAmount(totalCreditUsed)} of ${formatIndianAmount(totalCreditLimit)} used',
                    Icons.credit_card,
                    const Color(0xFF8B5CF6),
                    const Color(0xFF5B21B6),
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick stats - responsive layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Determine if we should use 2x2 grid or 1x4 row layout
                      final screenWidth = constraints.maxWidth;
                      final useGridLayout = screenWidth < 600; // Switch to grid on smaller screens
                      
                      if (useGridLayout) {
                        // 2x2 Grid layout for mobile screens
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStatsCard(
                                    'Transactions',
                                    totalTransactions.toString(),
                                    Icons.receipt_long,
                                    const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickStatsCard(
                                    'Avg. Amount',
                                    formatIndianAmount(avgTransactionAmount),
                                    Icons.calculate,
                                    const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStatsCard(
                                    'Accounts',
                                    accounts.length.toString(),
                                    Icons.account_balance,
                                    const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickStatsCard(
                                    'Cards',
                                    creditCards.length.toString(),
                                    Icons.credit_card,
                                    const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Single row layout for larger screens
                        return Row(
                          children: [
                            Expanded(
                              child: _buildQuickStatsCard(
                                'Transactions',
                                totalTransactions.toString(),
                                Icons.receipt_long,
                                const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickStatsCard(
                                'Avg. Amount',
                                formatIndianAmount(avgTransactionAmount),
                                Icons.calculate,
                                const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickStatsCard(
                                'Accounts',
                                accounts.length.toString(),
                                Icons.account_balance,
                                const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickStatsCard(
                                'Cards',
                                creditCards.length.toString(),
                                Icons.credit_card,
                                const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Spending by Category Chart
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.pie_chart,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Spending by Category',
                                style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 320,
                            child: filteredTransactions.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Icons.pie_chart_outline,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No spending data available',
                                          style: TextStyle(fontFamily: 'Inter', 
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'for the selected period',
                                          style: TextStyle(fontFamily: 'Inter', 
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : PieChart(
                                    PieChartData(
                                      sections: _buildCategorySections(filteredTransactions),
                                      centerSpaceRadius: 0,
                                      sectionsSpace: 3,
                                      borderData: FlBorderData(show: false),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Category breakdown
                  if (sortedCategories.isNotEmpty) ...[
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.insights,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Category Insights',
                                  style: TextStyle(fontFamily: 'Inter', 
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ...sortedCategories.take(5).map((entry) {
                              final colors = {
                                ExpenseCategory.food: const Color(0xFFFF6B6B),
                                ExpenseCategory.travel: const Color(0xFF4ECDC4),
                                ExpenseCategory.bills: const Color(0xFFFFE66D),
                                ExpenseCategory.shopping: const Color(0xFF95E1D3),
                                ExpenseCategory.entertainment: const Color(0xFFAB83A1),
                                ExpenseCategory.other: const Color(0xFF6C7CE0),
                              };
                              
                              final percentage = totalSpent > 0 ? (entry.value / totalSpent * 100).toDouble() : 0.0;
                              return _buildCategoryInsightCard(
                                entry.key,
                                entry.value,
                                percentage,
                                colors[entry.key] ?? const Color(0xFF6C7CE0),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Monthly spending chart
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.bar_chart,
                                  color: Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Monthly Spending Trend',
                                  style: TextStyle(fontFamily: 'Inter', 
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return SizedBox(
                                height: 280,
                                width: constraints.maxWidth,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: _buildMonthlyBarData(allTransactions),
                                    gridData: FlGridData(
                                      show: true,
                                      drawHorizontalLine: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 1000,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: Colors.grey.withOpacity(0.2),
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                          final now = DateTime.now();
                                          final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                          
                                          // Calculate which month this bar represents (last 6 months)
                                          final monthDate = DateTime(now.year, now.month - (5 - value.toInt()), 1);
                                          final monthIndex = monthDate.month - 1; // Convert to 0-based index
                                          
                                          if (value.toInt() < 6 && monthIndex >= 0 && monthIndex < 12) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                monthNames[monthIndex],
                                                style: TextStyle(fontFamily: 'Inter', 
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        tooltipBgColor: const Color(0xFF6366F1),
                                        tooltipRoundedRadius: 8,
                                        tooltipPadding: const EdgeInsets.all(8),
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          return BarTooltipItem(
                                            formatIndianAmount(rod.toY),
                                            TextStyle(fontFamily: 'Inter', 
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    maxY: null, // Let the chart auto-scale
                                    alignment: BarChartAlignment.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
