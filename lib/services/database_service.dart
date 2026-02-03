import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'budget_zero.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        balance REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE category_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        name TEXT NOT NULL,
        target_amount REAL,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (group_id) REFERENCES category_groups (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        month TEXT NOT NULL,
        assigned REAL DEFAULT 0,
        activity REAL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        payee TEXT NOT NULL,
        category_id TEXT,
        account_id TEXT NOT NULL,
        memo TEXT,
        is_income INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Insert default category groups and categories
    await _insertDefaults(db);
  }

  Future<void> _insertDefaults(Database db) async {
    // Default category groups
    final groups = [
      {'id': 'grp_bills', 'name': 'Bills', 'sort_order': 0},
      {'id': 'grp_needs', 'name': 'Needs', 'sort_order': 1},
      {'id': 'grp_wants', 'name': 'Wants', 'sort_order': 2},
      {'id': 'grp_savings', 'name': 'Savings Goals', 'sort_order': 3},
    ];

    for (var group in groups) {
      await db.insert('category_groups', group);
    }

    // Default categories
    final categories = [
      {'id': 'cat_rent', 'group_id': 'grp_bills', 'name': 'Rent/Mortgage', 'sort_order': 0},
      {'id': 'cat_electric', 'group_id': 'grp_bills', 'name': 'Electricity', 'sort_order': 1},
      {'id': 'cat_phone', 'group_id': 'grp_bills', 'name': 'Phone', 'sort_order': 2},
      {'id': 'cat_internet', 'group_id': 'grp_bills', 'name': 'Internet', 'sort_order': 3},
      {'id': 'cat_groceries', 'group_id': 'grp_needs', 'name': 'Groceries', 'sort_order': 0},
      {'id': 'cat_transport', 'group_id': 'grp_needs', 'name': 'Transportation', 'sort_order': 1},
      {'id': 'cat_medical', 'group_id': 'grp_needs', 'name': 'Medical', 'sort_order': 2},
      {'id': 'cat_dining', 'group_id': 'grp_wants', 'name': 'Dining Out', 'sort_order': 0},
      {'id': 'cat_entertainment', 'group_id': 'grp_wants', 'name': 'Entertainment', 'sort_order': 1},
      {'id': 'cat_shopping', 'group_id': 'grp_wants', 'name': 'Shopping', 'sort_order': 2},
      {'id': 'cat_emergency', 'group_id': 'grp_savings', 'name': 'Emergency Fund', 'sort_order': 0},
      {'id': 'cat_vacation', 'group_id': 'grp_savings', 'name': 'Vacation', 'sort_order': 1},
    ];

    for (var category in categories) {
      await db.insert('categories', category);
    }
  }

  // Account methods
  Future<List<Account>> getAccounts() async {
    final db = await database;
    final maps = await db.query('accounts');
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<void> insertAccount(Account account) async {
    final db = await database;
    await db.insert('accounts', account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // Category Group methods
  Future<List<CategoryGroup>> getCategoryGroups() async {
    final db = await database;
    final maps = await db.query('category_groups', orderBy: 'sort_order');
    return maps.map((map) => CategoryGroup.fromMap(map)).toList();
  }

  Future<void> insertCategoryGroup(CategoryGroup group) async {
    final db = await database;
    await db.insert('category_groups', group.toMap());
  }

  // Category methods
  Future<List<BudgetCategory>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'sort_order');
    return maps.map((map) => BudgetCategory.fromMap(map)).toList();
  }

  Future<List<BudgetCategory>> getCategoriesByGroup(String groupId) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'sort_order',
    );
    return maps.map((map) => BudgetCategory.fromMap(map)).toList();
  }

  Future<void> insertCategory(BudgetCategory category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    // Delete associated monthly budgets first
    await db.delete('monthly_budgets', where: 'category_id = ?', whereArgs: [id]);
    // Set category_id to null for transactions with this category
    await db.update('transactions', {'category_id': null}, where: 'category_id = ?', whereArgs: [id]);
    // Delete the category
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCategoryGroup(String id) async {
    final db = await database;
    // Get all categories in this group
    final categories = await db.query('categories', where: 'group_id = ?', whereArgs: [id]);
    // Delete each category and its associated data
    for (var category in categories) {
      await deleteCategory(category['id'] as String);
    }
    // Delete the group
    await db.delete('category_groups', where: 'id = ?', whereArgs: [id]);
  }

  // Monthly Budget methods
  Future<MonthlyBudget?> getMonthlyBudget(String categoryId, String month) async {
    final db = await database;
    final maps = await db.query(
      'monthly_budgets',
      where: 'category_id = ? AND month = ?',
      whereArgs: [categoryId, month],
    );
    if (maps.isEmpty) return null;
    return MonthlyBudget.fromMap(maps.first);
  }

  Future<List<MonthlyBudget>> getMonthlyBudgets(String month) async {
    final db = await database;
    final maps = await db.query(
      'monthly_budgets',
      where: 'month = ?',
      whereArgs: [month],
    );
    return maps.map((map) => MonthlyBudget.fromMap(map)).toList();
  }

  Future<void> upsertMonthlyBudget(MonthlyBudget budget) async {
    final db = await database;
    await db.insert(
      'monthly_budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Transaction methods
  Future<List<BudgetTransaction>> getTransactions({int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  Future<List<BudgetTransaction>> getTransactionsByMonth(String month) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: "strftime('%Y-%m', date) = ?",
      whereArgs: [month],
      orderBy: 'date DESC',
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  Future<List<BudgetTransaction>> getTransactionsByAccount(String accountId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => BudgetTransaction.fromMap(map)).toList();
  }

  Future<void> insertTransaction(BudgetTransaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Settings methods
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Calculate "To Be Budgeted"
  Future<double> getToBeBudgeted(String month) async {
    final db = await database;

    // Get total of all cash/savings accounts (not credit)
    final accountResult = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total
      FROM accounts
      WHERE type != 1
    ''');
    final totalFunds = (accountResult.first['total'] as num?)?.toDouble() ?? 0;

    // Get total assigned this month and all previous months
    final assignedResult = await db.rawQuery('''
      SELECT COALESCE(SUM(assigned), 0) as total
      FROM monthly_budgets
      WHERE month <= ?
    ''', [month]);
    final totalAssigned = (assignedResult.first['total'] as num?)?.toDouble() ?? 0;

    return totalFunds - totalAssigned;
  }

  // Get activity for a category in a month
  Future<double> getCategoryActivity(String categoryId, String month) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN is_income = 0 THEN -amount ELSE amount END), 0) as total
      FROM transactions
      WHERE category_id = ? AND strftime('%Y-%m', date) = ?
    ''', [categoryId, month]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
