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
    const Locale('es'), // Spanish
    const Locale('de'), // German
    const Locale('fr'), // French
    const Locale('it'), // Italian
    const Locale('pt'), // Portuguese
    const Locale('ru'), // Russian
    const Locale('zh'), // Chinese
    const Locale('ja'), // Japanese
    const Locale('ko'), // Korean
    const Locale('hi'), // Hindi
    const Locale('ar'), // Arabic
    const Locale('tr'), // Turkish
    const Locale('nl'), // Dutch
    const Locale('pl'), // Polish
  ];

  static String getNativeName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'de': return 'Deutsch';
      case 'fr': return 'Français';
      case 'it': return 'Italiano';
      case 'pt': return 'Português';
      case 'ru': return 'Русский';
      case 'zh': return '中文';
      case 'ja': return '日本語';
      case 'ko': return '한국어';
      case 'hi': return 'हिन्दी';
      case 'ar': return 'العربية';
      case 'tr': return 'Türkçe';
      case 'nl': return 'Nederlands';
      case 'pl': return 'Polski';
      default: return code.toUpperCase();
    }
  }
  
  static String getFlag(String code) {
     // Optional: You could return flag emojis or asset paths here
     switch (code) {
      case 'en': return '🇺🇸';
      case 'es': return '🇪🇸';
      case 'de': return '🇩🇪';
      case 'fr': return '🇫🇷';
      case 'it': return '🇮🇹';
      case 'pt': return 'PT'; 
      case 'ru': return '🇷🇺';
      case 'zh': return '🇨🇳';
      case 'ja': return '🇯🇵';
      case 'ko': return '🇰🇷';
      case 'hi': return '🇮🇳';
      case 'ar': return '🇸🇦';
      case 'tr': return '🇹🇷';
      case 'nl': return '🇳🇱';
      case 'pl': return '🇵🇱';
      default: return '🏳️';
    }
  }
}
