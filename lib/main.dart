import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';
import 'database/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面平台需要初始化 sqflite_ffi
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 设置状态栏样式（仅移动端）
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // 初始化数据库
  await DBHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()..loadTransactions()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
      ],
      child: const LokiiApp(),
    ),
  );
}
