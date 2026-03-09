import 'package:fitlyfe_frontend/models/user.dart';
import 'package:fitlyfe_frontend/services/graphql_service.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

// Re-export for convenience so callers don't need to import graphql_service.dart.
export 'package:fitlyfe_frontend/services/graphql_service.dart'
    show BackendNetworkException, BackendSyncException;

class AppState extends ChangeNotifier {
  final GraphQLService _graphQLService;

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

  AppState({GraphQLService? graphQLService})
      : _graphQLService = graphQLService ?? GraphQLService();

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

      // Determine display name: prefer profile displayName, then OAuth name
      final oauthName = [result.firstName, result.lastName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ')
          .trim();
      final profileDisplayName = result.profile?.displayName;
      final displayName = (profileDisplayName?.isNotEmpty == true)
          ? profileDisplayName!
          : (oauthName.isNotEmpty ? oauthName : _currentUser.name);

      // Calculate age from date-of-birth if available
      int age = _currentUser.age;
      final profileDateOfBirth = result.profile?.dateOfBirth;
      if (profileDateOfBirth != null) {
        final dob = DateTime.tryParse(profileDateOfBirth);
        if (dob != null) {
          age = _calculateAge(dob);
        }
      }

      _currentUser = _currentUser.copyWith(
        id: result.id,
        email: result.email,
        name: displayName,
        height: result.profile?.heightCm ?? _currentUser.height,
        weight: result.profile?.weightKg ?? _currentUser.weight,
        age: age,
        goal: result.profile?.goal ?? _currentUser.goal,
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
  /// Updates state optimistically so navigation fires immediately; the backend
  /// call completes in the background.
  Future<void> completeOnboarding() async {
    _requiresOnboarding = false;
    notifyListeners();
    try {
      await _graphQLService.completeOnboarding();
    } catch (e) {
      debugPrint('completeOnboarding backend sync failed: $e');
    }
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Updates the local user profile and fire-and-forgets a sync to the backend.
  /// Pass [dateOfBirth] (from onboarding) to store the precise DOB; when only
  /// [age] is provided (profile page edits), an approximate DOB is derived.
  void updateUserProfile({
    String? name,
    String? email,
    double? weight,
    double? height,
    int? age,
    String? goal,
    DateTime? dateOfBirth,
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
    _syncProfileToBackend(
      name: name,
      height: height,
      weight: weight,
      age: age,
      goal: goal,
      dateOfBirth: dateOfBirth,
    );
  }

  Future<void> _syncProfileToBackend({
    String? name,
    double? height,
    double? weight,
    int? age,
    String? goal,
    DateTime? dateOfBirth,
  }) async {
    // Skip sync if there's nothing to update or no session
    if (_session == null) return;
    if (name == null &&
        height == null &&
        weight == null &&
        age == null &&
        goal == null &&
        dateOfBirth == null) {
      return;
    }

    try {
      // Use precise DOB if provided; otherwise derive approximate DOB from age
      DateTime? dob = dateOfBirth;
      if (dob == null && age != null) {
        dob = DateTime(DateTime.now().year - age, 1, 1);
      }
      final dobStr = dob != null
          ? '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}'
          : null;

      await _graphQLService.updateUserProfile(
        displayName: name,
        heightCm: height,
        weightKg: weight,
        dateOfBirth: dobStr,
        goal: goal,
      );
    } catch (e) {
      debugPrint('Profile backend sync failed: $e');
    }
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

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
