import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class ExportHelper {
  /// 导出账目为 CSV 文件
  static Future<File> exportToCSV(List<Transaction> transactions, {String? fileName}) async {
    final dir = await getTemporaryDirectory();
    final name = fileName ?? 'lokii_export_${Formatters.date(DateTime.now())}.csv';
    final file = File('${dir.path}/$name');

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

  /// 分享导出的文件
  static Future<void> shareCSV(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Lokii 记账数据导出',
    );
  }

  /// 导出指定时间范围的账目
  static Future<void> exportAndShare(
    List<Transaction> transactions, {
    String? dateRange,
  }) async {
    final fileName = 'lokii_${dateRange ?? Formatters.date(DateTime.now())}.csv';
    final file = await exportToCSV(transactions, fileName: fileName);
    await shareCSV(file);
  }
}
