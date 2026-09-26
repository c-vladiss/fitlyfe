import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import 'package:fitlyfe_frontend/l10n/l10n_extensions.dart';
import 'package:fitlyfe_frontend/providers/locale_provider.dart';
import 'package:fitlyfe_frontend/widgets/language_selector.dart';
import 'package:fitlyfe_frontend/widgets/rest_timer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// The app's MaterialApp setup: the locale comes from [LocaleProvider].
  Widget app(LocaleProvider localeProvider, Widget home) {
    return ChangeNotifierProvider.value(
      value: localeProvider,
      child: Consumer<LocaleProvider>(
        builder: (context, provider, _) => MaterialApp(
          locale: provider.locale,
          supportedLocales: LocaleProvider.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: home),
        ),
      ),
    );
  }

  Future<AppLocalizations> l10nFor(String code) =>
      AppLocalizations.delegate.load(Locale(code));

  testWidgets('screens render in the chosen language', (tester) async {
    final localeProvider = LocaleProvider();
    await localeProvider.setLocale(const Locale('es'));

    await tester.pumpWidget(app(localeProvider, const RestTimerWidget()));

    expect(find.text('Selección Rápida'), findsOneWidget);
    expect(find.text('Quick Select'), findsNothing);
  });

  testWidgets('picking a language in the selector switches the app', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final localeProvider = LocaleProvider();
    await tester.pumpWidget(app(
      localeProvider,
      const Column(children: [Expanded(child: LanguageSelector()), RestTimerWidget()]),
    ));
    expect(find.text('Quick Select'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(localeProvider.locale, const Locale('de'));
    expect(find.text('Schnellauswahl'), findsOneWidget);
    expect(find.text('Systemsprache'), findsOneWidget);
  });

  test('an unsupported phone language falls back to English', () {
    final resolved = basicLocaleListResolution(
      [const Locale('ja', 'JP')],
      LocaleProvider.supportedLocales,
    );
    expect(resolved.languageCode, 'en');
  });

  test('age uses the plural form', () async {
    final en = await l10nFor('en');
    final de = await l10nFor('de');
    expect(en.yearsOld(1), '1 year old');
    expect(en.yearsOld(29), '29 years old');
    expect(de.yearsOld(29), '29 Jahre alt');
  });

  test('goal messages insert the translated goal', () async {
    final fr = await l10nFor('fr');
    expect(fr.goalUpdatedTo(fr.goalLabel('lose_weight')), 'Objectif mis à jour : ${fr.loseWeight}');
  });

  test('goalLabel accepts both stored goal formats', () async {
    final es = await l10nFor('es');
    expect(es.goalLabel('Build Muscle'), es.buildMuscle);
    expect(es.goalLabel('build_muscle'), es.buildMuscle);
    expect(es.goalLabel('Improve Endurance'), es.improveEndurance);
    expect(es.goalLabel('stay_fit'), es.stayFit);
    expect(es.goalLabel('Something custom'), 'Something custom');
  });

  test('units are not garbled', () async {
    for (final code in ['en', 'es', 'fr', 'de']) {
      expect((await l10nFor(code)).kg, 'KG', reason: code);
    }
  });
}
