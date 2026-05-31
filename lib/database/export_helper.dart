import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class ExportHelper {
  /// 获取导出目录（Windows: 文档/Lokii, 其他: 应用文档目录）
  static Future<Directory> _getExportDir() async {
    Directory baseDir;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 桌面平台：保存到用户文档目录
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final exportDir = Directory('${baseDir.path}${Platform.pathSeparator}Lokii导出');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// 导出账目为 CSV 文件并保存到本地
  static Future<File> exportToCSV(List<Transaction> transactions, {String? fileName}) async {
    final dir = await _getExportDir();
    final name = fileName ?? 'lokii_export_${Formatters.date(DateTime.now())}.csv';
    final file = File('${dir.path}${Platform.pathSeparator}$name');

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
    // 添加 BOM 以支持中文在 Excel 中正确显示
    await file.writeAsString('﻿$csv', flush: true);
    return file;
  }

  /// 导出并返回文件路径（供 UI 显示保存位置）
  static Future<String> exportAndSave(
    List<Transaction> transactions, {
    String? dateRange,
  }) async {
    final fileName = 'lokii_${dateRange ?? Formatters.date(DateTime.now())}.csv';
    final file = await exportToCSV(transactions, fileName: fileName);
    return file.path;
  }
}
