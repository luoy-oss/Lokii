import 'package:flutter/material.dart';

class AppCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense; // true=支出分类, false=收入分类
  final bool isDefault; // 是否为预设分类

  AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
    this.isDefault = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'isExpense': isExpense ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(
        map['iconCodePoint'] as int,
        fontFamily: map['iconFontFamily'] as String?,
      ),
      color: Color(map['colorValue'] as int),
      isExpense: map['isExpense'] == 1,
      isDefault: map['isDefault'] == 1,
    );
  }
}
