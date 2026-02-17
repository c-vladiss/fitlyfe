import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/models/progress.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context);
    final tp = Provider.of<TranslationProvider>(context);
    final goals = progressProvider.goals;

    final categories = ['Daily', 'Workout', 'Health', 'Habit', 'Challenge'];
    final categoryIcons = {
      'Daily': Icons.today,
      'Workout': Icons.fitness_center,
      'Health': Icons.favorite,
      'Habit': Icons.repeat,
      'Challenge': Icons.emoji_events,
    };
    final categoryColors = {
      'Daily': AppTheme.accentOrange,
      'Workout': AppTheme.accentBlue,
      'Health': AppTheme.accentRed,
      'Habit': AppTheme.accentPurple,
      'Challenge': AppTheme.accentYellow,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(tp.translate('goals')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.map((cat) {
            final catGoals = goals.where((g) => g.category == cat).toList();
            if (catGoals.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(categoryIcons[cat], color: categoryColors[cat], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        cat == 'Daily' ? '🔥 Daily Goals' : 
                        cat == 'Workout' ? '💪 Workout Goals' :
                        cat == 'Health' ? '❤️ Health Goals' :
                        cat == 'Habit' ? '📅 Habit Goals' :
                        '🧭 Challenge Goals',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: categoryColors[cat],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...catGoals.map((goal) => _buildGoalItem(context, goal, progressProvider)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, Goal goal, ProgressProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: goal.isCompleted 
            ? Border.all(color: AppTheme.accentGreen.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.toggleGoalStatus(goal.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: goal.isCompleted ? AppTheme.accentGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: goal.isCompleted ? AppTheme.accentGreen : AppTheme.secondaryText,
                  width: 2,
                ),
              ),
              child: goal.isCompleted 
                  ? const Icon(Icons.check, size: 16, color: AppTheme.backgroundColor)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                    color: goal.isCompleted ? AppTheme.secondaryText : AppTheme.primaryText,
                  ),
                ),
                if (!goal.isBoolean && !goal.isCompleted) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      backgroundColor: AppTheme.backgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal.progress > 0.8 ? AppTheme.accentGreen : AppTheme.accentBlue,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
