import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class DataProvider extends ChangeNotifier {
  Future<void> updateTransaction(int index, ExpenseTransaction updatedTx, double oldAmount, String oldAccountName) async {
    if (index < 0 || index >= _transactions.length) return;
    final oldTx = _transactions[index];
    _transactions[index] = updatedTx;
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    await _saveTransactions();

    // Restore old account balance
    final oldAccountIdx = _accounts.indexWhere((a) => a.name == oldAccountName);
    if (oldAccountIdx != -1) {
      _accounts[oldAccountIdx] = _accounts[oldAccountIdx].copyWith(
        balance: _accounts[oldAccountIdx].balance + oldAmount,
        balanceDate: DateTime.now(),
      );
    }
    // Deduct new amount from new account
    final newAccountIdx = _accounts.indexWhere((a) => a.name == updatedTx.accountName);
    if (newAccountIdx != -1) {
      _accounts[newAccountIdx] = _accounts[newAccountIdx].copyWith(
        balance: _accounts[newAccountIdx].balance - updatedTx.amount,
        balanceDate: DateTime.now(),
      );
    }
    await _saveAccounts();
    notifyListeners();
  }
  Future<void> setAccountBalance(String accountName, double newBalance) async {
    final idx = _accounts.indexWhere((a) => a.name == accountName);
    if (idx != -1) {
      final updated = _accounts[idx].copyWith(
        balance: newBalance,
        balanceDate: DateTime.now(),
      );
      _accounts[idx] = updated;
      await _saveAccounts();
      notifyListeners();
    }
  }
  Future<void> addMoneyToAccount(String accountName, double amount) async {
    final idx = _accounts.indexWhere((a) => a.name == accountName);
    if (idx != -1 && amount > 0) {
      final updated = _accounts[idx].copyWith(
        balance: _accounts[idx].balance + amount,
        balanceDate: DateTime.now(),
      );
      _accounts[idx] = updated;
      await _saveAccounts();
      notifyListeners();
    }
  }
  List<Account> _accounts = [];
  List<ExpenseTransaction> _transactions = [];
  bool _initialized = false;

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<ExpenseTransaction> get transactions => List.unmodifiable(_transactions);
  bool get initialized => _initialized;

  DataProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountList = prefs.getStringList('accounts') ?? [];
      final txList = prefs.getStringList('transactions') ?? [];

      _accounts = accountList
          .map((e) => Account.fromMap(Map<String, dynamic>.from(Uri.splitQueryString(e))))
          .toList();
    _transactions = txList
      .map((e) => ExpenseTransaction.fromMap(Map<String, dynamic>.from(Uri.splitQueryString(e))))
      .toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date));

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data: $e');
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> addTransaction(ExpenseTransaction tx) async {
    try {
  _transactions.add(tx);
  _transactions.sort((a, b) => b.date.compareTo(a.date));
  await _saveTransactions();

      // Update account balance
      final accountIndex = _accounts.indexWhere((a) => a.name == tx.accountName);
      if (accountIndex != -1) {
        final updatedAccount = Account(
          name: _accounts[accountIndex].name,
          balance: _accounts[accountIndex].balance - tx.amount,
          balanceDate: DateTime.now(),
        );
        _accounts[accountIndex] = updatedAccount;
        await _saveAccounts();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(int index) async {
    try {
      if (index >= 0 && index < _transactions.length) {
        final tx = _transactions[index];
  _transactions.removeAt(index);
  _transactions.sort((a, b) => b.date.compareTo(a.date));
  await _saveTransactions();

        // Update account balance
        final accountIndex = _accounts.indexWhere((a) => a.name == tx.accountName);
        if (accountIndex != -1) {
          final updatedAccount = Account(
            name: _accounts[accountIndex].name,
            balance: _accounts[accountIndex].balance + tx.amount,
            balanceDate: DateTime.now(),
          );
          _accounts[accountIndex] = updatedAccount;
          await _saveAccounts();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<void> addAccount(Account account) async {
    try {
      if (!_accounts.any((a) => a.name == account.name)) {
        _accounts.add(account);
        await _saveAccounts();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding account: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(int index) async {
    try {
      if (index >= 0 && index < _accounts.length) {
        final accountName = _accounts[index].name;
        _accounts.removeAt(index);
        await _saveAccounts();

        // Remove associated transactions
        _transactions.removeWhere((tx) => tx.accountName == accountName);
        await _saveTransactions();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('accounts',
        _accounts.map((a) => Uri(queryParameters: a.toMap()).query).toList());
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('transactions',
        _transactions.map((t) => Uri(queryParameters: t.toMap()).query).toList());
  }
}
