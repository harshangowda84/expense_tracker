import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/income_transaction.dart';
import '../models/account.dart';
import '../utils/income_category_utils.dart';

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

class _IncomeTabState extends State<IncomeTab> {
  String _searchQuery = '';
  IncomeCategory? _selectedCategory;
  DateFilterType _selectedDateFilter = DateFilterType.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedSourceFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        dateKey = '${date.day}/${date.month}/${date.year}';
      }
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
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
                  hintText: 'Search by amount, account, note, source, or category...',
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
                onTap: _showFilterDialog,
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
                            IncomeCategoryUtils.getCategoryIcon(_selectedCategory!),
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
                    'Filter Income',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Category Filter
              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setModalState(() => _selectedCategory = null);
                      setState(() => _selectedCategory = null);
                    },
                  ),
                  ...IncomeCategoryUtils.getAllCategories().map((category) {
                    return FilterChip(
                      label: Text(IncomeCategoryUtils.getCategoryName(category)),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        final newCategory = selected ? category : null;
                        setModalState(() => _selectedCategory = newCategory);
                        setState(() => _selectedCategory = newCategory);
                      },
                    );
                  }),
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
              
              // Custom Date Range
              FilterChip(
                label: Text(_selectedDateFilter == DateFilterType.custom && _customStartDate != null && _customEndDate != null
                    ? '${_customStartDate!.day}/${_customStartDate!.month} - ${_customEndDate!.day}/${_customEndDate!.month}'
                    : 'Custom Range'),
                selected: _selectedDateFilter == DateFilterType.custom,
                onSelected: (selected) async {
                  if (selected) {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setModalState(() {
                        _selectedDateFilter = DateFilterType.custom;
                        _customStartDate = picked.start;
                        _customEndDate = picked.end;
                      });
                      setState(() {
                        _selectedDateFilter = DateFilterType.custom;
                        _customStartDate = picked.start;
                        _customEndDate = picked.end;
                      });
                    }
                  } else {
                    setModalState(() {
                      _selectedDateFilter = DateFilterType.all;
                      _customStartDate = null;
                      _customEndDate = null;
                    });
                    setState(() {
                      _selectedDateFilter = DateFilterType.all;
                      _customStartDate = null;
                      _customEndDate = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Source Filter
              const Text(
                'Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('All Sources'),
                        selected: _selectedSourceFilter == null,
                        onSelected: (selected) {
                          setModalState(() => _selectedSourceFilter = null);
                          setState(() => _selectedSourceFilter = null);
                        },
                      ),
                      ...sources.map((source) {
                        return FilterChip(
                          label: Text(source),
                          selected: _selectedSourceFilter == source,
                          onSelected: (selected) {
                            final newSource = selected ? source : null;
                            setModalState(() => _selectedSourceFilter = newSource);
                            setState(() => _selectedSourceFilter = newSource);
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Clear All Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
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
                  child: const Text('Clear All Filters'),
                ),
              ),
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
                'Delete Income',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this $itemType?',
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
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: Selector<DataProvider, List<IncomeTransaction>>(
            selector: (_, provider) => provider.incomeTransactions,
            builder: (context, allTransactions, _) {
              final filteredTransactions = _filterTransactions(allTransactions);
              
              if (filteredTransactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != null || _selectedDateFilter != DateFilterType.all
                            ? 'No income matches your filters'
                            : 'No income recorded yet',
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
              
              return ListView.builder(
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
                          confirmDismiss: (_) => _confirmDelete(context, 'income'),
                          onDismissed: (_) {
                            Provider.of<DataProvider>(context, listen: false).deleteIncomeTransaction(txIndex);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Income deleted'),
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
                                if (await _confirmDelete(context, 'income')) {
                                  if (context.mounted) {
                                    Provider.of<DataProvider>(context, listen: false).deleteIncomeTransaction(txIndex);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Income deleted'),
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
                                          flex: 3,
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
                                                  Text(
                                                    _formatTime(tx.date),
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 12,
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
                                        // Amount with Edit Icon
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '+₹${tx.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18),
                                              color: const Color(0xFF6366F1),
                                              tooltip: 'Edit Income',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                              onPressed: () => _editIncomeTransaction(context, tx, txIndex),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (tx.note.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tx.note,
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 12,
                                            fontFamily: 'Inter',
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
                      }),
                    ],
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
              'Add Income',
              style: TextStyle(
                fontFamily: 'Inter', 
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _showAddIncomeDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
    final amountController = TextEditingController(text: transaction.amount.toString());
    final noteController = TextEditingController(text: transaction.note);
    final sourceController = TextEditingController(text: transaction.source);
    IncomeCategory selectedCategory = transaction.category;
    String? selectedAccount = transaction.accountName;
    DateTime selectedDate = transaction.date;

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
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        width: constraints.maxWidth - 32,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                    Icons.edit,
                                    color: Color(0xFF6366F1),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Edit Income',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Amount Field
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                hintText: 'Enter amount',
                                prefixIcon: const Icon(Icons.currency_rupee),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Category Dropdown
                            DropdownButtonFormField<IncomeCategory>(
                              value: selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(IncomeCategoryUtils.getCategoryIcon(selectedCategory)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: IncomeCategory.values.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(
                                        IncomeCategoryUtils.getCategoryIcon(category),
                                        size: 20,
                                        color: IncomeCategoryUtils.getCategoryColor(category),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(IncomeCategoryUtils.getCategoryName(category)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedCategory = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Account Dropdown
                            Consumer<DataProvider>(
                              builder: (context, dataProvider, child) {
                                final accounts = dataProvider.accounts;
                                return DropdownButtonFormField<String>(
                                  value: selectedAccount,
                                  decoration: InputDecoration(
                                    labelText: 'Account',
                                    prefixIcon: const Icon(Icons.account_balance_wallet),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: accounts.map((account) {
                                    return DropdownMenuItem(
                                      value: account.name,
                                      child: Text(account.name),
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
                            const SizedBox(height: 16),
                            
                            // Source Field
                            TextField(
                              controller: sourceController,
                              decoration: InputDecoration(
                                labelText: 'Source (Optional)',
                                hintText: 'e.g., Company name, client name',
                                prefixIcon: const Icon(Icons.business),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Note Field
                            TextField(
                              controller: noteController,
                              decoration: InputDecoration(
                                labelText: 'Note (Optional)',
                                hintText: 'Add a note',
                                prefixIcon: const Icon(Icons.note),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            
                            // Date Picker
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              ),
                              trailing: const Icon(Icons.edit),
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
                            ),
                            const SizedBox(height: 24),
                            
                            // Update Button
                            ElevatedButton(
                              onPressed: () async {
                                final amount = double.tryParse(amountController.text);
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid amount'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (selectedAccount == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select an account'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                final updatedTransaction = IncomeTransaction(
                                  id: transaction.id, // Keep the same ID
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
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Income updated successfully!'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                      duration: const Duration(milliseconds: 1500),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Update Income',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  void _showAddIncomeDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final sourceController = TextEditingController();
    IncomeCategory selectedCategory = IncomeCategory.salary;
    String? selectedAccount;
    DateTime selectedDate = DateTime.now();

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
                                  'Add Income',
                                  style: TextStyle(
                                    fontFamily: 'Inter', 
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
                            
                            // Amount
                            TextField(
                              controller: amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixText: '₹',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            
                            // Category
                            DropdownButtonFormField<IncomeCategory>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: IncomeCategoryUtils.getAllCategories().map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(
                                        IncomeCategoryUtils.getCategoryIcon(category),
                                        color: IncomeCategoryUtils.getCategoryColor(category),
                                        size: 20,
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
                            const SizedBox(height: 16),
                            
                            // Account
                            Consumer<DataProvider>(
                              builder: (context, dataProvider, child) {
                                return DropdownButtonFormField<String>(
                                  value: selectedAccount,
                                  decoration: const InputDecoration(
                                    labelText: 'Account',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: dataProvider.accounts.map((account) {
                                    return DropdownMenuItem(
                                      value: account.name,
                                      child: Text(account.name),
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
                            const SizedBox(height: 16),
                            
                            // Source
                            TextField(
                              controller: sourceController,
                              decoration: const InputDecoration(
                                labelText: 'Source (Optional)',
                                hintText: 'e.g., Company Name, Client',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Note
                            TextField(
                              controller: noteController,
                              decoration: const InputDecoration(
                                labelText: 'Note (Optional)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            
                            // Date
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_today),
                              title: Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              ),
                              trailing: const Icon(Icons.edit),
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
                            ),
                            const SizedBox(height: 24),
                            
                            // Add Button
                            ElevatedButton(
                              onPressed: () async {
                                final amount = double.tryParse(amountController.text);
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid amount'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (selectedAccount == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select an account'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Income added successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Add Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}