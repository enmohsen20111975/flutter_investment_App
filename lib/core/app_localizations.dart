import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AppLocalizations — نظام ترجمة بسيط (عربى/إنجليزى)
class AppLocalizations {
  static const String _prefKey = 'app_language';
  static Locale _currentLocale = const Locale('ar', 'EG');

  static Locale get currentLocale => _currentLocale;
  static bool get isArabic => _currentLocale.languageCode == 'ar';
  static bool get isEnglish => _currentLocale.languageCode == 'en';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'ar';
    _currentLocale = Locale(code, code == 'ar' ? 'EG' : 'US');
  }

  static Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  static Future<void> toggleLocale() async {
    if (isArabic) {
      await setLocale(const Locale('en', 'US'));
    } else {
      await setLocale(const Locale('ar', 'EG'));
    }
  }

  /// ترجمة سريعة
  static String tr(String ar, String en) {
    return isArabic ? ar : en;
  }
}

/// InheritedWidget لتوفير الترجمات للشاشات
class LocalizationProvider extends InheritedWidget {
  final Locale locale;

  const LocalizationProvider({
    super.key,
    required this.locale,
    required super.child,
  });

  static LocalizationProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocalizationProvider>();
  }

  @override
  bool updateShouldNotify(LocalizationProvider oldWidget) {
    return locale != oldWidget.locale;
  }

  /// ترجمة سريعة من الـ context
  static String tr(BuildContext context, String ar, String en) {
    final provider = of(context);
    if (provider == null) return ar;
    return provider.locale.languageCode == 'ar' ? ar : en;
  }
}
