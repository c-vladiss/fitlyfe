import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/providers/health_provider.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';
import 'package:fitlyfe_frontend/screens/home_page.dart';
import 'package:fitlyfe_frontend/screens/nutrition_page.dart';
import 'package:fitlyfe_frontend/screens/workout_page.dart';
import 'package:fitlyfe_frontend/screens/progress_page.dart';
import 'package:fitlyfe_frontend/screens/ai_assistant_page.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/top_notification.dart';
import 'dart:async';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late AppState _appState;
  StreamSubscription? _completionSubscription;
  final List<String> _notificationQueue = [];
  String? _activeNotification;

  final List<Widget> _pages = [
    const HomePage(),
    const NutritionPage(),
    const WorkoutPage(),
    const ProgressPage(),
    const AIAssistantPage(),
  ];

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);

    // Initialize health data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final healthProvider = Provider.of<HealthProvider>(
        context,
        listen: false,
      );
      final progressProvider = Provider.of<ProgressProvider>(
        context,
        listen: false,
      );

      healthProvider.initialize().then((_) {
        if (healthProvider.isAuthorized) {
          progressProvider.syncHealthData(
            healthProvider.steps,
            healthProvider.activeMinutes,
          );
        }
      });

      // Also listen for updates (e.g. after manual refresh or authorization)
      healthProvider.addListener(() {
        if (healthProvider.isAuthorized) {
          progressProvider.syncHealthData(
            healthProvider.steps,
            healthProvider.activeMinutes,
          );
        }
      });
      // Listen for goal/achievement completions
      _completionSubscription = progressProvider.completionStream.listen((
        message,
      ) {
        _queueNotification(message);
      });

      // Trigger "First Step" achievement on first login/entry
      Future.delayed(const Duration(seconds: 2), () {
        _appState.checkStreak();
        progressProvider.unlockAchievement('b1');

        // Trigger streak achievements
        if (_appState.currentUser.streakCount >= 3) {
          progressProvider.unlockAchievement('b6');
        }
      });
    });
  }

  void _queueNotification(String message) {
    setState(() {
      if (_activeNotification == null) {
        _activeNotification = message;
      } else {
        _notificationQueue.add(message);
      }
    });
  }

  void _onNotificationDismissed() {
    setState(() {
      if (_notificationQueue.isNotEmpty) {
        _activeNotification = _notificationQueue.removeAt(0);
      } else {
        _activeNotification = null;
      }
    });
  }

  @override
  void dispose() {
    _completionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final tp = Provider.of<TranslationProvider>(context);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: appState.selectedPageIndex,
            children: _pages,
          ),
          if (_activeNotification != null)
            TopNotification(
              key: ValueKey(_activeNotification),
              message: _activeNotification!,
              onDismiss: _onNotificationDismissed,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 80,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  Icons.home_outlined,
                  Icons.home,
                  0,
                  tp.translate('home'),
                  appState,
                ),
                _buildNavItem(
                  Icons.local_fire_department_outlined,
                  Icons.local_fire_department,
                  1,
                  tp.translate('nutrition'),
                  appState,
                ),
                _buildNavItem(
                  Icons.fitness_center_outlined,
                  Icons.fitness_center,
                  2,
                  tp.translate('workout'),
                  appState,
                ),
                _buildNavItem(
                  Icons.bar_chart_outlined,
                  Icons.bar_chart,
                  3,
                  tp.translate('progress'),
                  appState,
                ),
                _buildNavItem(
                  Icons.auto_awesome_outlined,
                  Icons.auto_awesome,
                  4,
                  tp.translate('ai'),
                  appState,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData outlineIcon,
    IconData filledIcon,
    int index,
    String label,
    AppState appState,
  ) {
    final isSelected = appState.selectedPageIndex == index;
    return Tooltip(
      message: label,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          appState.setPageIndex(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(isSelected ? 14 : 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentGreen : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accentGreen.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected
                  ? AppTheme.backgroundColor
                  : AppTheme.secondaryText,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
