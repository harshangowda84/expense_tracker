
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/income_transaction.dart';
import '../utils/income_category_utils.dart';
import '../utils/performance_utils.dart';
import '../utils/success_dialog.dart';
import '../utils/error_dialog.dart';
import 'accounts_tab.dart';

// Track expanded transactions by their index
final Set<int> _expandedIncomeIndices = {};

enum DateFilterType {
  all,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  last30Days,
  custom,
}

class IncomeTab extends StatefulWidget {
  const IncomeTab({super.key});

  @override
  State<IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<IncomeTab> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  IncomeCategory? _selectedCategory;
  DateFilterType _selectedDateFilter = DateFilterType.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedSourceFilter;
  final TextEditingController _searchController = TextEditingController();
  AnimationController? _buttonGlowController;

  @override
  void dispose() {
    _searchController.dispose();
    _buttonGlowController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _buttonGlowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  List<IncomeTransaction> _filterTransactions(List<IncomeTransaction> transactions) {
    var filtered = transactions.where((tx) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          tx.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.accountName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.source.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.amount.toString().contains(_searchQuery) ||
          IncomeCategoryUtils.getCategoryName(tx.category).toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Category filter
      final matchesCategory = _selectedCategory == null || tx.category == _selectedCategory;

      // Source filter
      final matchesSource = _selectedSourceFilter == null || 
          _selectedSourceFilter!.isEmpty ||
          tx.source.toLowerCase().contains(_selectedSourceFilter!.toLowerCase());

      // Date filter
      final now = DateTime.now();
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      bool matchesDate = true;

      switch (_selectedDateFilter) {
        case DateFilterType.all:
          matchesDate = true;
          break;
        case DateFilterType.today:
          final today = DateTime(now.year, now.month, now.day);
          matchesDate = txDate.isAtSameMomentAs(today);
          break;
        case DateFilterType.yesterday:
          final yesterday = DateTime(now.year, now.month, now.day - 1);
          matchesDate = txDate.isAtSameMomentAs(yesterday);
          break;
        case DateFilterType.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          matchesDate = txDate.isAfter(startDate.subtract(const Duration(days: 1)));
          break;
        case DateFilterType.thisMonth:
          matchesDate = txDate.year == now.year && txDate.month == now.month;
          break;
        case DateFilterType.last30Days:
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          matchesDate = txDate.isAfter(thirtyDaysAgo.subtract(const Duration(days: 1)));
          break;
        case DateFilterType.custom:
          if (_customStartDate != null && _customEndDate != null) {
            final startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
            final endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
            matchesDate = txDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                         txDate.isBefore(endDate.add(const Duration(days: 1)));
          }
          break;
      }

      return matchesSearch && matchesCategory && matchesSource && matchesDate;
    }).toList();

    // Sort by date (most recent first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Map<String, List<IncomeTransaction>> _groupTransactionsByDate(List<IncomeTransaction> transactions) {
    final Map<String, List<IncomeTransaction>> grouped = {};
    
    for (final transaction in transactions) {
      final date = transaction.date;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      String dateKey;
      final transactionDate = DateTime(date.year, date.month, date.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      
      if (transactionDate.isAtSameMomentAs(todayDate)) {
        dateKey = 'Today';
      } else if (transactionDate.isAtSameMomentAs(yesterdayDate)) {
        dateKey = 'Yesterday';
      } else {
        dateKey = '${date.day}/${date.month}/${(date.year % 100).toString().padLeft(2, '0')}';
      }
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    
    return grouped;
  }

  Widget _buildSearchAndFilters() {
    final hasFilters = _selectedCategory != null || _selectedDateFilter != DateFilterType.all || _selectedSourceFilter != null;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Search bar - takes most of the space
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search income...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.grey[400], size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter button - compact
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: hasFilters
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                    )
                  : null,
              color: hasFilters ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: hasFilters ? Colors.transparent : Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: hasFilters 
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showFilterDialog,
                child: Icon(
                  Icons.tune_rounded,
                  color: hasFilters ? Colors.white : Colors.grey[600],
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedCategory != null || _selectedDateFilter != DateFilterType.all || _selectedSourceFilter != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategory = null;
                              _selectedDateFilter = DateFilterType.all;
                              _selectedSourceFilter = null;
                              _customStartDate = null;
                              _customEndDate = null;
                            });
                            setState(() {
                              _selectedCategory = null;
                              _selectedDateFilter = DateFilterType.all;
                              _selectedSourceFilter = null;
                              _customStartDate = null;
                              _customEndDate = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Clear All', style: TextStyle(fontSize: 14)),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Category Filter Section (Compact Grid)
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 3.2,
                children: [
                  _buildCompactCategoryCard(null, 'All', Icons.grid_view, Colors.grey[600]!, setModalState),
                  ...IncomeCategoryUtils.getAllCategories().map((category) =>
                    _buildCompactCategoryCard(
                      category,
                      IncomeCategoryUtils.getCategoryName(category).toUpperCase(),
                      IncomeCategoryUtils.getCategoryIcon(category),
                      IncomeCategoryUtils.getCategoryColor(category),
                      setModalState,
                    )),
                ],
              ),
              const SizedBox(height: 20),

              // Date Filter
              const Text(
                'Date Range',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCompactDateChip('All', DateFilterType.all, setModalState),
                    const SizedBox(width: 8),
                    _buildCompactDateChip('Today', DateFilterType.today, setModalState),
                    const SizedBox(width: 8),
                    _buildCompactDateChip('Week', DateFilterType.thisWeek, setModalState),
                    const SizedBox(width: 8),
                    _buildCompactDateChip('Month', DateFilterType.thisMonth, setModalState),
                    const SizedBox(width: 8),
                    _buildCompactDateChip('30 Days', DateFilterType.last30Days, setModalState),
                    const SizedBox(width: 8),
                    _buildCompactDateChip('Custom', DateFilterType.custom, setModalState),
                  ],
                ),
              ),
              
              // Custom Date Range Picker
              if (_selectedDateFilter == DateFilterType.custom) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDatePickerButton(
                        'Start',
                        _customStartDate,
                        (date) => setModalState(() => _customStartDate = date),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactDatePickerButton(
                        'End',
                        _customEndDate,
                        (date) => setModalState(() => _customEndDate = date),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Source Filter
              const Text(
                'Source',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<DataProvider>(
                builder: (context, dataProvider, child) {
                  final sources = dataProvider.incomeTransactions
                      .where((tx) => tx.source.isNotEmpty)
                      .map((tx) => tx.source)
                      .toSet()
                      .toList()
                    ..sort();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // All Sources chip
                      _buildSourceFilterChip(
                        'All Sources',
                        Icons.all_inclusive,
                        Colors.grey,
                        setModalState,
                      ),
                      const SizedBox(height: 6),
                      // Individual source chips
                      if (sources.isNotEmpty) 
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: sources.map((source) {
                            return _buildSourceFilterChip(
                              source,
                              Icons.monetization_on,
                              Colors.green,
                              setModalState,
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String itemType) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Delete Income?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // Message
              Text(
                'Are you sure you want to delete this $itemType?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[800],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Delete Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_expandedIncomeIndices.isNotEmpty) {
                setState(() {
                  _expandedIncomeIndices.clear();
                });
              }
            },
            child: Selector<DataProvider, List<IncomeTransaction>>(
              selector: (_, provider) => provider.incomeTransactions,
              builder: (context, allTransactions, _) {
                final filteredTransactions = _filterTransactions(allTransactions);
                
                if (filteredTransactions.isEmpty) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green.shade100,
                                  Colors.teal.shade100,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _searchQuery.isNotEmpty || _selectedCategory != null || _selectedDateFilter != DateFilterType.all
                                  ? Icons.search_off_rounded
                                  : Icons.trending_up_rounded,
                              size: 48,
                              color: Colors.green.shade400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != null || _selectedDateFilter != DateFilterType.all
                                ? 'No matches found'
                                : 'Grow Your Wealth',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty && _selectedCategory == null && _selectedDateFilter == DateFilterType.all && _selectedSourceFilter == null) ...[
                            Text(
                              'Every income matters, track them all',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green.shade50,
                                    Colors.teal.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.wallet_rounded,
                                        color: Colors.green.shade600,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Quick Setup Guide',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Glowing border for Add Account step
                                  // Decide subtitle and tap behavior based on whether accounts exist
                                  Builder(builder: (context) {
                                    final bool hasAccounts = Provider.of<DataProvider>(context, listen: false).accounts.isNotEmpty;
                                    return AnimatedBuilder(
                                      animation: _buttonGlowController ?? AnimationController(vsync: this, duration: Duration.zero),
                                      builder: (context, child) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.greenAccent.withOpacity(0.5 + ((_buttonGlowController?.value ?? 0) * 0.3)),
                                                blurRadius: 20 + ((_buttonGlowController?.value ?? 0) * 16),
                                                spreadRadius: 2 + ((_buttonGlowController?.value ?? 0) * 2),
                                              ),
                                            ],
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              if (hasAccounts) {
                                                _showAddIncomeDialog();
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => const AccountsTab()),
                                                );
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(60),
                                            child: _buildIncomeStep(
                                              '1',
                                              'Add Account',
                                              hasAccounts ? 'Add your first income' : 'Tap here to add account',
                                              Icons.account_balance_wallet_rounded,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  _buildIncomeStep('2', 'Record Income', 'Use + button below to add', Icons.add_circle_rounded),
                                ],
                              ),
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Try adjusting your filters',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = null;
                                  _selectedDateFilter = DateFilterType.all;
                                  _selectedSourceFilter = null;
                                  _customStartDate = null;
                                  _customEndDate = null;
                                });
                              },
                              icon: const Icon(Icons.clear_all_rounded, size: 18),
                              label: const Text('Clear Filters'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                        ),
                      ),
                    ),
                  );
                }

                final groupedTransactions = _groupTransactionsByDate(filteredTransactions);
                
                return PerformanceUtils.createOptimizedListView(
                  itemCount: groupedTransactions.length,
                  padding: const EdgeInsets.only(top: 0, bottom: 80),
                  itemBuilder: (context, index) {
                    final dateKey = groupedTransactions.keys.elementAt(index);
                    final dayTransactions = groupedTransactions[dateKey]!;
                    final dayTotal = dayTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateKey,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              Text(
                                '+₹${dayTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Income transactions for this date
                        ...dayTransactions.asMap().entries.map((entry) {
                          final txIndex = allTransactions.indexOf(entry.value);
                          final tx = entry.value;
                          final isExpanded = _expandedIncomeIndices.contains(txIndex);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedIncomeIndices.remove(txIndex);
                                } else {
                                  _expandedIncomeIndices.clear();
                                  _expandedIncomeIndices.add(txIndex);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOutCubic,
                                alignment: Alignment.topCenter,
                                clipBehavior: Clip.hardEdge,
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
                                            color: IncomeCategoryUtils.getCategoryColor(tx.category).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            IncomeCategoryUtils.getCategoryIcon(tx.category),
                                            size: 20,
                                            color: IncomeCategoryUtils.getCategoryColor(tx.category),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Account and category info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.account_balance_wallet,
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
                                                IncomeCategoryUtils.getCategoryName(tx.category),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      _formatIncomeDate(tx.date),
                                                      style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 12,
                                                      ),
                                                      softWrap: false,
                                                      overflow: TextOverflow.visible,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (tx.source.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.business,
                                                      size: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        tx.source,
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // Amount
                                        Text(
                                          '+₹${tx.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tx.note.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.blue.shade100,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.sticky_note_2_outlined,
                                              size: 16,
                                              color: Colors.blue.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                tx.note,
                                                style: TextStyle(
                                                  fontStyle: FontStyle.normal,
                                                  color: Colors.grey[800],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    if (isExpanded) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(14),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF10B981).withOpacity(0.18),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.edit, size: 18),
                                                  label: const Text('Edit'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  ),
                                                  onPressed: () => _editIncomeTransaction(context, tx, txIndex),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  borderRadius: BorderRadius.circular(14),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.redAccent.withOpacity(0.16),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.delete, size: 18),
                                                  label: const Text('Delete'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.transparent,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  ),
                                                  onPressed: () async {
                                                    if (await _confirmDelete(context, 'income')) {
                                                      if (context.mounted) {
                                                        Provider.of<DataProvider>(context, listen: false).deleteIncomeTransaction(txIndex);
                                                        SuccessDialog.show(context, message: 'Income deleted successfully!');
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        Consumer<DataProvider>(
          builder: (context, provider, _) {
            final hasAccounts = provider.accounts.isNotEmpty;
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade300.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (hasAccounts) {
                        _showAddIncomeDialog();
                      } else {
                        _showRequireAccountDialog(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.teal.shade400],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Add Income',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Helper _formatTime removed: no longer used in the UI (kept formatting in _formatIncomeDate)

  String _formatIncomeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final txDate = DateTime(date.year, date.month, date.day);
  final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String dayStr = weekday[date.weekday - 1];
  String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${(date.year % 100).toString().padLeft(2, '0')}';
  int hour = date.hour;
  String period = hour >= 12 ? 'PM' : 'AM';
  if (hour == 0) hour = 12;
  if (hour > 12) hour -= 12;
  String timeStr = '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  if (txDate == today) {
    return 'Today, $dateStr, $timeStr';
  } else if (txDate == yesterday) {
    return 'Yesterday, $dateStr, $timeStr';
  } else {
    return '$dayStr, $dateStr, $timeStr';
  }
}

  String _getFilterDisplayText() {
    List<String> parts = [];
    
    if (_selectedCategory != null) {
      parts.add(IncomeCategoryUtils.getCategoryName(_selectedCategory!).toUpperCase());
    }
    
    if (_selectedSourceFilter != null) {
      parts.add(_selectedSourceFilter!.toUpperCase());
    }
    
    if (_selectedDateFilter != DateFilterType.all) {
      switch (_selectedDateFilter) {
        case DateFilterType.today:
          parts.add('TODAY');
          break;
        case DateFilterType.yesterday:
          parts.add('YESTERDAY');
          break;
        case DateFilterType.thisWeek:
          parts.add('THIS WEEK');
          break;
        case DateFilterType.thisMonth:
          parts.add('THIS MONTH');
          break;
        case DateFilterType.last30Days:
          parts.add('LAST 30 DAYS');
          break;
        case DateFilterType.custom:
          parts.add('CUSTOM');
          break;
        case DateFilterType.all:
          break;
      }
    }
    
    return parts.join(' • ');
  }

  void _editIncomeTransaction(BuildContext context, IncomeTransaction transaction, int index) {
    final amountController = TextEditingController(text: transaction.amount.toStringAsFixed(2));
    final noteController = TextEditingController(text: transaction.note);
    final sourceController = TextEditingController(text: transaction.source);
    IncomeCategory selectedCategory = transaction.category;
    String? selectedAccount = transaction.accountName;
    DateTime selectedDate = transaction.date;
    bool hasEdits = false;
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
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with gradient title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: const Text(
                                  'Edit Income',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[100],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.close, color: Colors.grey[600], size: 24),
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  tooltip: 'Close',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Amount TextField with enhanced styling
                              const SizedBox(height: 8),
                              const Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: amountController,
                                  decoration: InputDecoration(
                                    prefixText: '₹ ',
                                    prefixStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    hintText: '0.00',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) {
                                    if (value != transaction.amount.toStringAsFixed(2)) {
                                      setState(() => hasEdits = true);
                                    }
                                  },
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Category Selection
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<IncomeCategory>(
                                  value: selectedCategory,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  items: IncomeCategoryUtils.getAllCategories().map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Row(
                                        children: [
                                          Icon(
                                            IncomeCategoryUtils.getCategoryIcon(category),
                                            size: 18,
                                            color: IncomeCategoryUtils.getCategoryColor(category),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(IncomeCategoryUtils.getCategoryName(category)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != transaction.category) {
                                      setState(() => hasEdits = true);
                                    }
                                    setState(() => selectedCategory = value!);
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Account Selection
                              const Text(
                                'Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Consumer<DataProvider>(
                                  builder: (context, dataProvider, child) {
                                    return DropdownButtonFormField<String>(
                                      value: selectedAccount,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      items: dataProvider.accounts.map((account) {
                                        return DropdownMenuItem(
                                          value: account.name,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.account_balance_wallet,
                                                size: 18,
                                                color: Colors.orange[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text('${account.name} (₹${account.balance.toStringAsFixed(0)})'),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedAccount = value;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Source
                              const Text(
                                'Source (Optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: sourceController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., Company Name, Client',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Note
                              const Text(
                                'Note (Optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: noteController,
                                  decoration: InputDecoration(
                                    hintText: 'Add any notes...',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Date Picker
                              const Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey[300]!),
                                  color: Colors.white,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              
                              // Cancel and Save Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: hasEdits
                                          ? const LinearGradient(
                                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : LinearGradient(
                                              colors: [Colors.grey[400]!, Colors.grey[400]!],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: hasEdits
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withOpacity(0.25),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: (!hasEdits || isSubmitting) ? null : () async {
                                        final amount = double.tryParse(amountController.text);
                                        if (amount == null || amount <= 0) {
                                          if (context.mounted) {
                                            ErrorDialog.show(context, message: 'Please enter a valid amount');
                                          }
                                          return;
                                        }
                                        
                                        if (selectedAccount == null) {
                                          if (context.mounted) {
                                            ErrorDialog.show(context, message: 'Please select an account');
                                          }
                                          return;
                                        }
                                        
                                        final updatedTransaction = IncomeTransaction(
                                          id: transaction.id,
                                          amount: amount,
                                          category: selectedCategory,
                                          accountName: selectedAccount!,
                                          source: sourceController.text.trim(),
                                          note: noteController.text.trim(),
                                          date: selectedDate,
                                        );
                                        
                                        if (context.mounted) {
                                          Provider.of<DataProvider>(context, listen: false).updateIncomeTransaction(
                                            index, 
                                            updatedTransaction, 
                                            transaction.amount, 
                                            transaction.accountName
                                          );
                                          Navigator.of(dialogContext).pop();
                                          SuccessDialog.show(context, message: 'Income updated successfully!');
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.save, size: 18, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'Save',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
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

  void _showAddIncomeDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final sourceController = TextEditingController();
    IncomeCategory selectedCategory = IncomeCategory.salary;
    final accounts = Provider.of<DataProvider>(context, listen: false).accounts;
    String? selectedAccount = accounts.isNotEmpty ? accounts.first.name : null;
    DateTime selectedDate = DateTime.now();
    String? amountError;

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
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with gradient title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: const Text(
                                  'Add Income',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[100],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.close, color: Colors.grey[600], size: 24),
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  tooltip: 'Close',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Amount TextField with enhanced styling
                              const SizedBox(height: 8),
                              const Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: amountController,
                                  decoration: InputDecoration(
                                    prefixText: '₹ ',
                                    prefixStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    hintText: '0.00',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: amountError != null ? Colors.red : Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: amountError != null ? Colors.red : Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: amountError != null ? Colors.red : const Color(0xFF10B981),
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    errorText: amountError,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.isEmpty) {
                                        amountError = 'Amount is required';
                                      } else if (double.tryParse(value) == null) {
                                        amountError = 'Enter a valid amount (numbers and decimal only)';
                                      } else if (double.parse(value) <= 0) {
                                        amountError = 'Amount must be greater than 0';
                                      } else {
                                        amountError = null;
                                      }
                                    });
                                  },
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Category Selection
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<IncomeCategory>(
                                  value: selectedCategory,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  items: IncomeCategoryUtils.getAllCategories().map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Row(
                                        children: [
                                          Icon(
                                            IncomeCategoryUtils.getCategoryIcon(category),
                                            size: 18,
                                            color: IncomeCategoryUtils.getCategoryColor(category),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(IncomeCategoryUtils.getCategoryName(category)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Account Selection
                              const Text(
                                'Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Consumer<DataProvider>(
                                  builder: (context, dataProvider, child) {
                                    return DropdownButtonFormField<String>(
                                      value: selectedAccount,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      items: dataProvider.accounts.map((account) {
                                        return DropdownMenuItem(
                                          value: account.name,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.account_balance_wallet,
                                                size: 18,
                                                color: Colors.orange[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text('${account.name} (₹${account.balance.toStringAsFixed(0)})'),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedAccount = value;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Source
                              const Text(
                                'Source (Optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: sourceController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., Company Name, Client',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Note
                              const Text(
                                'Note (Optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: noteController,
                                  decoration: InputDecoration(
                                    hintText: 'Add any notes...',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Date Picker
                              const Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey[300]!),
                                  color: Colors.white,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              
                              // Action buttons - Cancel and Add
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Cancel Button
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.grey[600],
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Add Button
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withOpacity(0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          // Validate amount
                                          if (amountController.text.isEmpty) {
                                            if (context.mounted) {
                                              ErrorDialog.show(context, message: 'Amount is required');
                                            }
                                            return;
                                          }

                                          if (amountError != null) {
                                            if (context.mounted) {
                                              ErrorDialog.show(context, message: amountError!);
                                            }
                                            return;
                                          }
                                          
                                          if (selectedAccount == null) {
                                            if (context.mounted) {
                                              ErrorDialog.show(context, message: 'Please select an account');
                                            }
                                            return;
                                          }

                                          final amount = double.tryParse(amountController.text);
                                          if (amount == null || amount <= 0) {
                                            if (context.mounted) {
                                              ErrorDialog.show(context, message: 'Please enter a valid amount');
                                            }
                                            return;
                                          }

                                          final income = IncomeTransaction(
                                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                                            accountName: selectedAccount!,
                                            amount: amount,
                                            date: selectedDate,
                                            category: selectedCategory,
                                            note: noteController.text,
                                            source: sourceController.text,
                                          );

                                          try {
                                            await Provider.of<DataProvider>(context, listen: false)
                                                .addIncomeTransaction(income);
                                            
                                            if (context.mounted) {
                                              Navigator.of(dialogContext).pop();
                                              SuccessDialog.show(context, message: 'Income added successfully!');
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ErrorDialog.show(context, message: 'Error: $e');
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: const Text(
                                          'Add Income',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildCompactDateChip(String label, DateFilterType filterType, StateSetter setModalState) {
    final isSelected = _selectedDateFilter == filterType;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setModalState(() {
            _selectedDateFilter = filterType;
            if (filterType != DateFilterType.custom) {
              _customStartDate = null;
              _customEndDate = null;
            }
          });
          setState(() {
            _selectedDateFilter = filterType;
            if (filterType != DateFilterType.custom) {
              _customStartDate = null;
              _customEndDate = null;
            }
          });
        },
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDatePickerButton(String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onDateSelected(date);
              setState(() {});
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? '${selectedDate.day}/${selectedDate.month}'
                            : 'Select',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: selectedDate != null ? Colors.black87 : Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceFilterChip(String sourceName, IconData icon, MaterialColor color, StateSetter setModalState) {
    final isSelected = _selectedSourceFilter == sourceName || (sourceName == 'All Sources' && _selectedSourceFilter == null);
    return InkWell(
      onTap: () {
        setModalState(() {
          _selectedSourceFilter = (sourceName == 'All Sources') ? null : (isSelected ? null : sourceName);
        });
        setState(() {
          _selectedSourceFilter = (sourceName == 'All Sources') ? null : (isSelected ? null : sourceName);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.shade100 : color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.shade400 : color.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color.shade700 : color.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              sourceName,
              style: TextStyle(
                color: isSelected ? color.shade700 : color.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 12,
                color: color.shade700,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCategoryCard(IncomeCategory? category, String label, IconData icon, Color color, StateSetter setModalState) {
    final isSelected = _selectedCategory == category;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setModalState(() => _selectedCategory = category);
            setState(() => _selectedCategory = category);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(height: 1),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 8,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeStep(String number, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.teal.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.green.shade300, size: 24),
        ],
      ),
    );
  }

  void _showRequireAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please add an account first to track your income.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountsTab()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
}