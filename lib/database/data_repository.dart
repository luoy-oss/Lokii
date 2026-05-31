import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/transaction.dart';
import 'db_helper.dart';

/// 统一数据仓库：导入、导出、备份、恢复
class DataRepository {
  static final DataRepository instance = DataRepository._init();
  DataRepository._init();

  final DBHelper _db = DBHelper.instance;

  // ── 获取数据目录 ─────────────────────────────────────────────────

  Future<Directory> _getBaseDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'Lokii'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _getBackupDir() async {
    final base = await _getBaseDir();
    final dir = Directory(p.join(base.path, 'backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _getExportDir() async {
    final base = await _getBaseDir();
    final dir = Directory(p.join(base.path, '导出'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── 导出全部数据为 JSON ──────────────────────────────────────────

  Future<Map<String, dynamic>> _collectAllData() async {
    final txMaps = await _db.getTransactions();
    final transactions = txMaps.map((m) => Transaction.fromMap(m)).toList();
    final tags = await _db.getTags();
    final categories = await _db.getCategories();

    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'tags': tags,
      'categories': categories,
    };
  }

  /// 导出数据到 JSON 文件，返回文件路径
  Future<String> exportToJson({String? directory}) async {
    final dir = directory ?? (await _getExportDir()).path;
    final now = DateTime.now();
    final name = 'lokii_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';
    final file = File(p.join(dir, name));

    final data = await _collectAllData();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(json, flush: true);
    return file.path;
  }

  // ── 备份当前数据 ─────────────────────────────────────────────────

  /// 创建备份，返回备份文件路径
  Future<String> backup() async {
    final dir = await _getBackupDir();
    final now = DateTime.now();
    final name = 'backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.json';
    final file = File(p.join(dir.path, name));

    final data = await _collectAllData();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(json, flush: true);
    return file.path;
  }

  /// 获取所有备份文件（按时间倒序）
  Future<List<File>> getBackups() async {
    final dir = await _getBackupDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// 从备份文件恢复数据
  Future<ImportResult> restoreFromBackup(String filePath) async {
    return await _importFromJson(filePath);
  }

  // ── 从 JSON 导入数据（覆盖） ────────────────────────────────────

  /// 导入数据，会先自动备份，然后覆盖现有数据
  Future<ImportResult> importFromJson(String filePath) async {
    // 先备份
    final backupPath = await backup();

    // 再导入
    final result = await _importFromJson(filePath);
    result.backupPath = backupPath;
    return result;
  }

  Future<ImportResult> _importFromJson(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在');
    }

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    // 清空现有数据
    await _db.deleteAllTransactions();
    await _db.deleteAllTags();
    await _db.deleteAllCategories();

    // 导入账目
    int txCount = 0;
    final txList = data['transactions'] as List<dynamic>? ?? [];
    for (var item in txList) {
      final tx = Transaction.fromJson(item as Map<String, dynamic>);
      await _db.insertTransaction(tx.toMap());
      txCount++;
    }

    // 导入标签
    int tagCount = 0;
    final tagList = data['tags'] as List<dynamic>? ?? [];
    for (var item in tagList) {
      await _db.insertTag(Map<String, dynamic>.from(item as Map));
      tagCount++;
    }

    // 导入分类
    int catCount = 0;
    final catList = data['categories'] as List<dynamic>? ?? [];
    for (var item in catList) {
      await _db.insertCategory(Map<String, dynamic>.from(item as Map));
      catCount++;
    }

    return ImportResult(
      transactionCount: txCount,
      tagCount: tagCount,
      categoryCount: catCount,
    );
  }

  // ── 删除备份 ────────────────────────────────────────────────────

  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }
}

/// 导入结果
class ImportResult {
  final int transactionCount;
  final int tagCount;
  final int categoryCount;
  String? backupPath;

  ImportResult({
    required this.transactionCount,
    required this.tagCount,
    required this.categoryCount,
    this.backupPath,
  });

  String get summary => '账目 $transactionCount 条，标签 $tagCount 个，分类 $categoryCount 个';
}
