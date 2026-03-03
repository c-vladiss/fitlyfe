import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';

class NutritionDetailsPage extends StatelessWidget {
  final double caloriesConsumed;
  final double caloriesGoal;

  const NutritionDetailsPage({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryText),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.secondaryText.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Eaten
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.ramen_dining,
                            color: AppTheme.accentGreen,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Eaten',
                              style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${caloriesConsumed.toInt()} kcal',
                              style: const TextStyle(color: AppTheme.primaryText, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    Divider(color: AppTheme.secondaryText.withValues(alpha: 0.2)),
                    const SizedBox(height: 24),
                    
                    // Burned
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: AppTheme.accentOrange,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Burned',
                              style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '0 kcal', // Burned is currently static 0
                              style: TextStyle(color: AppTheme.primaryText, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
