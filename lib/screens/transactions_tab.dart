import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/credit_card.dart';
import '../providers/data_provider.dart';
import '../utils/performance_utils.dart';

enum DateFilterType {
  all,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  last30Days,
  custom,
}

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  String _searchQuery = '';
  ExpenseCategory? _selectedCategory;
  DateFilterType _selectedDateFilter = DateFilterType.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedSourceFilter;
  String? _selectedReceivableFilter; // null = all, 'receivable' = only receivable, 'non-receivable' = only non-receivable
  bool _showActualExpense = true; // Toggle for showing "Your actual expense" feature
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpenseTransaction> _filterTransactions(List<ExpenseTransaction> transactions) {
    var filtered = transactions.where((tx) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          tx.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.accountName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.amount.toString().contains(_searchQuery) ||
          tx.category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Category filter
      final matchesCategory = _selectedCategory == null || tx.category == _selectedCategory;
      
      // Date filter
      final matchesDate = _matchesDateFilter(tx.date);
      
      // Source filter (specific account or card)
      final matchesSource = _selectedSourceFilter == null || tx.accountName == _selectedSourceFilter;
      
      // Receivable filter
      final matchesReceivable = _selectedReceivableFilter == null || 
          (_selectedReceivableFilter == 'receivable' && tx.isReceivable && tx.receivableAmount > 0) ||
          (_selectedReceivableFilter == 'non-receivable' && (!tx.isReceivable || tx.receivableAmount <= 0));
      
      return matchesSearch && matchesCategory && matchesDate && matchesSource && matchesReceivable;
    }).toList();
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  bool _matchesDateFilter(DateTime transactionDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final last30Days = today.subtract(const Duration(days: 30));
    
    final txDate = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
    
    switch (_selectedDateFilter) {
      case DateFilterType.all:
        return true;
      case DateFilterType.today:
        return txDate.isAtSameMomentAs(today);
      case DateFilterType.yesterday:
        return txDate.isAtSameMomentAs(yesterday);
      case DateFilterType.thisWeek:
        return txDate.isAfter(weekStart.subtract(const Duration(days: 1))) && txDate.isBefore(today.add(const Duration(days: 1)));
      case DateFilterType.thisMonth:
        return txDate.isAfter(monthStart.subtract(const Duration(days: 1))) && txDate.isBefore(today.add(const Duration(days: 1)));
      case DateFilterType.last30Days:
        return txDate.isAfter(last30Days.subtract(const Duration(days: 1))) && txDate.isBefore(today.add(const Duration(days: 1)));
      case DateFilterType.custom:
        if (_customStartDate == null || _customEndDate == null) return true;
        final startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
        final endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day);
        return txDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
               txDate.isBefore(endDate.add(const Duration(days: 1)));
    }
  }

  Map<String, List<ExpenseTransaction>> _groupTransactionsByDate(List<ExpenseTransaction> transactions) {
    final Map<String, List<ExpenseTransaction>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    for (var tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String dateKey;
      if (txDate == today) {
        dateKey = 'Today';
      } else if (txDate == yesterday) {
        dateKey = 'Yesterday';
      } else {
        final difference = today.difference(txDate).inDays;
        if (difference < 7) {
          dateKey = '${difference} days ago';
        } else {
          dateKey = '${tx.date.day}/${tx.date.month}/${(tx.date.year % 100).toString().padLeft(2, '0')}';
        }
      }
      grouped[dateKey] ??= [];
      grouped[dateKey]!.add(tx);
    }
    return grouped;
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by amount, account, note, or category...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Button
          Container(
            decoration: BoxDecoration(
              color: (_selectedCategory != null || _selectedDateFilter != DateFilterType.all || _selectedSourceFilter != null) 
                  ? const Color(0xFF6366F1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_selectedCategory != null || _selectedDateFilter != DateFilterType.all || _selectedSourceFilter != null) 
                    ? const Color(0xFF6366F1) : Colors.grey[300]!,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showFilterModal,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: (_selectedCategory != null || _selectedDateFilter != DateFilterType.all || _selectedSourceFilter != null) 
                            ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      if (_selectedCategory != null || _selectedDateFilter != DateFilterType.all || _selectedSourceFilter != null) ...[
                        if (_selectedCategory != null) ...[
                          Icon(
                            _getCategoryIcon(_selectedCategory!),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (_selectedDateFilter != DateFilterType.all) ...[
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _getFilterDisplayText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedCategory != null || _selectedDateFilter != DateFilterType.all || _selectedSourceFilter != null || _selectedReceivableFilter != null)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCategory = null;
                                _selectedDateFilter = DateFilterType.all;
                                _selectedSourceFilter = null;
                                _selectedReceivableFilter = null;
                                _customStartDate = null;
                                _customEndDate = null;
                              });
                              setState(() {
                                _selectedCategory = null;
                                _selectedDateFilter = DateFilterType.all;
                                _selectedSourceFilter = null;
                                _selectedReceivableFilter = null;
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
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Preset Filters
                      const Text(
                        'Quick Presets',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildPresetChip('Today\'s Food', ExpenseCategory.food, DateFilterType.today, setModalState),
                          _buildPresetChip('This Week\'s Bills', ExpenseCategory.bills, DateFilterType.thisWeek, setModalState),
                          _buildPresetChip('Monthly Shopping', ExpenseCategory.shopping, DateFilterType.thisMonth, setModalState),
                          _buildPresetChip('Recent Travel', ExpenseCategory.travel, DateFilterType.last30Days, setModalState),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quick Date Filters (Horizontal)
                      const Text(
                        'Date Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
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
                      
                      const SizedBox(height: 16),
                      
                      // Amount Range Filter Section
                      const Text(
                        'Amount Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: const Text(
                                      '₹0 - ₹100',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: const Text(
                                      '₹100 - ₹500',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: const Text(
                                      '₹500+',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Source Filter Section
                      const Text(
                        'Source Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<DataProvider>(
                        builder: (context, provider, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bank Accounts Section
                              if (provider.accounts.isNotEmpty) ...[
                                const Text(
                                  'Bank Accounts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: provider.accounts.map((account) {
                                    return _buildSourceFilterChip(
                                      account.name,
                                      Icons.account_balance_wallet,
                                      Colors.orange,
                                      setModalState,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              // Credit Cards Section
                              if (provider.creditCards.isNotEmpty) ...[
                                const Text(
                                  'Credit Cards',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: provider.creditCards.map((card) {
                                    return _buildSourceFilterChip(
                                      card.name,
                                      Icons.credit_card,
                                      Colors.purple,
                                      setModalState,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
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
                          _buildCompactCategoryCard(null, 'All', Icons.grid_view, Colors.grey[600]!),
                          ...ExpenseCategory.values.map((category) =>
                            _buildCompactCategoryCard(
                              category,
                              category.name.toUpperCase(),
                              _getCategoryIcon(category),
                              _getCategoryColor(category),
                            )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Receivable Filter Section
                      const Text(
                        'Split Bill / Receivable',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildReceivableFilterChip('All', null, setModalState),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildReceivableFilterChip('Receivable', 'receivable', setModalState),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildReceivableFilterChip('Regular', 'non-receivable', setModalState),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFilterDisplayText() {
    List<String> parts = [];
    
    if (_selectedCategory != null) {
      parts.add(_selectedCategory!.name.toUpperCase());
    }
    
    if (_selectedSourceFilter != null) {
      parts.add(_selectedSourceFilter!.toUpperCase());
    }
    
    if (_selectedReceivableFilter != null) {
      if (_selectedReceivableFilter == 'receivable') {
        parts.add('RECEIVABLE');
      } else if (_selectedReceivableFilter == 'non-receivable') {
        parts.add('REGULAR');
      }
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

  Widget _buildDateFilterChip(String label, DateFilterType filterType, StateSetter setModalState) {
    final isSelected = _selectedDateFilter == filterType;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200]!,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerButton(String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      selectedDate != null
                          ? '${selectedDate.day}/${selectedDate.month}/${(selectedDate.year % 100).toString().padLeft(2, '0')}'
                          : 'Select Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selectedDate != null ? Colors.black : Colors.grey[500],
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

  Widget _buildFilterCategoryCard(ExpenseCategory? category, String label, IconData icon, Color color) {
    final isSelected = _selectedCategory == category;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200]!,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _selectedCategory = category);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceFilterChip(String sourceName, IconData icon, MaterialColor color, StateSetter setModalState) {
    final isSelected = _selectedSourceFilter == sourceName;
    return InkWell(
      onTap: () {
        setModalState(() {
          _selectedSourceFilter = isSelected ? null : sourceName;
        });
        setState(() {
          _selectedSourceFilter = isSelected ? null : sourceName;
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

  Widget _buildPresetChip(String label, ExpenseCategory category, DateFilterType dateFilter, StateSetter setModalState) {
    final isSelected = _selectedCategory == category && _selectedDateFilter == dateFilter;
    return InkWell(
      onTap: () {
        setModalState(() {
          _selectedCategory = category;
          _selectedDateFilter = dateFilter;
          _customStartDate = null;
          _customEndDate = null;
        });
        setState(() {
          _selectedCategory = category;
          _selectedDateFilter = dateFilter;
          _customStartDate = null;
          _customEndDate = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 14,
              color: isSelected ? Colors.white : _getCategoryColor(category),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildCompactCategoryCard(ExpenseCategory? category, String label, IconData icon, Color color) {
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
            setState(() => _selectedCategory = category);
            Navigator.pop(context);
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

  Widget _buildReceivableFilterChip(String label, String? value, StateSetter setModalState) {
    final isSelected = _selectedReceivableFilter == value;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedReceivableFilter = value;
        });
      },
      child: Container(
        height: 40, // Fixed height for consistent alignment
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value == 'receivable' ? Icons.people : 
              value == 'non-receivable' ? Icons.person :
              Icons.all_inclusive,
              size: 16, // Slightly larger icon for better visibility
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Flexible( // Changed from Expanded to Flexible
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
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
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);
    
    // 12-hour format
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayStr = weekday[date.weekday - 1];
    String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${(date.year % 100).toString().padLeft(2, '0')}';
    String timeStr = '${hour}:${date.minute.toString().padLeft(2, '0')} $period';
    
    if (txDate == today) {
      return 'Today, $dateStr, $timeStr';
    } else if (txDate == yesterday) {
      return 'Yesterday, $dateStr, $timeStr';
    } else {
      return '$dayStr, $dateStr, $timeStr';
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
    String? receivableAmountError;
    bool isSubmitting = false;
    bool isReceivable = tx.isReceivable;
    String receivableAmount = tx.receivableAmount > 0 ? tx.receivableAmount.toString() : '';
    TransactionSourceType sourceType = tx.sourceType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        // Create controllers inside the builder so they're tied to the dialog lifecycle
        final amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
        final noteController = TextEditingController(text: tx.note);
        final receivableAmountController = TextEditingController(text: receivableAmount);
        
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
                                  style: TextStyle(fontFamily: 'Inter', 
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
                            const SizedBox(height: 18),
                            // Receivable Section
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.people, color: const Color(0xFF8B5CF6), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Split Bill / Receivable',
                                          style: TextStyle(
                                            color: const Color(0xFF8B5CF6),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      // Toggle for showing actual expense
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Show actual',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Switch(
                                            value: _showActualExpense,
                                            onChanged: (value) {
                                              setState(() {
                                                _showActualExpense = value;
                                              });
                                            },
                                            activeColor: const Color(0xFF8B5CF6),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isReceivable,
                                        onChanged: tx.receivableAmountPaid > 0 ? null : (value) {
                                          setState(() {
                                            isReceivable = value ?? false;
                                            if (!isReceivable) {
                                              receivableAmount = '';
                                              receivableAmountError = null;
                                            }
                                          });
                                        },
                                        activeColor: const Color(0xFF8B5CF6),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Split bill',
                                          style: TextStyle(
                                            color: tx.receivableAmountPaid > 0 ? Colors.grey[400] : Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isReceivable) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      enabled: tx.receivableAmountPaid == 0,
                                      decoration: InputDecoration(
                                        labelText: tx.receivableAmountPaid > 0 
                                            ? 'Receivable Amount (Locked - Payments Made)'
                                            : 'Receivable Amount',
                                        prefixIcon: Icon(
                                          Icons.currency_rupee, 
                                          color: tx.receivableAmountPaid > 0 
                                              ? Colors.grey[400] 
                                              : const Color(0xFF8B5CF6)
                                        ),
                                        errorText: receivableAmountError,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: tx.receivableAmountPaid > 0 ? Colors.grey[100] : Colors.white,
                                        hintText: tx.receivableAmountPaid > 0 
                                            ? 'Cannot edit - payments already received'
                                            : 'Amount friends will pay back',
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      controller: receivableAmountController,
                                      onChanged: tx.receivableAmountPaid > 0 ? null : (v) {
                                        setState(() {
                                          receivableAmount = v;
                                          receivableAmountError = null;
                                          if (receivableAmount.isNotEmpty) {
                                            final receivableVal = double.tryParse(receivableAmount);
                                            final totalAmount = double.tryParse(amountController.text);
                                            if (receivableVal == null || receivableVal <= 0) {
                                              receivableAmountError = 'Enter a valid receivable amount';
                                            } else if (totalAmount != null && receivableVal >= totalAmount) {
                                              receivableAmountError = 'Receivable amount must be less than total amount';
                                            }
                                          }
                                        });
                                      },
                                      style: TextStyle(
                                        color: tx.receivableAmountPaid > 0 ? Colors.grey[500] : Colors.black87, 
                                        fontSize: 16
                                      ),
                                    ),
                                    // Payment status indicator
                                    if (tx.receivableAmountPaid > 0) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: tx.receivableAmountPaid >= tx.receivableAmount 
                                              ? Colors.green.shade50 
                                              : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: tx.receivableAmountPaid >= tx.receivableAmount 
                                                ? Colors.green.shade200 
                                                : Colors.blue.shade200
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              tx.receivableAmountPaid >= tx.receivableAmount 
                                                  ? Icons.check_circle_outline 
                                                  : Icons.payments_outlined, 
                                              color: tx.receivableAmountPaid >= tx.receivableAmount 
                                                  ? Colors.green.shade600 
                                                  : Colors.blue.shade600, 
                                              size: 16
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                tx.receivableAmountPaid >= tx.receivableAmount 
                                                    ? 'Fully Paid: ₹${tx.receivableAmountPaid.toStringAsFixed(2)}'
                                                    : 'Partially Paid: ₹${tx.receivableAmountPaid.toStringAsFixed(2)} of ₹${tx.receivableAmount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: tx.receivableAmountPaid >= tx.receivableAmount 
                                                      ? Colors.green.shade700 
                                                      : Colors.blue.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_showActualExpense && amountController.text.isNotEmpty && receivableAmount.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.green.shade600, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Your actual expense: ₹${(double.tryParse(amountController.text) ?? 0) - (double.tryParse(receivableAmount) ?? 0)}',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
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
                                ],
                              ),
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
                                  onPressed: (accountName.isEmpty || amountError != null || amountController.text.isEmpty || isSubmitting ||
                                      (isReceivable && (receivableAmountError != null || receivableAmount.isEmpty)))
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
                                              isReceivable: isReceivable,
                                              receivableAmount: isReceivable ? double.parse(receivableAmount) : 0.0,
                                              receivableAmountPaid: tx.receivableAmountPaid, // Preserve existing paid amount
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
                                        _showPaymentConfirmationInTransactions(context, amount, false);
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
                                      _showPaymentConfirmationInTransactions(context, remainingAmount, true);
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

  void _showPaymentConfirmationInTransactions(BuildContext context, double amount, bool isFullPayment) {
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
                '${isFullPayment ? 'Marked as fully paid' : 'Payment of ₹${amount.toStringAsFixed(2)} recorded'}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
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
                      margin: EdgeInsets.only(bottom: 72, left: 16, right: 16),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, List<Account> accounts) {
    String accountName = accounts.isNotEmpty ? accounts[0].name : '';
    String amount = '';
    ExpenseCategory category = ExpenseCategory.office;
    String note = '';
    String? amountError;
    String? receivableAmountError;
    bool isSubmitting = false;
    bool isReceivable = false;
    String receivableAmount = '';
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
                            style: TextStyle(fontFamily: 'Inter', 
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
                      const SizedBox(height: 18),
                      // Receivable Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: const Color(0xFF8B5CF6), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Split Bill / Receivable',
                                    style: TextStyle(
                                      color: const Color(0xFF8B5CF6),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Toggle for showing actual expense
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Show actual',
                                      style: TextStyle(
                                        color: () {
                                          // Check if receivable amount equals total amount
                                          if (isReceivable && receivableAmount.isNotEmpty && amount.isNotEmpty) {
                                            final receivableVal = double.tryParse(receivableAmount);
                                            final totalAmount = double.tryParse(amount);
                                            if (receivableVal != null && totalAmount != null && receivableVal >= totalAmount) {
                                              return Colors.grey[400]; // Grey out when full payment
                                            }
                                          }
                                          return Colors.grey[600];
                                        }(),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Switch(
                                      value: _showActualExpense,
                                      onChanged: () {
                                        // Check if receivable amount equals total amount
                                        if (isReceivable && receivableAmount.isNotEmpty && amount.isNotEmpty) {
                                          final receivableVal = double.tryParse(receivableAmount);
                                          final totalAmount = double.tryParse(amount);
                                          if (receivableVal != null && totalAmount != null && receivableVal >= totalAmount) {
                                            return null; // Disable when full payment
                                          }
                                        }
                                        return (value) {
                                          setState(() {
                                            _showActualExpense = value;
                                          });
                                        };
                                      }(),
                                      activeColor: const Color(0xFF8B5CF6),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: isReceivable,
                                  onChanged: (value) {
                                    setState(() {
                                      isReceivable = value ?? false;
                                      if (!isReceivable) {
                                        receivableAmount = '';
                                        receivableAmountError = null;
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFF8B5CF6),
                                ),
                                Expanded(
                                  child: Text(
                                    'Split bill',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isReceivable) ...[
                              const SizedBox(height: 12),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Receivable Amount',
                                  prefixIcon: Icon(Icons.currency_rupee, color: const Color(0xFF8B5CF6)),
                                  errorText: receivableAmountError,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Amount friends will pay back',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (v) {
                                  setState(() {
                                    receivableAmount = v;
                                    receivableAmountError = null;
                                    if (receivableAmount.isNotEmpty) {
                                      final receivableVal = double.tryParse(receivableAmount);
                                      final totalAmount = double.tryParse(amount);
                                      if (receivableVal == null || receivableVal <= 0) {
                                        receivableAmountError = 'Enter a valid receivable amount';
                                      } else if (totalAmount != null && receivableVal > totalAmount) {
                                        receivableAmountError = 'Receivable amount cannot exceed total amount';
                                      }
                                    }
                                  });
                                },
                                style: const TextStyle(color: Colors.black87, fontSize: 16),
                              ),
                              if (_showActualExpense && amount.isNotEmpty && receivableAmount.isNotEmpty && (double.tryParse(receivableAmount) ?? 0) < (double.tryParse(amount) ?? 0)) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.green.shade600, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Your actual expense: ₹${(double.tryParse(amount) ?? 0) - (double.tryParse(receivableAmount) ?? 0)}',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
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
                          ],
                        ),
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
                            onPressed: (accountName.isEmpty || amountError != null || amount.isEmpty || isSubmitting ||
                                (isReceivable && (receivableAmountError != null || receivableAmount.isEmpty)))
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
                                          isReceivable: isReceivable,
                                          receivableAmount: isReceivable ? double.parse(receivableAmount) : 0.0,
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
        _buildSearchAndFilters(),
        Expanded(
          child: Selector<DataProvider, List<ExpenseTransaction>>(
            selector: (_, provider) => provider.transactions,
            builder: (context, allTransactions, _) {
              final filteredTransactions = _filterTransactions(allTransactions);
              
              if (filteredTransactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != null || _selectedDateFilter != DateFilterType.all
                            ? 'No transactions match your filters'
                            : 'No transactions yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (_searchQuery.isNotEmpty || _selectedCategory != null || _selectedDateFilter != DateFilterType.all || _selectedSourceFilter != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
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
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final groupedTransactions = _groupTransactionsByDate(filteredTransactions);
              
              return PerformanceUtils.createOptimizedListView(
                itemCount: groupedTransactions.length,
                padding: const EdgeInsets.only(top: 8, bottom: 80),
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
                              '₹${dayTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Transactions for this date
                      ...dayTransactions.asMap().entries.map((entry) {
                        final txIndex = allTransactions.indexOf(entry.value);
                        final tx = entry.value;
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
                            Provider.of<DataProvider>(context, listen: false).deleteTransaction(txIndex);
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
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onLongPress: () async {
                                if (await _confirmDelete(context, 'transaction')) {
                                  if (context.mounted) {
                                    Provider.of<DataProvider>(context, listen: false).deleteTransaction(txIndex);
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
                                        // Account and category info
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
                                                      _formatDate(tx.date),
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
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Amount only
                                        Container(
                                          width: 100,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₹${tx.amount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                  fontSize: 18,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
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
                                    if (tx.isReceivable && tx.receivableAmount > 0) ...[
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
                                          _showReceivablePaymentDialog(context, tx, txIndex);
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
                                      ),
                                    ],
                                    // Edit button at the bottom
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        color: const Color(0xFF6366F1),
                                        tooltip: 'Edit Transaction',
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        onPressed: () {
                                          final accounts = Provider.of<DataProvider>(context, listen: false).accounts;
                                          _showEditTransactionDialog(context, accounts, tx, txIndex);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                    ],
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
