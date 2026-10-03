import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language the user picked for the app, remembered across restarts.
///
/// A null [locale] means "follow the phone's language"; Flutter then picks the
/// best match from [AppLocalizations.supportedLocales] (English if none match).
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'language_code';

  Locale? _locale;

  Locale? get locale => _locale;

  /// Supported locales with English first: Flutter falls back to the first
  /// entry when the phone's language isn't supported, and the generated list
  /// is alphabetical (which would make that German).
  static final List<Locale> supportedLocales = [
    const Locale('en'),
    ...AppLocalizations.supportedLocales.where((l) => l.languageCode != 'en'),
  ];

  /// Restores the saved choice. Unknown or no-longer-supported values fall
  /// back to the system language.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    _locale = _supported(code);
    notifyListeners();
  }

  /// Switches the app language; null goes back to the system language.
  Future<void> setLocale(Locale? locale) async {
    final supported = _supported(locale?.languageCode);
    if (locale != null && supported == null) {
      throw ArgumentError.value(locale, 'locale', 'is not supported');
    }
    _locale = supported;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (supported == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, supported.languageCode);
    }
  }

  Locale? _supported(String? languageCode) {
    if (languageCode == null) return null;
    for (final locale in supportedLocales) {
      if (locale.languageCode == languageCode) return locale;
    }
    return null;
  }

  /// A language's name in that language, for the language picker.
  static String nativeName(Locale locale) => switch (locale.languageCode) {
        'en' => 'English',
        'es' => 'Español',
        'fr' => 'Français',
        'de' => 'Deutsch',
        _ => locale.languageCode,
      };
}
