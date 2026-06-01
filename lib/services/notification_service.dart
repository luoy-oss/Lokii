import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../database/db_helper.dart';

/// 通知自动记账服务
///
/// 解析支付宝、微信支付等支付通知，自动创建账目。
/// 通过 MethodChannel/EventChannel 与 Android NotificationListenerService 通信。
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final DBHelper _db = DBHelper.instance;

  // ── 平台通道 ──────────────────────────────────────────────────────

  static const MethodChannel _methodChannel = MethodChannel('com.lokii/notification');
  static const EventChannel _eventChannel = EventChannel('com.lokii/notification_stream');

  StreamSubscription<dynamic>? _notificationSubscription;
  bool _isListening = false;

  /// 通知流控制器（供 UI 层订阅）
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// 通知流（新通知到达时触发）
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  // ── 支付通知关键词 ────────────────────────────────────────────────

  static const List<String> _paymentKeywords = [
    '付款', '支付', '消费', '扣款', '支出',
    '收款', '到账', '收入', '转入',
    '成功', '完成', '已付', '已支付',
    '退款', '退回', '返还',
    '转账', '红包', '提现', '充值',
  ];

  // ── 金额正则 ──────────────────────────────────────────────────────

  // 支付宝/微信通知格式：¥123.45 或 ￥123.45
  static final RegExp _alipayAmountReg = RegExp(r'[¥￥](\d+\.?\d*)');
  // 通用金额格式
  static final RegExp _genericAmountReg = RegExp(r'(\d+\.?\d{0,2})\s*元');

  // ── 权限与服务状态 ────────────────────────────────────────────────

  /// 检查通知监听权限是否已授予
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _methodChannel.invokeMethod<bool>('checkNotificationPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('检查通知权限失败: $e');
      return false;
    }
  }

  /// 打开系统通知监听设置页面
  Future<void> openNotificationSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('打开通知设置失败: $e');
    }
  }

  /// 打开电池优化设置页面
  Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('openBatterySettings');
    } catch (e) {
      debugPrint('打开电池设置失败: $e');
    }
  }

  /// 检查 NotificationListenerService 是否正在运行
  Future<bool> isServiceRunning() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _methodChannel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } catch (e) {
      debugPrint('检查服务状态失败: $e');
      return false;
    }
  }

  /// 启动保活前台服务
  Future<void> startKeepAlive() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('startKeepAlive');
    } catch (e) {
      debugPrint('启动保活服务失败: $e');
    }
  }

  /// 停止保活前台服务
  Future<void> stopKeepAlive() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('stopKeepAlive');
    } catch (e) {
      debugPrint('停止保活服务失败: $e');
    }
  }

  // ── 通知监听 ──────────────────────────────────────────────────────

  /// 开始监听通知流
  void startListening() {
    if (_isListening) return;
    if (!Platform.isAndroid) return;

    _notificationSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final notification = Map<String, dynamic>.from(event);
          debugPrint('收到通知: ${notification['packageName']} - ${notification['title']}');
          _notificationController.add(notification);
          _processNotification(notification);
        }
      },
      onError: (dynamic error) {
        debugPrint('通知流错误: $error');
      },
    );

    _isListening = true;
    debugPrint('开始监听通知流');
  }

  /// 停止监听通知流
  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _isListening = false;
    debugPrint('停止监听通知流');
  }

  /// 是否正在监听
  bool get isListening => _isListening;

  // ── 通知处理 ──────────────────────────────────────────────────────

  /// 处理收到的通知
  Future<void> _processNotification(Map<String, dynamic> notification) async {
    try {
      final packageName = notification['packageName'] as String? ?? '';
      final title = notification['title'] as String? ?? '';
      final content = notification['content'] as String? ?? '';
      final subText = notification['subText'] as String? ?? '';
      final bigText = notification['bigText'] as String? ?? '';

      // 合并所有文本
      final fullContent = '$title $content $subText $bigText'.trim();

      await parseAndRecord(
        packageName: packageName,
        title: title,
        content: fullContent,
      );
    } catch (e) {
      debugPrint('处理通知失败: $e');
    }
  }

  // ── 解析与记账 ────────────────────────────────────────────────────

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
      String category = _inferCategory(content, isExpense, packageName);

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
    final incomeKeywords = ['收款', '到账', '收入', '转入', '退款', '退回', '返还', '红包', '提现', '充值'];
    return !incomeKeywords.any((keyword) => text.contains(keyword));
  }

  /// 提取金额
  double? _extractAmount(String content) {
    // 尝试支付宝/微信格式（¥123.45）
    final payMatch = _alipayAmountReg.firstMatch(content);
    if (payMatch != null) {
      return double.tryParse(payMatch.group(1)!);
    }

    // 尝试通用格式（123.45元）
    final genericMatch = _genericAmountReg.firstMatch(content);
    if (genericMatch != null) {
      return double.tryParse(genericMatch.group(1)!);
    }

    // 最后尝试纯数字
    final numberReg = RegExp(r'(\d+\.?\d{0,2})');
    final match = numberReg.firstMatch(content);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }

    return null;
  }

  /// 根据通知内容推断分类
  String _inferCategory(String content, bool isExpense, String packageName) {
    if (!isExpense) return '其他';

    // 根据包名推断
    final packageCategory = _inferCategoryFromPackage(packageName);
    if (packageCategory != null) return packageCategory;

    // 根据内容关键词推断
    final categoryKeywords = {
      '餐饮': ['餐厅', '饭店', '外卖', '美团', '饿了么', '肯德基', '麦当劳', '星巴克', '奶茶', '食堂', '小吃', '烧烤', '火锅'],
      '交通': ['滴滴', '出租', '地铁', '公交', '加油', '停车', '高速', '火车', '机票', '航空', '高铁', '打车'],
      '购物': ['淘宝', '京东', '拼多多', '天猫', '超市', '商场', '商城', '网购', '电商'],
      '住房': ['房租', '水费', '电费', '燃气', '物业', '暖气', '宽带'],
      '娱乐': ['电影', '游戏', 'KTV', '健身', '旅游', '景区', '门票'],
      '医疗': ['医院', '药店', '诊所', '挂号', '体检'],
      '教育': ['学费', '培训', '书店', '课程'],
      '通讯': ['话费', '流量', '宽带', '充值'],
      '转账': ['转账', '红包', '提现'],
    };

    for (var entry in categoryKeywords.entries) {
      if (entry.value.any((keyword) => content.contains(keyword))) {
        return entry.key;
      }
    }

    return '其他';
  }

  /// 根据包名推断分类
  String? _inferCategoryFromPackage(String packageName) {
    final packageCategoryMap = {
      'com.sankuai.meituan': '餐饮',      // 美团
      'meituan.takeoutnew': '餐饮',       // 美团外卖
      'me.ele': '餐饮',                   // 饿了么
      'com.sdu.didi.psnger': '交通',      // 滴滴出行
      'com.autonavi.minimap': '交通',     // 高德地图
      'com.MobileTicket': '交通',         // 12306
      'com.ctrip.ticket': '交通',         // 携程
      'com.jingdong.app.mall': '购物',    // 京东
      'com.taobao.taobao': '购物',        // 淘宝
      'com.xunmeng.pinduoduo': '购物',    // 拼多多
      'com.ss.android.ugc.aweme': '购物', // 抖音
      'com.smile.gifmaker': '购物',       // 快手
    };
    return packageCategoryMap[packageName];
  }

  /// 提取商户名
  String? _extractMerchant(String content) {
    // 尝试提取"商户名"或"收款方"后面的内容
    final merchantPatterns = [
      RegExp(r'(?:商户|收款方|商家|店铺)[：:]?\s*(.+?)(?:\s|$|，|。)'),
      RegExp(r'(?:在|于)\s*(.+?)\s*(?:消费|支付|付款)'),
      RegExp(r'(?:向|给)\s*(.+?)\s*(?:转账|付款|支付)'),
    ];

    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        final merchant = match.group(1)?.trim();
        if (merchant != null && merchant.isNotEmpty && merchant.length < 20) {
          return merchant;
        }
      }
    }
    return null;
  }

  // ── 资源释放 ──────────────────────────────────────────────────────

  void dispose() {
    stopListening();
    _notificationController.close();
  }
}
