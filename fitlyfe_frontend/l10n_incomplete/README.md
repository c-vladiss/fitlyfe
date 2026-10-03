# Incomplete translations

These languages were partly translated in the old hand-written
`TranslationProvider` (about 30 of the app's ~145 strings each). They are kept
here so the work isn't lost, but they are **not shipped**: a half-translated
language shows users a mix of their language and English.

To ship a language:

1. Copy `app_<code>.arb` into `lib/l10n/`.
2. Translate every key in `lib/l10n/app_en.arb` (read its `@key` descriptions
   for context and keep `{placeholders}` unchanged).
3. Add its native name to `LocaleProvider.nativeName`.
4. Run `flutter gen-l10n` and `flutter test test/l10n` — the consistency test
   fails until every key is translated.
