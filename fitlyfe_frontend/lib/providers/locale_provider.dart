import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      // Check if the saved code is supported, otherwise default to system or null
      final supported = L10n.all.firstWhere(
        (element) => element.languageCode == languageCode,
        orElse: () => L10n.all.first,
      );
      _locale = supported;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!L10n.all.any((l) => l.languageCode == locale.languageCode)) return;

    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);

    notifyListeners();
  }
}

class L10n {
  static final all = [
    const Locale('en'), // English
  ];

  static String getNativeName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      default:
        return code.toUpperCase();
    }
  }
}
