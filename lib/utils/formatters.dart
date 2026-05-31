import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthFormat = DateFormat('yyyy年M月');
  static final DateFormat _yearFormat = DateFormat('yyyy年');
  static final DateFormat _dayFormat = DateFormat('M月d日');
  static final DateFormat _weekdayFormat = DateFormat('EEEE', 'zh_CN');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// 格式化金额
  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// 格式化金额带符号
  static String currencyWithSign(double amount, {required bool isExpense}) {
    final sign = isExpense ? '-' : '+';
    return '$sign${_currencyFormat.format(amount.abs())}';
  }

  /// 格式化日期
  static String date(DateTime dt) => _dateFormat.format(dt);

  /// 格式化月份
  static String month(DateTime dt) => _monthFormat.format(dt);

  /// 格式化年份
  static String year(DateTime dt) => _yearFormat.format(dt);

  /// 格式化日
  static String day(DateTime dt) => _dayFormat.format(dt);

  /// 格式化时间
  static String time(DateTime dt) => _timeFormat.format(dt);

  /// 格式化星期
  static String weekday(DateTime dt) => _weekdayFormat.format(dt);

  /// 获取今天是星期几的简短描述
  static String shortWeekday(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';
    return _weekdayFormat.format(dt);
  }
}
