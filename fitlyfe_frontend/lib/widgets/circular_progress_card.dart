import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fitlyfe_frontend/theme/app_theme.dart';

class CircularProgressCard extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final int mainValue;
  final String label;
  final String unit;
  final Color color;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onTap;
  final bool isWarning;

  const CircularProgressCard({
    super.key,
    required this.value,
    required this.mainValue,
    required this.label,
    required this.unit,
    required this.color,
    this.icon,
    this.actionText,
    this.onTap,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          backgroundColor: AppTheme.cardBackground,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            color.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      // Progress circle
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Transform.rotate(
                          angle: -math.pi / 2,
                          child: CircularProgressIndicator(
                            value: value.clamp(0.0, 1.0),
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      // Content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isWarning) ...[
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                            const SizedBox(height: 4),
                          ] else if (icon != null) ...[
                            Icon(icon, color: AppTheme.primaryText, size: 20),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            mainValue >= 10000
                                ? '${(mainValue / 1000).toStringAsFixed(1)}k'
                                : mainValue.toString(),
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: isWarning ? Colors.redAccent : AppTheme.primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: mainValue >= 1000 ? 28 : (isWarning ? 26 : 32),
                                ),
                          ),
                          Text(
                            label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isWarning ? Colors.redAccent : AppTheme.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (actionText != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        actionText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: color),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
