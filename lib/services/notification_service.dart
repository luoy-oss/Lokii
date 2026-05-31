import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../database/db_helper.dart';

/// 通知自动记账服务
/// 解析支付宝、微信支付等支付通知，自动创建账目
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final DBHelper _db = DBHelper.instance;

  // 支付通知关键词
  static const List<String> _paymentKeywords = [
    '付款', '支付', '消费', '扣款', '支出',
    '收款', '到账', '收入', '转入',
  ];

  // 支付宝通知格式
  static final RegExp _alipayAmountReg = RegExp(r'(\d+\.?\d*)元');
  // 微信支付通知格式
  static final RegExp _wechatAmountReg = RegExp(r'¥(\d+\.?\d*)');

  /// 解析通知内容并自动记账
  Future<Transaction?> parseAndRecord({
    required String packageName,
    required String title,
    required String content,
  }) async {
    try {
      // 判断是否为支付类通知
      if (!_isPaymentNotification(title, content)) {
        return null;
      }

      // 解析金额
      double? amount = _extractAmount(content);
      if (amount == null || amount <= 0) {
        return null;
      }

      // 判断收入还是支出
      bool isExpense = _isExpense(title, content);

      // 推断分类
      String category = _inferCategory(content, isExpense);

      // 提取商户名作为备注
      String? note = _extractMerchant(content);

      // 创建账目
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: amount,
        isExpense: isExpense,
        category: category,
        note: note,
        tags: ['自动记账'],
        date: DateTime.now(),
        isAutoRecorded: true,
      );

      await _db.insertTransaction(transaction.toMap());
      debugPrint('自动记账: ${transaction.category} ${transaction.amount}');
      return transaction;
    } catch (e) {
      debugPrint('自动记账解析失败: $e');
      return null;
    }
  }

  /// 判断是否为支付类通知
  bool _isPaymentNotification(String title, String content) {
    final text = '$title$content'.toLowerCase();
    return _paymentKeywords.any((keyword) => text.contains(keyword));
  }

  /// 判断是收入还是支出
  bool _isExpense(String title, String content) {
    final text = '$title$content';
    final incomeKeywords = ['收款', '到账', '收入', '转入', '退款'];
    return !incomeKeywords.any((keyword) => text.contains(keyword));
  }

  /// 提取金额
  double? _extractAmount(String content) {
    // 尝试支付宝格式
    final alipayMatch = _alipayAmountReg.firstMatch(content);
    if (alipayMatch != null) {
      return double.tryParse(alipayMatch.group(1)!);
    }

    // 尝试微信格式
    final wechatMatch = _wechatAmountReg.firstMatch(content);
    if (wechatMatch != null) {
      return double.tryParse(wechatMatch.group(1)!);
    }

    // 通用金额提取
    final genericReg = RegExp(r'(\d+\.?\d{0,2})');
    final match = genericReg.firstMatch(content);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }

    return null;
  }

  /// 根据通知内容推断分类
  String _inferCategory(String content, bool isExpense) {
    if (!isExpense) return '其他';

    final categoryKeywords = {
      '餐饮': ['餐厅', '饭店', '外卖', '美团', '饿了么', '肯德基', '麦当劳', '星巴克', '奶茶'],
      '交通': ['滴滴', '出租', '地铁', '公交', '加油', '停车', '高速'],
      '购物': ['淘宝', '京东', '拼多多', '天猫', '超市', '商场'],
      '住房': ['房租', '水费', '电费', '燃气', '物业'],
      '娱乐': ['电影', '游戏', 'KTV', '健身'],
      '医疗': ['医院', '药店', '诊所'],
      '教育': ['学费', '培训', '书店'],
      '通讯': ['话费', '流量', '宽带'],
    };

    for (var entry in categoryKeywords.entries) {
      if (entry.value.any((keyword) => content.contains(keyword))) {
        return entry.key;
      }
    }

    return '其他';
  }

  /// 提取商户名
  String? _extractMerchant(String content) {
    // 尝试提取"商户名"或"收款方"后面的内容
    final merchantReg = RegExp(r'(?:商户|收款方|商家)[：:]?\s*(.+?)(?:\s|$)');
    final match = merchantReg.firstMatch(content);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }
}
