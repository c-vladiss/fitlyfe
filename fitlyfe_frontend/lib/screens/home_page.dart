import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:fitlyfe_frontend/models/workout.dart';
import 'package:fitlyfe_frontend/models/progress.dart';
import 'package:fitlyfe_frontend/providers/nutrition_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/circular_progress_card.dart';
import 'package:fitlyfe_frontend/widgets/goal_progress_card.dart';
import 'package:fitlyfe_frontend/screens/profile_page.dart';

import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import 'package:fitlyfe_frontend/l10n/l10n_extensions.dart';
import 'package:fitlyfe_frontend/providers/health_provider.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    final l10n = AppLocalizations.of(context);
    final user = appState.currentUser;

    final caloriesConsumed = nutritionProvider.todayCalories;
    final isCaloriesOver = caloriesConsumed > user.dailyCalorieGoal;
    final caloriesValueToShow = isCaloriesOver 
        ? (caloriesConsumed - user.dailyCalorieGoal).toInt() 
        : (user.dailyCalorieGoal - caloriesConsumed).toInt();
    final caloriesLabel = isCaloriesOver ? 'Over Goal' : l10n.remaining;
    final caloriesProgress = caloriesConsumed / user.dailyCalorieGoal;

    final healthProvider = Provider.of<HealthProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final progressProvider = Provider.of<ProgressProvider>(context);

    final dailyGoals = progressProvider.goals
        .where((g) => g.category == 'Daily')
        .toList();

    final steps = healthProvider.steps;
    final stepsProgress = steps / user.dailyStepGoal;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, user, l10n),
              const SizedBox(height: 16),

              if (!healthProvider.isAuthorized && !healthProvider.isLoading)
                _buildHealthAuthBanner(context, healthProvider, l10n),

              const SizedBox(height: 32),

              // Daily Progress Cards
              _buildProgressCards(
                context,
                appState,
                l10n,
                caloriesProgress,
                caloriesValueToShow,
                isCaloriesOver,
                caloriesLabel,
                stepsProgress,
                steps,
              ),
              const SizedBox(height: 32),

              // Today's Goals (Now showing progress goals)
              _buildDailyGoals(context, dailyGoals, l10n),
              const SizedBox(height: 32),

              // My Primary Goal section
              _buildGoalSection(
                context,
                user.goal,
                l10n,
                workoutProvider.routines,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic user,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FitLyfe',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.accentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.welcomeBack}, ${user.name.split(' ').first}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Row(
          children: [
            if (user.streakCount > 0)
              Tooltip(
                message: l10n.streakTooltip,
                preferBelow: true,
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppTheme.accentOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.streakCount.toString(),
                        style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentGreen, width: 2),
                  color: AppTheme.cardBackground,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCards(
    BuildContext context,
    AppState appState,
    AppLocalizations l10n,
    double caloriesProgress,
    int caloriesValue,
    bool isCaloriesOver,
    String caloriesLabel,
    double stepsProgress,
    int steps,
  ) {
    return Row(
      children: [
        Expanded(
          child: CircularProgressCard(
            value: caloriesProgress,
            mainValue: caloriesValue,
            label: caloriesLabel,
            unit: 'KCAL',
            color: isCaloriesOver ? Colors.redAccent : AppTheme.accentGreen,
            icon: Icons.local_fire_department,
            isWarning: isCaloriesOver,
            onTap: () {
              appState.setProgressMetricIndex(0); // Set to calories
              appState.setPageIndex(1); // Navigate to nutrition page
            },
            actionText: l10n.viewMeals,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CircularProgressCard(
            value: stepsProgress,
            mainValue: steps,
            label: l10n.steps,
            unit: '',
            color: AppTheme.accentBlue,
            icon: Icons.directions_walk,
            onTap: () {
              appState.setProgressMetricIndex(1); // Set to steps
              appState.setPageIndex(3); // Navigate to progress page
            },
            actionText: l10n.viewStats,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoals(
    BuildContext context,
    List<Goal> goals,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dailyGoals,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...goals.map((goal) {
          IconData icon;
          if (goal.title.toLowerCase().contains('step')) {
            icon = Icons.directions_walk;
          } else if (goal.title.toLowerCase().contains('water')) {
            icon = Icons.local_drink;
          } else if (goal.title.toLowerCase().contains('meal')) {
            icon = Icons.restaurant;
          } else {
            icon = Icons.check_circle_outline;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GoalProgressCard(
              icon: icon,
              label: goal.title,
              current: goal.currentValue.toInt(),
              target: goal.targetValue.toInt(),
              unit: goal.isBoolean
                  ? ''
                  : '', // Could expand unit logic if needed
              color: AppTheme.accentGreen,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGoalSection(
    BuildContext context,
    String goal,
    AppLocalizations l10n,
    List<WorkoutRoutine> routines,
  ) {
    Map<String, dynamic> goalContent = _getGoalContent(goal, l10n);
    List<String> tips = goalContent['tips'];
    final translatedGoal = l10n.goalLabel(goal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${l10n.yourGoal}: $translatedGoal",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.accentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.star, color: AppTheme.accentYellow),
          ],
        ),
        const SizedBox(height: 16),

        // Tips Section
        Text(
          l10n.expertTips,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: AppTheme.accentYellow,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Recommended Playlists
        Text(
          l10n.recommendedForYou,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return GestureDetector(
                onTap: () {
                  final workoutProvider = Provider.of<WorkoutProvider>(
                    context,
                    listen: false,
                  );
                  workoutProvider.setCurrentRoutine(routine);
                  Provider.of<AppState>(
                    context,
                    listen: false,
                  ).setPageIndex(2); // Go to Logbook
                },
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        routine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${routine.exercises.length} Exercises',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AppTheme.accentGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${routine.estimatedDuration.inMinutes}m',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHealthAuthBanner(
    BuildContext context,
    HealthProvider healthProvider,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.connectHealthTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  l10n.connectHealthDesc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => healthProvider.requestAuthorization(),
            child: Text(l10n.connect),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getGoalContent(String goal, AppLocalizations l10n) {
    // Accept stored keys ("lose_weight") as well as labels ("Lose Weight")
    switch (goal.trim().toLowerCase().replaceAll(' ', '_')) {
      case 'lose_weight':
        return {
          'tips': [
            l10n.tipDeficit,
            l10n.tipProtein,
            l10n.tipVeggies,
          ],
          'exercises': [
            {
              'name': l10n.exBurpeesName,
              'desc': l10n.exBurpeesDesc,
              'icon': Icons.flash_on,
            },
            {
              'name': l10n.exJumpRopeName,
              'desc': l10n.exJumpRopeDesc,
              'icon': Icons.timer,
            },
            {
              'name': l10n.exSprintingName,
              'desc': l10n.exSprintingDesc,
              'icon': Icons.run_circle,
            },
          ],
        };
      case 'build_muscle':
        return {
          'tips': [
            l10n.tipOverload,
            l10n.tipSleep,
            l10n.tipProteinKg,
          ],
          'exercises': [
            {
              'name': l10n.exSquatsName,
              'desc': l10n.exSquatsDesc,
              'icon': Icons.fitness_center,
            },
            {
              'name': l10n.exDeadliftsName,
              'desc': l10n.exDeadliftsDesc,
              'icon': Icons.fitness_center,
            },
            {
              'name': l10n.exBenchPressName,
              'desc': l10n.exBenchPressDesc,
              'icon': Icons.fitness_center,
            },
          ],
        };
      case 'improve_endurance':
        return {
          'tips': [
            l10n.tipMileage,
            l10n.tipInterval,
            l10n.tipHydration,
          ],
          'exercises': [
            {
              'name': l10n.exRunningName,
              'desc': l10n.exRunningDesc,
              'icon': Icons.directions_run,
            },
            {
              'name': l10n.exCyclingName,
              'desc': l10n.exCyclingDesc,
              'icon': Icons.directions_bike,
            },
            {
              'name': l10n.exSwimmingName,
              'desc': l10n.exSwimmingDesc,
              'icon': Icons.pool,
            },
          ],
        };
      default: // Stay Fit
        return {
          'tips': [
            l10n.tipHolistic,
            l10n.tipNeat,
            l10n.tipWholeFoods,
          ],
          'exercises': [
            {
              'name': l10n.exYogaName,
              'desc': l10n.exYogaDesc,
              'icon': Icons.self_improvement,
            },
            {
              'name': l10n.exPlankName,
              'desc': l10n.exPlankDesc,
              'icon': Icons.accessibility_new,
            },
            {
              'name': l10n.exHikingName,
              'desc': l10n.exHikingDesc,
              'icon': Icons.terrain,
            },
          ],
        };
    }
  }
}
