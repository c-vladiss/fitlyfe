/// Compile-time configuration injected via --dart-define-from-file.
///
/// Usage:
///   flutter run   --dart-define-from-file=config/dev.json
///   flutter build ios --dart-define-from-file=config/prod.json
///
/// Values are baked into the binary at compile time — they are never read
/// from the filesystem at runtime and do not appear as plain strings.
///
/// If a value is missing (e.g. you forgot to pass --dart-define-from-file),
/// the app will throw an assertion at startup rather than silently misbehave.
class AppConfig {
  AppConfig._();

  // ── Supabase ─────────────────────────────────────────────────────────────

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The anon/publishable key. Safe to ship in the binary (Row Level Security
  /// enforces access on Supabase's side), but keep it out of source control.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Web Application OAuth 2.0 Client ID from Google Cloud Console.
  /// Must match the client ID registered in Supabase → Auth → Google.
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// iOS OAuth 2.0 Client ID from Google Cloud Console.
  /// Must be added to Supabase → Auth → Google → Authorized Client IDs.
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  // ── Backend API ───────────────────────────────────────────────────────────

  /// GraphQL endpoint for the FitLyfe backend.
  /// Dev (Android emulator): http://10.0.2.2:8081/graphql
  /// Dev (iOS simulator):    http://127.0.0.1:8081/graphql
  /// Production:             https://api.fitlyfe.com/graphql
  static const String apiUrl = String.fromEnvironment('API_URL');

  // ── Validation ────────────────────────────────────────────────────────────

  /// Call once in main() before runApp() to catch missing config early.
  /// Only fires in debug builds (assert is stripped from release builds).
  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (googleWebClientId.isEmpty) missing.add('GOOGLE_WEB_CLIENT_ID');
    if (googleIosClientId.isEmpty) missing.add('GOOGLE_IOS_CLIENT_ID');
    if (apiUrl.isEmpty) missing.add('API_URL');

    assert(
      missing.isEmpty,
      'Missing required config keys: ${missing.join(', ')}\n'
      'Run with: flutter run --dart-define-from-file=config/dev.json',
    );
  }
}
