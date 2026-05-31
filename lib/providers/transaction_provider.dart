import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../database/db_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;
  List<Transaction> _transactions = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;

  /// 加载当前选中月份的账目
  Future<void> loadCurrentMonth() async {
    await loadMonthTransactions(_selectedMonth.year, _selectedMonth.month);
  }

  /// 加载指定月份的账目
  Future<void> loadMonthTransactions(int year, int month) async {
    _isLoading = true;
    notifyListeners();

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final maps = await _db.getTransactions(startDate: startDate, endDate: endDate);
    _transactions = maps.map((m) => Transaction.fromMap(m)).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// 切换选中月份
  Future<void> setSelectedMonth(DateTime month) async {
    _selectedMonth = month;
    await loadMonthTransactions(month.year, month.month);
  }

  /// 前一个月
  Future<void> previousMonth() async {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    await loadMonthTransactions(_selectedMonth.year, _selectedMonth.month);
  }

  /// 后一个月
  Future<void> nextMonth() async {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    await loadMonthTransactions(_selectedMonth.year, _selectedMonth.month);
  }

  /// 添加账目
  Future<void> addTransaction(Transaction transaction) async {
    await _db.insertTransaction(transaction.toMap());
    await loadMonthTransactions(_selectedMonth.year, _selectedMonth.month);
  }

  /// 更新账目
  Future<void> updateTransaction(Transaction transaction) async {
    await _db.updateTransaction(transaction.id, transaction.toMap());
    await loadMonthTransactions(_selectedMonth.year, _selectedMonth.month);
  }

  /// 删除账目
  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await loadMonthTransactions(_selectedMonth.year, _selectedMonth.month);
  }

  /// 快速添加账目
  Future<void> quickAdd({
    required double amount,
    required bool isExpense,
    required String category,
    List<String> tags = const [],
    String? note,
    bool isAutoRecorded = false,
  }) async {
    final transaction = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      isExpense: isExpense,
      category: category,
      tags: tags,
      note: note,
      date: DateTime.now(),
      isAutoRecorded: isAutoRecorded,
    );
    await addTransaction(transaction);
  }

  /// 导入数据后强制刷新
  Future<void> refreshAfterImport() async {
    _selectedMonth = DateTime.now();
    await loadMonthTransactions(_selectedMonth.year, _selectedMonth.month);
  }

  /// 获取月度汇总
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    return await _db.getMonthlySummary(year, month);
  }

  /// 获取分类汇总
  Future<Map<String, double>> getCategorySummary({
    required int year,
    required int month,
    required bool isExpense,
  }) async {
    return await _db.getCategorySummary(year: year, month: month, isExpense: isExpense);
  }

  /// 获取年度月度汇总
  Future<List<Map<String, dynamic>>> getYearlyMonthlyTotals(int year, {bool? isExpense}) async {
    return await _db.getYearlyMonthlyTotals(year, isExpense: isExpense);
  }

  /// 获取指定分类的账目
  Future<List<Transaction>> getTransactionsByCategory(
    String category, {
    int? year,
    int? month,
  }) async {
    DateTime? startDate;
    DateTime? endDate;
    if (year != null && month != null) {
      startDate = DateTime(year, month, 1);
      endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    }
    final maps = await _db.getTransactions(
      category: category,
      startDate: startDate,
      endDate: endDate,
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// 获取所有账目（用于导出）
  Future<List<Transaction>> getAllTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final maps = await _db.getTransactions(startDate: startDate, endDate: endDate);
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// 获取指定标签的账目
  Future<List<Transaction>> getTransactionsByTag(String tag) async {
    final maps = await _db.getTransactions(tag: tag);
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }
}
