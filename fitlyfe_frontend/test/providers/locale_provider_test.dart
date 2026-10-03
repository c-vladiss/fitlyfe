import 'package:fitlyfe_frontend/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('follows the system language until a choice is made', () async {
    final provider = LocaleProvider();
    await provider.load();
    expect(provider.locale, isNull);
  });

  test('remembers the chosen language across restarts', () async {
    final provider = LocaleProvider();
    var notified = 0;
    provider.addListener(() => notified++);

    await provider.setLocale(const Locale('de'));

    expect(provider.locale, const Locale('de'));
    expect(notified, 1);
    final restarted = LocaleProvider();
    await restarted.load();
    expect(restarted.locale, const Locale('de'));
  });

  test('choosing the system default forgets the saved language', () async {
    final provider = LocaleProvider();
    await provider.setLocale(const Locale('fr'));

    await provider.setLocale(null);

    expect(provider.locale, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language_code'), isNull);
  });

  test('a region variant maps to the supported language', () async {
    final provider = LocaleProvider();
    await provider.setLocale(const Locale('es', 'MX'));
    expect(provider.locale, const Locale('es'));
  });

  test('an unsupported language is rejected', () async {
    final provider = LocaleProvider();
    expect(() => provider.setLocale(const Locale('xx')), throwsArgumentError);
    expect(provider.locale, isNull);
  });

  test('a saved language that is no longer supported falls back to the system', () async {
    SharedPreferences.setMockInitialValues({'language_code': 'it'});
    final provider = LocaleProvider();
    await provider.load();
    expect(provider.locale, isNull);
  });

  test('keeps a choice saved by the previous version of the app', () async {
    SharedPreferences.setMockInitialValues({'language_code': 'en'});
    final provider = LocaleProvider();
    await provider.load();
    expect(provider.locale, const Locale('en'));
  });

  test('language names are shown in their own language', () {
    expect(LocaleProvider.nativeName(const Locale('es')), 'Español');
    expect(LocaleProvider.nativeName(const Locale('fr')), 'Français');
    expect(LocaleProvider.nativeName(const Locale('de')), 'Deutsch');
  });
}
