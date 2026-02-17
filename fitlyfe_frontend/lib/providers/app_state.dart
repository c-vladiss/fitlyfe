import 'package:fitlyfe_frontend/models/user.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

// Re-export for convenience so callers don't need to import graphql_service.dart.
export 'package:fitlyfe_frontend/services/graphql_service.dart'
    show BackendNetworkException, BackendSyncException;

class AppState extends ChangeNotifier {
  Session? _session;
  Session? get session => _session;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _syncFailed = false;
  bool get syncFailed => _syncFailed;

  String? _syncErrorMessage;
  String? get syncErrorMessage => _syncErrorMessage;

  bool _requiresOnboarding = false;
  bool get requiresOnboarding => _requiresOnboarding;

  int _selectedPageIndex = 0;
  int _progressMetricIndex = 0;
  Color _themeColor = AppTheme.accentGreen;

  bool get isAuthenticated => _session != null;

  final _graphQLService = GraphQLService();

  User _currentUser = User(
    id: '1',
    name: 'Alex Johnson',
    email: 'alex.johnson@example.com',
    weight: 75,
    height: 182,
    age: 24,
    dailyCalorieGoal: 2000,
    dailyStepGoal: 10000,
    dailyActiveTimeGoal: 60,
  );

  User get currentUser => _currentUser;
  int get selectedPageIndex => _selectedPageIndex;
  int get progressMetricIndex => _progressMetricIndex;
  Color get themeColor => _themeColor;

  void setPageIndex(int index) {
    _selectedPageIndex = index;
    notifyListeners();
  }

  void setProgressMetricIndex(int index) {
    _progressMetricIndex = index;
    notifyListeners();
  }

  void setThemeColor(Color color) {
    _themeColor = color;
    notifyListeners();
  }

  void onAuthStateChange(AuthState state) {
    _session = state.session;

    if (_session != null) {
      _syncFailed = false;
      checkStreak();
      _syncWithBackend();
    } else {
      // Signed out — reset routing state
      _requiresOnboarding = false;
      _isSyncing = false;
    }

    notifyListeners();
  }

  Future<void> _syncWithBackend() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _graphQLService.syncUser();
      _requiresOnboarding = result.requiresOnboarding;
      _currentUser = _currentUser.copyWith(
        id: result.id,
        email: result.email,
        name: [result.firstName, result.lastName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ')
            .trim()
            .isEmpty
            ? _currentUser.name
            : [result.firstName, result.lastName]
                .where((s) => s != null && s.isNotEmpty)
                .join(' ')
                .trim(),
      );
    } on BackendNetworkException {
      _syncFailed = true;
      _syncErrorMessage =
          'Could not reach the server. Check your internet connection and that the backend is running.';
      await Supabase.instance.client.auth.signOut();
    } on BackendSyncException {
      _syncFailed = true;
      _syncErrorMessage =
          'The server rejected the login request. This may indicate a backend configuration issue (e.g. missing SUPABASE_URL on the server).';
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Backend sync error: $e');
      _syncFailed = true;
      _syncErrorMessage = 'An unexpected error occurred. Please try again.';
      await Supabase.instance.client.auth.signOut();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Call at the last step of OnboardingScreen to mark onboarding complete.
  Future<void> completeOnboarding() async {
    await _graphQLService.completeOnboarding();
    _requiresOnboarding = false;
    notifyListeners();
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateUserProfile({
    String? name,
    String? email,
    double? weight,
    double? height,
    int? age,
    String? goal,
  }) {
    _currentUser = _currentUser.copyWith(
      name: name,
      email: email,
      weight: weight,
      height: height,
      age: age,
      goal: goal,
    );
    notifyListeners();
  }

  void checkStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = _currentUser.lastLoginDate;

    if (lastLogin == null) {
      _currentUser = _currentUser.copyWith(streakCount: 1, lastLoginDate: today);
    } else {
      final lastLoginDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      final difference = today.difference(lastLoginDay).inDays;

      if (difference == 1) {
        _currentUser = _currentUser.copyWith(
          streakCount: _currentUser.streakCount + 1,
          lastLoginDate: today,
        );
      } else if (difference > 1) {
        _currentUser = _currentUser.copyWith(streakCount: 1, lastLoginDate: today);
      }
      // difference == 0: already logged in today, nothing to update
    }
    notifyListeners();
  }

  /// Silently clear the sync-error state. Called by the UI after it has
  /// consumed the error (e.g. shown the dialog) so it doesn't re-trigger.
  void resetSyncFailed() {
    _syncFailed = false;
    _syncErrorMessage = null;
  }

  void signOut() {
    _session = null;
    _requiresOnboarding = false;
    notifyListeners();
  }
}
