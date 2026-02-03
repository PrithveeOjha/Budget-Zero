import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  List<Account> _accounts = [];
  List<CategoryGroup> _categoryGroups = [];
  List<BudgetCategory> _categories = [];
  List<MonthlyBudget> _monthlyBudgets = [];
  List<BudgetTransaction> _transactions = [];
  double _toBeBudgeted = 0;
  String _currentMonth = '';
  String _currency = 'USD';
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;

  List<Account> get accounts => _accounts;
  List<CategoryGroup> get categoryGroups => _categoryGroups;
  List<BudgetCategory> get categories => _categories;
  List<MonthlyBudget> get monthlyBudgets => _monthlyBudgets;
  List<BudgetTransaction> get transactions => _transactions;
  double get toBeBudgeted => _toBeBudgeted;
  String get currentMonth => _currentMonth;
  String get currency => _currency;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;

  BudgetProvider() {
    _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    _loadData();
  }

  Future<void> retryLoad() async {
    await _loadData();
  }

  String? _loadError;
  String? get loadError => _loadError;

  Future<void> _loadData() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _accounts = await _db.getAccounts();
      _categoryGroups = await _db.getCategoryGroups();
      _categories = await _db.getCategories();
      _transactions = await _db.getTransactions();

      await _loadMonthlyBudgets();
      await _loadToBeBudgeted();

      final savedCurrency = await _db.getSetting('currency');
      if (savedCurrency != null) {
        _currency = savedCurrency;
      }

      final savedTheme = await _db.getSetting('theme_mode');
      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.name == savedTheme,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      debugPrint('Failed to load data: $e');
      _loadError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMonthlyBudgets() async {
    _monthlyBudgets = await _db.getMonthlyBudgets(_currentMonth);

    // Ensure every category has a budget entry for current month
    for (var category in _categories) {
      final existing = _monthlyBudgets.where((b) => b.categoryId == category.id).firstOrNull;
      if (existing == null) {
        // Check for rollover from previous month
        final prevMonth = _getPreviousMonth(_currentMonth);
        final prevBudget = await _db.getMonthlyBudget(category.id, prevMonth);
        final rollover = prevBudget?.available ?? 0;

        final activity = await _db.getCategoryActivity(category.id, _currentMonth);

        final newBudget = MonthlyBudget(
          id: _uuid.v4(),
          categoryId: category.id,
          month: _currentMonth,
          assigned: rollover > 0 ? rollover : 0, // Positive rollover
          activity: activity,
        );
        await _db.upsertMonthlyBudget(newBudget);
        _monthlyBudgets.add(newBudget);
      }
    }
  }

  Future<void> _loadToBeBudgeted() async {
    _toBeBudgeted = await _db.getToBeBudgeted(_currentMonth);
  }

  String _getPreviousMonth(String month) {
    final date = DateFormat('yyyy-MM').parse(month);
    final prevDate = DateTime(date.year, date.month - 1);
    return DateFormat('yyyy-MM').format(prevDate);
  }

  // Account operations
  Future<void> addAccount(String name, AccountType type, double balance) async {
    final account = Account(
      id: _uuid.v4(),
      name: name,
      type: type,
      balance: balance,
    );
    await _db.insertAccount(account);
    _accounts.add(account);
    await _loadToBeBudgeted();
    notifyListeners();
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index != -1) {
      final updated = _accounts[index].copyWith(balance: newBalance);
      await _db.updateAccount(updated);
      _accounts[index] = updated;
      await _loadToBeBudgeted();
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String accountId) async {
    await _db.deleteAccount(accountId);
    _accounts.removeWhere((a) => a.id == accountId);
    await _loadToBeBudgeted();
    notifyListeners();
  }

  // Budget operations
  Future<void> assignToBudget(String categoryId, double amount) async {
    final index = _monthlyBudgets.indexWhere((b) => b.categoryId == categoryId);
    if (index != -1) {
      final current = _monthlyBudgets[index];
      final updated = current.copyWith(assigned: current.assigned + amount);
      await _db.upsertMonthlyBudget(updated);
      _monthlyBudgets[index] = updated;
      await _loadToBeBudgeted();
      notifyListeners();
    }
  }

  Future<void> setAssigned(String categoryId, double amount) async {
    final index = _monthlyBudgets.indexWhere((b) => b.categoryId == categoryId);
    if (index != -1) {
      final current = _monthlyBudgets[index];
      final updated = current.copyWith(assigned: amount);
      await _db.upsertMonthlyBudget(updated);
      _monthlyBudgets[index] = updated;
      await _loadToBeBudgeted();
      notifyListeners();
    }
  }

  MonthlyBudget? getBudgetForCategory(String categoryId) {
    return _monthlyBudgets.where((b) => b.categoryId == categoryId).firstOrNull;
  }

  List<BudgetCategory> getCategoriesForGroup(String groupId) {
    return _categories.where((c) => c.groupId == groupId).toList();
  }

  // Transaction operations
  Future<void> addTransaction({
    required double amount,
    required String payee,
    required String accountId,
    String? categoryId,
    String? memo,
    bool isIncome = false,
    DateTime? date,
  }) async {
    final transaction = BudgetTransaction(
      id: _uuid.v4(),
      amount: amount,
      date: date ?? DateTime.now(),
      payee: payee,
      categoryId: categoryId,
      accountId: accountId,
      memo: memo,
      isIncome: isIncome,
    );

    await _db.insertTransaction(transaction);
    _transactions.insert(0, transaction);

    // Update account balance
    final accountIndex = _accounts.indexWhere((a) => a.id == accountId);
    if (accountIndex != -1) {
      final account = _accounts[accountIndex];
      final newBalance = isIncome
          ? account.balance + amount
          : account.balance - amount;
      final updated = account.copyWith(balance: newBalance);
      await _db.updateAccount(updated);
      _accounts[accountIndex] = updated;
    }

    // Update category activity if not income
    if (!isIncome && categoryId != null) {
      final budgetIndex = _monthlyBudgets.indexWhere((b) => b.categoryId == categoryId);
      if (budgetIndex != -1) {
        final budget = _monthlyBudgets[budgetIndex];
        final updated = budget.copyWith(activity: budget.activity - amount);
        await _db.upsertMonthlyBudget(updated);
        _monthlyBudgets[budgetIndex] = updated;
      }
    }

    await _loadToBeBudgeted();
    notifyListeners();
  }

  Future<void> deleteTransaction(String transactionId) async {
    final transaction = _transactions.firstWhere((t) => t.id == transactionId);

    // Reverse account balance change
    final accountIndex = _accounts.indexWhere((a) => a.id == transaction.accountId);
    if (accountIndex != -1) {
      final account = _accounts[accountIndex];
      final newBalance = transaction.isIncome
          ? account.balance - transaction.amount
          : account.balance + transaction.amount;
      final updated = account.copyWith(balance: newBalance);
      await _db.updateAccount(updated);
      _accounts[accountIndex] = updated;
    }

    // Reverse category activity
    if (!transaction.isIncome && transaction.categoryId != null) {
      final budgetIndex = _monthlyBudgets.indexWhere(
        (b) => b.categoryId == transaction.categoryId
      );
      if (budgetIndex != -1) {
        final budget = _monthlyBudgets[budgetIndex];
        final updated = budget.copyWith(activity: budget.activity + transaction.amount);
        await _db.upsertMonthlyBudget(updated);
        _monthlyBudgets[budgetIndex] = updated;
      }
    }

    await _db.deleteTransaction(transactionId);
    _transactions.removeWhere((t) => t.id == transactionId);
    await _loadToBeBudgeted();
    notifyListeners();
  }

  // Month navigation
  Future<void> goToNextMonth() async {
    final date = DateFormat('yyyy-MM').parse(_currentMonth);
    final nextDate = DateTime(date.year, date.month + 1);
    _currentMonth = DateFormat('yyyy-MM').format(nextDate);
    _monthlyBudgets = [];
    await _loadMonthlyBudgets();
    await _loadToBeBudgeted();
    notifyListeners();
  }

  Future<void> goToPreviousMonth() async {
    final date = DateFormat('yyyy-MM').parse(_currentMonth);
    final prevDate = DateTime(date.year, date.month - 1);
    _currentMonth = DateFormat('yyyy-MM').format(prevDate);
    _monthlyBudgets = [];
    await _loadMonthlyBudgets();
    await _loadToBeBudgeted();
    notifyListeners();
  }

  // Settings
  Future<void> setCurrency(String currency) async {
    _currency = currency;
    await _db.setSetting('currency', currency);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _db.setSetting('theme_mode', mode.name);
    notifyListeners();
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(symbol: _getCurrencySymbol());
    return format.format(amount);
  }

  String _getCurrencySymbol() {
    switch (_currency) {
      case 'INR':
        return '₹';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }

  // Add category
  Future<void> addCategory(String name, String groupId) async {
    final category = BudgetCategory(
      id: _uuid.v4(),
      groupId: groupId,
      name: name,
    );
    await _db.insertCategory(category);
    _categories.add(category);

    // Create monthly budget entry
    final budget = MonthlyBudget(
      id: _uuid.v4(),
      categoryId: category.id,
      month: _currentMonth,
    );
    await _db.upsertMonthlyBudget(budget);
    _monthlyBudgets.add(budget);

    notifyListeners();
  }

  // Add category group
  Future<void> addCategoryGroup(String name) async {
    final group = CategoryGroup(
      id: _uuid.v4(),
      name: name,
      sortOrder: _categoryGroups.length,
    );
    await _db.insertCategoryGroup(group);
    _categoryGroups.add(group);
    notifyListeners();
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    await _db.deleteCategory(categoryId);
    _categories.removeWhere((c) => c.id == categoryId);
    _monthlyBudgets.removeWhere((b) => b.categoryId == categoryId);
    // Update transactions in memory to remove category reference
    _transactions = _transactions.map((t) {
      if (t.categoryId == categoryId) {
        return BudgetTransaction(
          id: t.id,
          amount: t.amount,
          date: t.date,
          payee: t.payee,
          categoryId: null,
          accountId: t.accountId,
          memo: t.memo,
          isIncome: t.isIncome,
        );
      }
      return t;
    }).toList();
    await _loadToBeBudgeted();
    notifyListeners();
  }

  // Delete category group (and all its categories)
  Future<void> deleteCategoryGroup(String groupId) async {
    // Get categories in this group to update in-memory state
    final categoriesToDelete = _categories.where((c) => c.groupId == groupId).toList();

    await _db.deleteCategoryGroup(groupId);

    // Remove from in-memory lists
    for (var category in categoriesToDelete) {
      _monthlyBudgets.removeWhere((b) => b.categoryId == category.id);
      _transactions = _transactions.map((t) {
        if (t.categoryId == category.id) {
          return BudgetTransaction(
            id: t.id,
            amount: t.amount,
            date: t.date,
            payee: t.payee,
            categoryId: null,
            accountId: t.accountId,
            memo: t.memo,
            isIncome: t.isIncome,
          );
        }
        return t;
      }).toList();
    }
    _categories.removeWhere((c) => c.groupId == groupId);
    _categoryGroups.removeWhere((g) => g.id == groupId);

    await _loadToBeBudgeted();
    notifyListeners();
  }

  Account? getAccountById(String id) {
    return _accounts.where((a) => a.id == id).firstOrNull;
  }

  BudgetCategory? getCategoryById(String? id) {
    if (id == null) return null;
    return _categories.where((c) => c.id == id).firstOrNull;
  }
}
