import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageService extends ChangeNotifier {
  AppLanguageService._();

  static final AppLanguageService instance = AppLanguageService._();
  static const _storageKey = 'app_language_code';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey);
    if (code == null || code.isEmpty) return;
    _locale = Locale(code);
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, languageCode);
  }
}
