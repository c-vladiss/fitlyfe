import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../config/app_config.dart';
import 'auth_stategy.dart';

class GoogleAuthStrategy implements AuthStategy {
  final SupabaseClient _supabase = Supabase.instance.client;

  static bool _googleInitialized = false;

  /// Call this once at app startup (recommended)
  static Future<void> initialize() async {
    if (kIsWeb || _googleInitialized) return;

    await gsi.GoogleSignIn.instance.initialize(serverClientId: AppConfig.googleWebClientId);

    _googleInitialized = true;
  }

  @override
  Future<void> signIn() async {
    try {
      if (kIsWeb) {
        // 🌐 Web: Supabase-managed OAuth redirect
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: _redirectUri(),
        );
        return;
      }

      // 📱 Mobile: Native Google Sign-In → Supabase
      await initialize();

      final googleUser = await gsi.GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google ID token not found');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e, stack) {
      debugPrint('Google sign-in error: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  /// Only needed for:
  /// - Web OAuth redirects
  /// - Magic links
  /// - External browser auth flows
  @override
  Future<void> handleDeepLink(Uri uri) async {
    try {
      if (!_isSupabaseCallback(uri)) return;

      await _supabase.auth.getSessionFromUrl(uri);

      final session = _supabase.auth.currentSession;
      final user = session?.user;

      if (user != null) {
        debugPrint('Session established for ${user.email}');
      }
    } on AuthException catch (e) {
      debugPrint('Supabase auth error: ${e.message}');
      rethrow;
    } catch (e, stack) {
      debugPrint('Deep link handling error: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  bool _isSupabaseCallback(Uri uri) {
    final fragment = uri.fragment;
    if (fragment.isEmpty) return false;

    final params = Uri.splitQueryString(fragment);
    return params.containsKey('access_token') ||
        params.containsKey('refresh_token');
  }

  String _redirectUri() {
    return kIsWeb
        ? 'https://yourwebapp.com/login-callback'
        : 'fitlyfe_frontend://login-callback';
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();

      if (!kIsWeb) {
        await gsi.GoogleSignIn.instance.signOut();
      }
    } catch (e, stack) {
      debugPrint('Sign-out error: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }
}
