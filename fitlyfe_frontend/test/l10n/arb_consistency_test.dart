import 'dart:convert';
import 'dart:io';

import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every shipped language must translate every string, so users never see a
/// mix of languages. Partial translations live in l10n_incomplete/ until done.
void main() {
  final arbDir = Directory('lib/l10n');
  Map<String, dynamic> readArb(File f) => jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

  final template = readArb(File('lib/l10n/app_en.arb'));
  final templateKeys = template.keys.where((k) => !k.startsWith('@')).toSet();
  final arbFiles = arbDir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList();

  /// Placeholder names used in a message, e.g. {goal} or the argument of a plural.
  Set<String> placeholders(String message) => RegExp(r'\{(\w+)[,}]').allMatches(message).map((m) => m.group(1)!).toSet();

  test('every ARB file is a supported locale and vice versa', () {
    final arbLocales = arbFiles.map((f) => readArb(f)['@@locale'] as String).toSet();
    final supported = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(arbLocales, supported);
    expect(supported, containsAll(['en', 'es', 'fr', 'de']));
  });

  for (final file in arbFiles) {
    final name = file.uri.pathSegments.last;
    group(name, () {
      final arb = readArb(file);
      final keys = arb.keys.where((k) => !k.startsWith('@')).toSet();

      test('@@locale matches the file name', () {
        expect(name, 'app_${arb['@@locale']}.arb');
      });

      test('has exactly the template keys', () {
        expect(templateKeys.difference(keys), isEmpty, reason: 'missing translations');
        expect(keys.difference(templateKeys), isEmpty, reason: 'keys not in app_en.arb');
      });

      test('has no empty messages', () {
        for (final key in keys) {
          expect((arb[key] as String).trim(), isNotEmpty, reason: key);
        }
      });

      test('uses the same placeholders as the template', () {
        for (final key in keys) {
          expect(
            placeholders(arb[key] as String),
            placeholders(template[key] as String),
            reason: key,
          );
        }
      });
    });
  }

  test('every placeholder in the template is declared', () {
    for (final key in templateKeys) {
      final used = placeholders(template[key] as String);
      if (used.isEmpty) continue;
      final declared = ((template['@$key'] as Map?)?['placeholders'] as Map?)?.keys.toSet() ?? {};
      expect(declared, used, reason: key);
    }
  });
}
