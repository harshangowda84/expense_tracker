import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/credit_card.dart';
import '../models/income_transaction.dart';

class DataProvider extends ChangeNotifier {
  Future<void> updateTransaction(int index, ExpenseTransaction updatedTx, double oldAmount, String oldAccountName) async {
    if (index < 0 || index >= _transactions.length) return;
    
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
  List<CreditCard> _creditCards = [];
  List<IncomeTransaction> _incomeTransactions = [];
  bool _initialized = false;

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<ExpenseTransaction> get transactions => List.unmodifiable(_transactions);
  List<CreditCard> get creditCards => List.unmodifiable(_creditCards);
  List<IncomeTransaction> get incomeTransactions => List.unmodifiable(_incomeTransactions);
  bool get initialized => _initialized;

  DataProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountList = prefs.getStringList('accounts') ?? [];
      final txList = prefs.getStringList('transactions') ?? [];
      final creditCardList = prefs.getStringList('creditCards') ?? [];
      final incomeList = prefs.getStringList('incomeTransactions') ?? [];

      _accounts = accountList
          .map((e) => Account.fromMap(Map<String, dynamic>.from(Uri.splitQueryString(e))))
          .toList();
    _transactions = txList
      .map((e) => ExpenseTransaction.fromMap(Map<String, dynamic>.from(Uri.splitQueryString(e))))
      .toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    _creditCards = creditCardList
      .map((e) => CreditCard.fromMap(Map<String, dynamic>.from(Uri.splitQueryString(e))))
      .toList();

    _incomeTransactions = incomeList
      .map((e) => IncomeTransaction.fromMap(Map<String, dynamic>.from(Uri.splitQueryString(e))))
      .toList();
    _incomeTransactions.sort((a, b) => b.date.compareTo(a.date));

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
      // Validate account/card exists and has sufficient balance/limit
      if (!canAddTransactionToAccount(tx.accountName, tx.sourceType)) {
        throw Exception('Selected account/card does not exist');
      }

      if (!hasSufficientBalance(tx.accountName, tx.sourceType, tx.amount)) {
        final message = tx.sourceType == TransactionSourceType.bankAccount 
            ? 'Insufficient balance in bank account'
            : 'Amount exceeds available credit limit';
        throw Exception(message);
      }

      _transactions.add(tx);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      await _saveTransactions();

      if (tx.sourceType == TransactionSourceType.bankAccount) {
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
      } else {
        // Update credit card limit
        final cardIndex = _creditCards.indexWhere((c) => c.name == tx.accountName);
        if (cardIndex != -1) {
          final updatedCard = CreditCard(
            name: _creditCards[cardIndex].name,
            limit: _creditCards[cardIndex].limit,
            dueDate: _creditCards[cardIndex].dueDate,
            addedDate: _creditCards[cardIndex].addedDate,
            usedAmount: (_creditCards[cardIndex].usedAmount ?? 0) + tx.amount,
          );
          _creditCards[cardIndex] = updatedCard;
          await _saveCreditCards();
        }
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

        if (tx.sourceType == TransactionSourceType.bankAccount) {
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
        } else {
          // Update credit card limit
          final cardIndex = _creditCards.indexWhere((c) => c.name == tx.accountName);
          if (cardIndex != -1) {
            final updatedCard = CreditCard(
              name: _creditCards[cardIndex].name,
              limit: _creditCards[cardIndex].limit,
              dueDate: _creditCards[cardIndex].dueDate,
              addedDate: _creditCards[cardIndex].addedDate,
              usedAmount: (_creditCards[cardIndex].usedAmount ?? 0) - tx.amount,
            );
            _creditCards[cardIndex] = updatedCard;
            await _saveCreditCards();
          }
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

  Future<void> updateAccount(int index, Account updatedAccount) async {
    try {
      if (index >= 0 && index < _accounts.length) {
        final oldAccountName = _accounts[index].name;
        _accounts[index] = updatedAccount;
        await _saveAccounts();

        // Update transaction account names if name changed
        if (oldAccountName != updatedAccount.name) {
          for (int i = 0; i < _transactions.length; i++) {
            if (_transactions[i].accountName == oldAccountName) {
              _transactions[i] = _transactions[i].copyWith(accountName: updatedAccount.name);
            }
          }
          await _saveTransactions();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating account: $e');
      rethrow;
    }
  }

  Future<void> insertAccountAt(int index, Account account) async {
    try {
      if (index >= 0 && index <= _accounts.length) {
        _accounts.insert(index, account);
        await _saveAccounts();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error inserting account: $e');
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

  Future<void> _saveIncomeTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('incomeTransactions',
        _incomeTransactions.map((t) => Uri(queryParameters: t.toMap()).query).toList());
  }

  // Income Transaction CRUD Operations
  Future<void> addIncomeTransaction(IncomeTransaction tx) async {
    try {
      // Validate account exists
      if (!_accounts.any((account) => account.name == tx.accountName)) {
        throw Exception('Account "${tx.accountName}" does not exist.');
      }

      // Add transaction
      _incomeTransactions.add(tx);
      _incomeTransactions.sort((a, b) => b.date.compareTo(a.date));
      await _saveIncomeTransactions();
      
      // Add money to account
      final accountIndex = _accounts.indexWhere((a) => a.name == tx.accountName);
      if (accountIndex != -1) {
        final updatedAccount = _accounts[accountIndex].copyWith(
          balance: _accounts[accountIndex].balance + tx.amount,
          balanceDate: DateTime.now(),
        );
        _accounts[accountIndex] = updatedAccount;
        await _saveAccounts();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding income transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteIncomeTransaction(int index) async {
    try {
      if (index >= 0 && index < _incomeTransactions.length) {
        final tx = _incomeTransactions[index];
        
        // Remove money from account
        final accountIndex = _accounts.indexWhere((a) => a.name == tx.accountName);
        if (accountIndex != -1) {
          final updatedAccount = _accounts[accountIndex].copyWith(
            balance: _accounts[accountIndex].balance - tx.amount,
            balanceDate: DateTime.now(),
          );
          _accounts[accountIndex] = updatedAccount;
          await _saveAccounts();
        }
        
        _incomeTransactions.removeAt(index);
        await _saveIncomeTransactions();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting income transaction: $e');
      rethrow;
    }
  }

  Future<void> updateIncomeTransaction(int index, IncomeTransaction updatedTx, double oldAmount, String oldAccountName) async {
    if (index < 0 || index >= _incomeTransactions.length) return;
    
    _incomeTransactions[index] = updatedTx;
    _incomeTransactions.sort((a, b) => b.date.compareTo(a.date));
    await _saveIncomeTransactions();

    // Remove old amount from old account
    final oldAccountIdx = _accounts.indexWhere((a) => a.name == oldAccountName);
    if (oldAccountIdx != -1) {
      _accounts[oldAccountIdx] = _accounts[oldAccountIdx].copyWith(
        balance: _accounts[oldAccountIdx].balance - oldAmount,
        balanceDate: DateTime.now(),
      );
    }
    // Add new amount to new account
    final newAccountIdx = _accounts.indexWhere((a) => a.name == updatedTx.accountName);
    if (newAccountIdx != -1) {
      _accounts[newAccountIdx] = _accounts[newAccountIdx].copyWith(
        balance: _accounts[newAccountIdx].balance + updatedTx.amount,
        balanceDate: DateTime.now(),
      );
    }
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> addCreditCard(CreditCard card) async {
    try {
      if (!_creditCards.any((c) => c.name == card.name)) {
        _creditCards.add(card);
        await _saveCreditCards();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding credit card: $e');
      rethrow;
    }
  }

  Future<void> deleteCreditCard(int index) async {
    try {
      if (index >= 0 && index < _creditCards.length) {
        _creditCards.removeAt(index);
        await _saveCreditCards();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting credit card: $e');
      rethrow;
    }
  }

  Future<void> insertCreditCardAt(int index, CreditCard card) async {
    try {
      if (index >= 0 && index <= _creditCards.length) {
        _creditCards.insert(index, card);
        await _saveCreditCards();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error inserting credit card: $e');
      rethrow;
    }
  }

  Future<void> _saveCreditCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('creditCards',
        _creditCards.map((c) => Uri(queryParameters: c.toMap()).query).toList());
  }

  Future<void> updateCreditCard(int index, CreditCard updatedCard) async {
    try {
      if (index >= 0 && index < _creditCards.length) {
        _creditCards[index] = updatedCard;
        await _saveCreditCards();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating credit card: $e');
      rethrow;
    }
  }

  // Reset credit card balance - paid manually (no account deduction)
  Future<void> resetCreditCardBalance(int index) async {
    try {
      if (index >= 0 && index < _creditCards.length) {
        final card = _creditCards[index];
        final resetCard = CreditCard(
          name: card.name,
          limit: card.limit,
          dueDate: card.dueDate,
          addedDate: card.addedDate,
          usedAmount: 0.0,
        );
        _creditCards[index] = resetCard;
        await _saveCreditCards();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resetting credit card balance: $e');
      rethrow;
    }
  }

  // Reset credit card balance by paying from bank account
  Future<void> resetCreditCardBalanceWithBankAccount(int cardIndex, String bankAccountName, [double? customAmount]) async {
    try {
      if (cardIndex >= 0 && cardIndex < _creditCards.length) {
        final card = _creditCards[cardIndex];
        final paymentAmount = customAmount ?? card.usedBalance;

        // Find the bank account
        final accountIndex = _accounts.indexWhere((a) => a.name == bankAccountName);
        if (accountIndex == -1) {
          throw Exception('Bank account not found');
        }

        // Check if account has sufficient balance
        if (_accounts[accountIndex].balance < paymentAmount) {
          throw Exception('Insufficient balance in bank account');
        }

        // Deduct amount from bank account
        final updatedAccount = Account(
          name: _accounts[accountIndex].name,
          balance: _accounts[accountIndex].balance - paymentAmount,
          balanceDate: DateTime.now(),
        );
        _accounts[accountIndex] = updatedAccount;

        // Update credit card balance (partial or full payment)
        final newUsedAmount = (card.usedAmount ?? 0.0) - paymentAmount;
        final resetCard = CreditCard(
          name: card.name,
          limit: card.limit,
          dueDate: card.dueDate,
          addedDate: card.addedDate,
          usedAmount: newUsedAmount,
        );
        _creditCards[cardIndex] = resetCard;

        // Create a transaction record for the credit card payment
        final transaction = ExpenseTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          accountName: bankAccountName,
          amount: paymentAmount,
          date: DateTime.now(),
          category: ExpenseCategory.bills, // Credit card payment is typically a bill
          note: 'Credit card payment: ${card.name}',
          sourceType: TransactionSourceType.bankAccount,
        );
        
        // Add the transaction
        _transactions.add(transaction);
        await _saveTransactions();

        // Save both updates
        await _saveAccounts();
        await _saveCreditCards();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resetting credit card balance with bank account: $e');
      rethrow;
    }
  }

  // Get available accounts/cards for transaction
  bool canAddTransactionToAccount(String accountName, TransactionSourceType sourceType) {
    if (sourceType == TransactionSourceType.bankAccount) {
      return _accounts.any((a) => a.name == accountName);
    } else {
      return _creditCards.any((c) => c.name == accountName);
    }
  }

  // Check if account/card has sufficient balance/limit
  bool hasSufficientBalance(String accountName, TransactionSourceType sourceType, double amount) {
    if (sourceType == TransactionSourceType.bankAccount) {
      final account = _accounts.firstWhere(
        (a) => a.name == accountName,
        orElse: () => Account(name: '', balance: 0, balanceDate: DateTime.now()),
      );
      return account.balance >= amount;
    } else {
      final card = _creditCards.firstWhere(
        (c) => c.name == accountName,
        orElse: () => CreditCard(name: '', limit: 0, dueDate: 1, addedDate: DateTime.now()),
      );
      return card.availableBalance >= amount;
    }
  }
}
