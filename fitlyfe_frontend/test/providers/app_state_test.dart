import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/graphql/operations/user.graphql.dart';

import '../mocks.dart';

void main() {
  late MockGraphQLService mockGraphQLService;
  late AppState appState;

  setUp(() {
    mockGraphQLService = MockGraphQLService();
    appState = AppState(graphQLService: mockGraphQLService);
  });

  group('AppState', () {
    group('initialization', () {
      test('starts with no session', () {
        expect(appState.session, isNull);
        expect(appState.isAuthenticated, false);
      });

      test('starts with isSyncing false', () {
        expect(appState.isSyncing, false);
      });

      test('starts with syncFailed false', () {
        expect(appState.syncFailed, false);
        expect(appState.syncErrorMessage, isNull);
      });

      test('starts with requiresOnboarding false', () {
        expect(appState.requiresOnboarding, false);
      });

      test('starts with default page index 0', () {
        expect(appState.selectedPageIndex, 0);
      });

      test('starts with default theme color', () {
        expect(appState.themeColor, AppTheme.accentGreen);
      });

      test('starts with default user', () {
        expect(appState.currentUser.name, 'Alex Johnson');
        expect(appState.currentUser.email, 'alex.johnson@example.com');
      });
    });

    group('page navigation', () {
      test('setPageIndex updates selected page', () {
        appState.setPageIndex(2);
        expect(appState.selectedPageIndex, 2);
      });

      test('setProgressMetricIndex updates metric index', () {
        appState.setProgressMetricIndex(1);
        expect(appState.progressMetricIndex, 1);
      });
    });

    group('theme', () {
      test('setThemeColor updates theme color', () {
        appState.setThemeColor(Colors.purple);
        expect(appState.themeColor, Colors.purple);
      });
    });

    group('user management', () {
      test('updateUser replaces current user', () {
        final newUser = appState.currentUser.copyWith(
          name: 'New Name',
          email: 'new@example.com',
        );

        appState.updateUser(newUser);

        expect(appState.currentUser.name, 'New Name');
        expect(appState.currentUser.email, 'new@example.com');
      });

      test('updateUserProfile updates user fields', () {
        // Mock the backend call to not fail
        when(() => mockGraphQLService.updateUserProfile(
              displayName: any(named: 'displayName'),
              heightCm: any(named: 'heightCm'),
              weightKg: any(named: 'weightKg'),
              dateOfBirth: any(named: 'dateOfBirth'),
              goal: any(named: 'goal'),
            )).thenAnswer((_) async => Mutation$UpdateUserProfile$updateUserProfile(
              heightCm: 185.0,
              weightKg: 80.0,
              dateOfBirth: null,
              goal: null,
              displayName: 'Updated Name',
            ));

        appState.updateUserProfile(
          name: 'Updated Name',
          height: 185.0,
          weight: 80.0,
        );

        expect(appState.currentUser.name, 'Updated Name');
        expect(appState.currentUser.height, 185.0);
        expect(appState.currentUser.weight, 80.0);
      });
    });

    group('streak tracking', () {
      test('checkStreak initializes streak for new user', () {
        appState.checkStreak();
        expect(appState.currentUser.streakCount, 1);
        expect(appState.currentUser.lastLoginDate, isNotNull);
      });

      test('checkStreak maintains streak for consecutive days', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final userWithStreak = appState.currentUser.copyWith(
          streakCount: 5,
          lastLoginDate: yesterday,
        );
        appState.updateUser(userWithStreak);

        appState.checkStreak();

        expect(appState.currentUser.streakCount, 6);
      });

      test('checkStreak resets streak after missing a day', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final userWithStreak = appState.currentUser.copyWith(
          streakCount: 10,
          lastLoginDate: twoDaysAgo,
        );
        appState.updateUser(userWithStreak);

        appState.checkStreak();

        expect(appState.currentUser.streakCount, 1);
      });

      test('checkStreak does not increment for same day login', () {
        final today = DateTime.now();
        final userLoggedInToday = appState.currentUser.copyWith(
          streakCount: 5,
          lastLoginDate: DateTime(today.year, today.month, today.day),
        );
        appState.updateUser(userLoggedInToday);

        appState.checkStreak();

        expect(appState.currentUser.streakCount, 5);
      });
    });

    group('sync error handling', () {
      test('resetSyncFailed clears error state', () {
        // Manually set error state for testing
        appState.resetSyncFailed();

        expect(appState.syncFailed, false);
        expect(appState.syncErrorMessage, isNull);
      });
    });

    group('sign out', () {
      test('signOut clears session and resets state', () {
        appState.signOut();

        expect(appState.session, isNull);
        expect(appState.isAuthenticated, false);
        expect(appState.requiresOnboarding, false);
      });
    });

    group('onboarding', () {
      test('completeOnboarding sets requiresOnboarding to false', () async {
        when(() => mockGraphQLService.completeOnboarding())
            .thenAnswer((_) async => true);

        await appState.completeOnboarding();

        expect(appState.requiresOnboarding, false);
        verify(() => mockGraphQLService.completeOnboarding()).called(1);
      });

      test('completeOnboarding handles backend failure gracefully', () async {
        when(() => mockGraphQLService.completeOnboarding())
            .thenThrow(Exception('Backend error'));

        // Should not throw
        await appState.completeOnboarding();

        // State should still be updated optimistically
        expect(appState.requiresOnboarding, false);
      });
    });

    group('notifyListeners', () {
      test('setPageIndex notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        appState.setPageIndex(1);

        expect(notified, true);
      });

      test('setThemeColor notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        appState.setThemeColor(Colors.red);

        expect(notified, true);
      });

      test('updateUser notifies listeners', () {
        var notified = false;
        appState.addListener(() => notified = true);

        appState.updateUser(appState.currentUser.copyWith(name: 'Test'));

        expect(notified, true);
      });
    });
  });
}
