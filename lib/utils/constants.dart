import 'package:flutter/material.dart';

/// 分类定义
class AppCategories {
  // 支出分类
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': '餐饮', 'icon': Icons.restaurant, 'color': Color(0xFFFF6B6B)},
    {'name': '交通', 'icon': Icons.directions_car, 'color': Color(0xFF4ECDC4)},
    {'name': '购物', 'icon': Icons.shopping_bag, 'color': Color(0xFFFFBE76)},
    {'name': '住房', 'icon': Icons.home, 'color': Color(0xFF6C5CE7)},
    {'name': '娱乐', 'icon': Icons.sports_esports, 'color': Color(0xFFFD79A8)},
    {'name': '医疗', 'icon': Icons.local_hospital, 'color': Color(0xFF00B894)},
    {'name': '教育', 'icon': Icons.school, 'color': Color(0xFF0984E3)},
    {'name': '通讯', 'icon': Icons.phone_android, 'color': Color(0xFF636E72)},
    {'name': '服饰', 'icon': Icons.checkroom, 'color': Color(0xFFE17055)},
    {'name': '日用', 'icon': Icons.shopping_cart, 'color': Color(0xFF00CEC9)},
    {'name': '美容', 'icon': Icons.face, 'color': Color(0xFFE84393)},
    {'name': '社交', 'icon': Icons.people, 'color': Color(0xFFFDCB6E)},
    {'name': '旅行', 'icon': Icons.flight, 'color': Color(0xFF55A3F5)},
    {'name': '宠物', 'icon': Icons.pets, 'color': Color(0xFFA29BFE)},
    {'name': '其他', 'icon': Icons.more_horiz, 'color': Color(0xFFB2BEC3)},
  ];

  // 收入分类
  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': '工资', 'icon': Icons.account_balance_wallet, 'color': Color(0xFF00B894)},
    {'name': '奖金', 'icon': Icons.card_giftcard, 'color': Color(0xFFFFBE76)},
    {'name': '投资', 'icon': Icons.trending_up, 'color': Color(0xFF0984E3)},
    {'name': '兼职', 'icon': Icons.work, 'color': Color(0xFF6C5CE7)},
    {'name': '红包', 'icon': Icons.redeem, 'color': Color(0xFFFF6B6B)},
    {'name': '退款', 'icon': Icons.replay, 'color': Color(0xFF00CEC9)},
    {'name': '其他', 'icon': Icons.more_horiz, 'color': Color(0xFFB2BEC3)},
  ];
}
