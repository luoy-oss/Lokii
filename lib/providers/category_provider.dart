import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../database/db_helper.dart';

class CategoryProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;
  List<AppCategory> _categories = [];

  List<AppCategory> get categories => _categories;
  List<AppCategory> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();
  List<AppCategory> get incomeCategories =>
      _categories.where((c) => !c.isExpense).toList();

  /// 加载分类
  Future<void> loadCategories() async {
    final maps = await _db.getCategories();
    if (maps.isEmpty) {
      // 首次运行，插入默认分类
      await _initDefaultCategories();
      final newMaps = await _db.getCategories();
      _categories = newMaps.map((m) => AppCategory.fromMap(m)).toList();
    } else {
      _categories = maps.map((m) => AppCategory.fromMap(m)).toList();
    }
    notifyListeners();
  }

  /// 初始化默认分类
  Future<void> _initDefaultCategories() async {
    // 支出分类
    for (var cat in AppCategories.expenseCategories) {
      await _db.insertCategory({
        'id': const Uuid().v4(),
        'name': cat['name'],
        'iconCodePoint': (cat['icon'] as IconData).codePoint,
        'iconFontFamily': (cat['icon'] as IconData).fontFamily,
        'colorValue': (cat['color'] as Color).value,
        'isExpense': 1,
        'isDefault': 1,
      });
    }
    // 收入分类
    for (var cat in AppCategories.incomeCategories) {
      await _db.insertCategory({
        'id': const Uuid().v4(),
        'name': cat['name'],
        'iconCodePoint': (cat['icon'] as IconData).codePoint,
        'iconFontFamily': (cat['icon'] as IconData).fontFamily,
        'colorValue': (cat['color'] as Color).value,
        'isExpense': 0,
        'isDefault': 1,
      });
    }
  }

  /// 根据名称查找分类
  AppCategory? findByName(String name, {bool isExpense = true}) {
    try {
      return _categories.firstWhere((c) => c.name == name && c.isExpense == isExpense);
    } catch (_) {
      return null;
    }
  }

  /// 添加自定义分类
  Future<void> addCategory({
    required String name,
    required IconData icon,
    required Color color,
    required bool isExpense,
  }) async {
    final category = {
      'id': const Uuid().v4(),
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'isExpense': isExpense ? 1 : 0,
      'isDefault': 0,
    };
    await _db.insertCategory(category);
    await loadCategories();
  }

  /// 删除分类
  Future<void> deleteCategory(String id) async {
    // TODO: 需要处理该分类下的账目
    notifyListeners();
  }
}
