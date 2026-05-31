import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _autoRecordEnabled = false;
  bool _darkModeEnabled = false;
  String _currencySymbol = '¥';

  bool get autoRecordEnabled => _autoRecordEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  String get currencySymbol => _currencySymbol;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoRecordEnabled = prefs.getBool('autoRecordEnabled') ?? false;
    _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    _currencySymbol = prefs.getString('currencySymbol') ?? '¥';
    notifyListeners();
  }

  Future<void> setAutoRecordEnabled(bool value) async {
    _autoRecordEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoRecordEnabled', value);
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool value) async {
    _darkModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkModeEnabled', value);
    notifyListeners();
  }

  Future<void> setCurrencySymbol(String value) async {
    _currencySymbol = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencySymbol', value);
    notifyListeners();
  }
}
