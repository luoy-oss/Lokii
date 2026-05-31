import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../database/db_helper.dart';
import '../utils/formatters.dart';

class ExportHelper {
  /// 获取默认导出目录
  static Future<Directory> _getDefaultDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${baseDir.path}${Platform.pathSeparator}Lokii导出');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// 导出账目为 CSV 文件到指定目录
  static Future<File> exportToCSV(
    List<Transaction> transactions, {
    String? directory,
    String? fileName,
  }) async {
    final dir = directory ?? (await _getDefaultDir()).path;
    final name = fileName ?? 'lokii_export_${Formatters.date(DateTime.now())}.csv';
    final file = File('$dir${Platform.pathSeparator}$name');

    List<List<dynamic>> rows = [
      ['日期', '类型', '分类', '金额', '标签', '备注', '自动记录'],
    ];

    for (var t in transactions) {
      rows.add([
        Formatters.date(t.date),
        t.isExpense ? '支出' : '收入',
        t.category,
        t.amount.toStringAsFixed(2),
        t.tags.join(' | '),
        t.note ?? '',
        t.isAutoRecorded ? '是' : '否',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString('﻿$csv', flush: true);
    return file;
  }

  /// 从 CSV 文件导入账目
  static Future<int> importFromCSV(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final content = await file.readAsString();
    // 去掉 BOM
    final csvContent = content.startsWith('﻿') ? content.substring(1) : content;
    final rows = const CsvToListConverter().convert(csvContent);

    if (rows.length < 2) return 0;

    final db = DBHelper.instance;
    int count = 0;

    // 跳过表头
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4) continue;

      try {
        final dateParts = (row[0] as String).split('-');
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
        final isExpense = (row[1] as String) == '支出';
        final category = row[2] as String;
        final amount = double.parse(row[3] as String);
        final tags = (row.length > 4 && (row[4] as String).isNotEmpty)
            ? (row[4] as String).split(' | ')
            : <String>[];
        final note = (row.length > 5 && (row[5] as String).isNotEmpty)
            ? row[5] as String
            : null;
        final isAuto = row.length > 6 && (row[6] as String) == '是';

        await db.insertTransaction({
          'id': '${DateTime.now().millisecondsSinceEpoch}_$i',
          'amount': amount,
          'isExpense': isExpense ? 1 : 0,
          'category': category,
          'note': note,
          'tags': tags.join(','),
          'date': date.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'isAutoRecorded': isAuto ? 1 : 0,
        });
        count++;
      } catch (_) {
        // 跳过格式错误的行
        continue;
      }
    }

    return count;
  }

  /// 导出配置到 JSON 文件
  static Future<File> exportConfig({
    String? directory,
  }) async {
    final dir = directory ?? (await _getDefaultDir()).path;
    final name = 'lokii_config_${Formatters.date(DateTime.now())}.json';
    final file = File('$dir${Platform.pathSeparator}$name');

    final prefs = await SharedPreferences.getInstance();
    final config = <String, dynamic>{
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': {
        'autoRecordEnabled': prefs.getBool('autoRecordEnabled') ?? false,
        'darkModeEnabled': prefs.getBool('darkModeEnabled') ?? false,
        'currencySymbol': prefs.getString('currencySymbol') ?? '¥',
      },
      'tags': [],
      'categories': [],
    };

    // 导出标签
    final tagMaps = await DBHelper.instance.getTags();
    config['tags'] = tagMaps;

    // 导出分类
    final catMaps = await DBHelper.instance.getCategories();
    config['categories'] = catMaps;

    final jsonStr = const JsonEncoder.withIndent('  ').convert(config);
    await file.writeAsString(jsonStr, flush: true);
    return file;
  }

  /// 导入配置
  static Future<int> importConfig(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('配置文件不存在');
    }

    final content = await file.readAsString();
    final config = jsonDecode(content) as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    final db = DBHelper.instance;

    // 导入设置
    final settings = config['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      if (settings.containsKey('autoRecordEnabled')) {
        await prefs.setBool('autoRecordEnabled', settings['autoRecordEnabled'] as bool);
      }
      if (settings.containsKey('darkModeEnabled')) {
        await prefs.setBool('darkModeEnabled', settings['darkModeEnabled'] as bool);
      }
      if (settings.containsKey('currencySymbol')) {
        await prefs.setString('currencySymbol', settings['currencySymbol'] as String);
      }
    }

    // 导入标签
    int tagCount = 0;
    final tags = config['tags'] as List<dynamic>?;
    if (tags != null) {
      for (var tag in tags) {
        await db.insertTag(Map<String, dynamic>.from(tag as Map));
        tagCount++;
      }
    }

    // 导入分类
    int catCount = 0;
    final categories = config['categories'] as List<dynamic>?;
    if (categories != null) {
      for (var cat in categories) {
        await db.insertCategory(Map<String, dynamic>.from(cat as Map));
        catCount++;
      }
    }

    return tagCount + catCount;
  }

  /// 导出数据并返回文件路径
  static Future<String> exportAndSave(
    List<Transaction> transactions, {
    String? dateRange,
  }) async {
    final fileName = 'lokii_${dateRange ?? Formatters.date(DateTime.now())}.csv';
    final file = await exportToCSV(transactions, fileName: fileName);
    return file.path;
  }

  /// 获取默认导出目录路径
  static Future<String> getDefaultExportPath() async {
    return (await _getDefaultDir()).path;
  }
}
