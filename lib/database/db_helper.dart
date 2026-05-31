import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lokii.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 桌面平台使用应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      dbPath = join(appDir.path, 'Lokii');
      // 确保目录存在
      await Directory(dbPath).create(recursive: true);
    } else {
      dbPath = await getDatabasesPath();
    }
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 账目表
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        isExpense INTEGER NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        tags TEXT DEFAULT '',
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isAutoRecorded INTEGER DEFAULT 0
      )
    ''');

    // 标签表
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        useCount INTEGER DEFAULT 0,
        lastUsedAt TEXT NOT NULL
      )
    ''');

    // 分类表
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        iconFontFamily TEXT,
        colorValue INTEGER NOT NULL,
        isExpense INTEGER NOT NULL,
        isDefault INTEGER DEFAULT 1
      )
    ''');

    // 创建索引
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(category)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_isExpense ON transactions(isExpense)',
    );
  }

  // ==================== 账目操作 ====================

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<int> updateTransaction(String id, Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    bool? isExpense,
    String? category,
    String? tag,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    if (isExpense != null) {
      whereClause += ' AND isExpense = ?';
      whereArgs.add(isExpense ? 1 : 0);
    }
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }
    if (tag != null) {
      whereClause += ' AND tags LIKE ?';
      whereArgs.add('%$tag%');
    }

    return await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, createdAt DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM transactions
      WHERE isExpense = 1 AND date >= ? AND date <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM transactions
      WHERE isExpense = 0 AND date >= ? AND date <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'expense': (expenseResult.first['total'] as num).toDouble(),
      'income': (incomeResult.first['total'] as num).toDouble(),
    };
  }

  Future<Map<String, double>> getCategorySummary({
    required int year,
    required int month,
    required bool isExpense,
  }) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT category, COALESCE(SUM(amount), 0) as total FROM transactions
      WHERE isExpense = ? AND date >= ? AND date <= ?
      GROUP BY category ORDER BY total DESC
    ''', [isExpense ? 1 : 0, startDate.toIso8601String(), endDate.toIso8601String()]);

    Map<String, double> summary = {};
    for (var row in result) {
      summary[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return summary;
  }

  Future<List<Map<String, dynamic>>> getYearlyMonthlyTotals(int year, {bool? isExpense}) async {
    final db = await database;
    String whereClause = "strftime('%Y', date) = ?";
    List<dynamic> whereArgs = [year.toString()];

    if (isExpense != null) {
      whereClause += ' AND isExpense = ?';
      whereArgs.add(isExpense ? 1 : 0);
    }

    return await db.rawQuery('''
      SELECT strftime('%m', date) as month, COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE $whereClause
      GROUP BY strftime('%m', date)
      ORDER BY month
    ''', whereArgs);
  }

  // ==================== 标签操作 ====================

  Future<int> insertTag(Map<String, dynamic> tag) async {
    final db = await database;
    return await db.insert('tags', tag, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTag(String id, Map<String, dynamic> tag) async {
    final db = await database;
    return await db.update('tags', tag, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTag(String id) async {
    final db = await database;
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTags({int? limit}) async {
    final db = await database;
    return await db.query(
      'tags',
      orderBy: 'useCount DESC, lastUsedAt DESC',
      limit: limit,
    );
  }

  Future<void> incrementTagUseCount(String tagName) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE tags SET useCount = useCount + 1, lastUsedAt = ?
      WHERE name = ?
    ''', [DateTime.now().toIso8601String(), tagName]);
  }

  // ==================== 分类操作 ====================

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('categories', category, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCategories({bool? isExpense}) async {
    final db = await database;
    if (isExpense != null) {
      return await db.query(
        'categories',
        where: 'isExpense = ?',
        whereArgs: [isExpense ? 1 : 0],
        orderBy: 'isDefault DESC, name',
      );
    }
    return await db.query('categories', orderBy: 'isDefault DESC, name');
  }

  // ==================== 清空操作 ====================

  Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<void> deleteAllTags() async {
    final db = await database;
    await db.delete('tags');
  }

  Future<void> deleteAllCategories() async {
    final db = await database;
    await db.delete('categories');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
