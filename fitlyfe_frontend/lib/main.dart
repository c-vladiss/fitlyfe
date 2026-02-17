import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/providers/health_provider.dart';
import 'package:fitlyfe_frontend/providers/locale_provider.dart';

import 'package:fitlyfe_frontend/config/app_config.dart';
import 'package:fitlyfe_frontend/screens/welcome_screen.dart';
import 'package:fitlyfe_frontend/screens/onboarding_screen.dart';
import 'package:fitlyfe_frontend/screens/main_screen.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/auth/google_auth_strategy.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.validate();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await GoogleAuthStrategy.initialize();

  final appState = AppState();

  // 🔐 Listen to auth changes ONCE (outside widget tree)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    appState.onAuthStateChange(data);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const FitLyfeApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class FitLyfeApp extends StatefulWidget {
  const FitLyfeApp({super.key});

  @override
  State<FitLyfeApp> createState() => _FitLyfeAppState();
}

class _FitLyfeAppState extends State<FitLyfeApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  final _googleAuth = GoogleAuthStrategy();
  StreamSubscription? _deepLinkSubscription;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: false);
    if (_appState != appState) {
      _appState?.removeListener(_onAppStateChanged);
      _appState = appState;
      _appState!.addListener(_onAppStateChanged);
    }
  }

  void _onAppStateChanged() {
    if (_appState!.syncFailed) {
      _appState!.resetSyncFailed();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _navigatorKey.currentContext;
        if (ctx == null) return;
        final errorMessage = _appState!.syncErrorMessage ??
            'Could not connect to the server. Please try again.';
        showDialog<void>(
          context: ctx,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: const Text('Sign-In Failed'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _googleAuth.handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Initial deep link error: $e');
    }

    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        await _googleAuth.handleDeepLink(uri);
      },
      onError: (error) {
        debugPrint('Deep link stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _appState?.removeListener(_onAppStateChanged);
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Widget _resolveHome(AppState appState) {
    if (!appState.isAuthenticated) return const WelcomeScreen();

    // Show a minimal loading screen while the backend syncUser call is in flight
    if (appState.isSyncing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (appState.requiresOnboarding) return const OnboardingScreen();

    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, LocaleProvider>(
      builder: (context, appState, localeProvider, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'FitLyfe',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          theme: AppTheme.getTheme(appState.themeColor),
          supportedLocales: L10n.all,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _resolveHome(appState),
        );
      },
    );
  }
}
