import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/models/progress.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context);
    final tp = Provider.of<TranslationProvider>(context);
    final achievements = progressProvider.achievements;

    final categories = [
      'Beginner',
      'Streak',
      'Performance',
      'Progress',
      'Exploration',
      'Special',
    ];

    final categoryTitles = {
      'Beginner': '🌟 Beginner Milestones',
      'Streak': '🔥 Streak Achievements',
      'Performance': '🚀 Performance Achievements',
      'Progress': '📊 Progress Achievements',
      'Exploration': '🗺️ Exploration Achievements',
      'Special': '🎖️ Special / Rare Achievements',
    };

    final categoryColors = {
      'Beginner': AppTheme.accentYellow,
      'Streak': AppTheme.accentOrange,
      'Performance': AppTheme.accentBlue,
      'Progress': AppTheme.accentGreen,
      'Exploration': AppTheme.accentPurple,
      'Special': AppTheme.accentRed,
    };

    return Scaffold(
      appBar: AppBar(title: Text(tp.translate('achievements'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.map((cat) {
            final catAchievements = achievements
                .where((a) => a.category == cat)
                .toList();
            if (catAchievements.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        categoryTitles[cat] ?? cat,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: categoryColors[cat],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: catAchievements.length,
                  itemBuilder: (context, index) {
                    return _buildAchievementCard(
                      context,
                      catAchievements[index],
                      categoryColors[cat]!,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    Achievement achievement,
    Color categoryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: achievement.isUnlocked
            ? Border.all(
                color: categoryColor.withValues(alpha: 0.5),
                width: 1.5,
              )
            : Border.all(
                color: AppTheme.secondaryText.withValues(alpha: 0.1),
                width: 1,
              ),
        boxShadow: achievement.isUnlocked
            ? [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? categoryColor.withValues(alpha: 0.15)
                  : AppTheme.backgroundColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Opacity(
                opacity: achievement.isUnlocked ? 1.0 : 0.2,
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked
                  ? AppTheme.primaryText
                  : AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: achievement.isUnlocked
                  ? AppTheme.secondaryText
                  : AppTheme.secondaryText.withValues(alpha: 0.5),
            ),
          ),
          if (achievement.isUnlocked) ...[
            const SizedBox(height: 8),
            const Icon(Icons.verified, color: AppTheme.accentGreen, size: 16),
          ],
        ],
      ),
    );
  }
}
