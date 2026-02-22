import 'package:fitlyfe_frontend/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the backend server cannot be reached (network/connection error).
class BackendNetworkException implements Exception {
  final String message;
  const BackendNetworkException(this.message);
  @override
  String toString() => 'BackendNetworkException: $message';
}

/// Thrown when the backend rejects the request (auth failure, bad response, etc.).
class BackendSyncException implements Exception {
  final String message;
  const BackendSyncException(this.message);
  @override
  String toString() => 'BackendSyncException: $message';
}

class GraphQLService {
  late GraphQLClient _client;

  GraphQLService() {
    final HttpLink httpLink = HttpLink(AppConfig.apiUrl);

    // Reads the Supabase access token directly from the active session.
    // This token is the JWT the backend validates against Supabase's JWKS.
    final AuthLink authLink = AuthLink(
      getToken: () {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        return token != null ? 'Bearer $token' : null;
      },
    );

    _client = GraphQLClient(
      link: authLink.concat(httpLink),
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  /// Called immediately after Supabase sign-in.
  /// Upserts the user on the backend and returns whether onboarding is needed.
  ///
  /// Throws [BackendNetworkException] if the server cannot be reached.
  /// Throws [BackendSyncException] if the server rejects the request (e.g. 401).
  Future<SyncUserResult> syncUser() async {
    // Debug: confirm that a Supabase token will be sent with the request.
    if (kDebugMode) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      debugPrint(
        'syncUser: Supabase token is ${token == null ? "NULL — request will have no Bearer header" : "present (${token.substring(0, 20)}...)"}',
      );
    }

    const String mutation = r'''
      mutation SyncUser {
        syncUser {
          id
          email
          firstName
          lastName
          requiresOnboarding
          profile {
            heightCm
            weightKg
            dateOfBirth
            goal
            displayName
          }
        }
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(document: gql(mutation)),
    );

    if (result.hasException) {
      final ex = result.exception!;
      debugPrint('GraphQL syncUser error: $ex');

      // NetworkException = connection refused / no internet / DNS failure.
      // Anything else (ResponseFormatException = non-JSON 401/403, etc.) is
      // treated as the backend rejecting the request.
      if (ex.linkException is NetworkException) {
        throw BackendNetworkException(ex.toString());
      }
      throw BackendSyncException(ex.toString());
    }

    final data = result.data?['syncUser'];
    if (data == null) {
      throw BackendSyncException('syncUser mutation returned null data');
    }

    final profileData = data['profile'] as Map<String, dynamic>?;

    return SyncUserResult(
      id: data['id'] as String,
      email: data['email'] as String,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      requiresOnboarding: data['requiresOnboarding'] as bool,
      profileHeightCm: profileData?['heightCm'] as double?,
      profileWeightKg: profileData?['weightKg'] as double?,
      profileDateOfBirth: profileData?['dateOfBirth'] as String?,
      profileGoal: profileData?['goal'] as String?,
      profileDisplayName: profileData?['displayName'] as String?,
    );
  }

  /// Called at the end of the onboarding flow to mark it complete on the backend.
  Future<bool> completeOnboarding() async {
    const String mutation = r'''
      mutation CompleteOnboarding {
        completeOnboarding
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(document: gql(mutation)),
    );

    if (result.hasException) {
      debugPrint('GraphQL completeOnboarding error: ${result.exception}');
      return false;
    }

    return result.data?['completeOnboarding'] as bool? ?? false;
  }

  /// Saves or updates the user's fitness profile on the backend.
  /// All fields are optional — only non-null values are sent.
  Future<void> updateUserProfile({
    String? displayName,
    double? heightCm,
    double? weightKg,
    String? dateOfBirth,
    String? goal,
  }) async {
    const String mutation = r'''
      mutation UpdateUserProfile($input: UpdateUserProfileInput!) {
        updateUserProfile(input: $input) {
          heightCm
          weightKg
          dateOfBirth
          goal
          displayName
        }
      }
    ''';

    final input = <String, dynamic>{};
    if (displayName != null) input['displayName'] = displayName;
    if (heightCm != null) input['heightCm'] = heightCm;
    if (weightKg != null) input['weightKg'] = weightKg;
    if (dateOfBirth != null) input['dateOfBirth'] = dateOfBirth;
    if (goal != null) input['goal'] = goal;

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'input': input},
      ),
    );

    if (result.hasException) {
      debugPrint('GraphQL updateUserProfile error: ${result.exception}');
      throw BackendSyncException(result.exception.toString());
    }
  }
}

class SyncUserResult {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool requiresOnboarding;
  // Profile fields — null if the user hasn't completed onboarding yet
  final double? profileHeightCm;
  final double? profileWeightKg;
  final String? profileDateOfBirth;
  final String? profileGoal;
  final String? profileDisplayName;

  const SyncUserResult({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.requiresOnboarding,
    this.profileHeightCm,
    this.profileWeightKg,
    this.profileDateOfBirth,
    this.profileGoal,
    this.profileDisplayName,
  });
}
