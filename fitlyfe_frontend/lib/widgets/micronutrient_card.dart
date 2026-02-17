import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';

class MicronutrientCard extends StatelessWidget {
  final Map<String, double> percentages;
  final Map<String, double> rawValues;
  final Map<String, double> rdis;

  const MicronutrientCard({
    super.key, 
    required this.percentages,
    required this.rawValues,
    required this.rdis, required Map<String, double> nutrients,
  });

  @override
  Widget build(BuildContext context) {
    final nutrientColors = {
      'vitamin_a': AppTheme.accentYellow,
      'vitamin_c': AppTheme.accentOrange,
      'vitamin_d': AppTheme.accentPurple,
      'calcium': AppTheme.accentBlue,
      'iron': AppTheme.accentRed,
      'magnesium': Colors.tealAccent,
    };

    final nutrientLabels = {
      'vitamin_a': 'VITAMIN A',
      'vitamin_c': 'VITAMIN C',
      'vitamin_d': 'VITAMIN D',
      'calcium': 'CALCIUM',
      'iron': 'IRON',
      'magnesium': 'MAGNESIUM',
    };

    final nutrientUnits = {
      'vitamin_a': 'mcg',
      'vitamin_c': 'mg',
      'vitamin_d': 'mcg',
      'calcium': 'mg',
      'iron': 'mg',
      'magnesium': 'mg',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: percentages.entries.map((entry) {
          final percentageValue = entry.value;
          final percentageInt = (percentageValue * 100).toInt();
          final color = nutrientColors[entry.key] ?? AppTheme.accentGreen;
          final label = nutrientLabels[entry.key] ?? entry.key.toUpperCase();
          final rawValue = rawValues[entry.key] ?? 0.0;
          final rdi = rdis[entry.key] ?? 1.0;
          final unit = nutrientUnits[entry.key] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: color,
                          ),
                        ),
                        Text(
                          '${rawValue.toInt()} / ${rdi.toInt()} $unit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$percentageInt%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: percentageValue >= 1.0 ? AppTheme.accentGreen : AppTheme.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: 8,
                          width: constraints.maxWidth * percentageValue.clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
