import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_stategy.dart';

class AppleAuthStrategy implements AuthStategy {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> signIn() async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
        // Web and Android: Supabase-managed OAuth redirect
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: _redirectUri(),
        );
        return;
      }

      // iOS/macOS: native Apple Sign-In dialog
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Apple identity token not found');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } catch (e, stack) {
      debugPrint('Apple sign-in error: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  /// Handles Supabase OAuth callbacks for web and Android redirect flows.
  /// No-op on iOS/macOS since the native dialog does not use deep links.
  @override
  Future<void> handleDeepLink(Uri uri) async {
    try {
      if (!_isSupabaseCallback(uri)) return;
      await _supabase.auth.getSessionFromUrl(uri);
    } catch (e, stack) {
      debugPrint('Apple deep link error: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e, stack) {
      debugPrint('Apple sign-out error: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  bool _isSupabaseCallback(Uri uri) {
    final params = Uri.splitQueryString(uri.fragment);
    return params.containsKey('access_token') ||
        params.containsKey('refresh_token');
  }

  String _redirectUri() {
    return kIsWeb
        ? 'https://yourwebapp.com/login-callback'
        : 'fitlyfe_frontend://login-callback';
  }
}
