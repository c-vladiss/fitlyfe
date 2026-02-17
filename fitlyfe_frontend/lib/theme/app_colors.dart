import 'package:flutter/material.dart';

/// FitLyfe design system colors.
/// Dark mode aesthetic with vibrant lime green accents.
class AppColors {
  AppColors._();

  /// Primary background - dark charcoal
  static const Color background = Color(0xFF121212);

  /// Slightly elevated surfaces (cards, input fields)
  static const Color surface = Color(0xFF2C2C2E);

  /// Vibrant lime green - primary accent, buttons, links, active states
  static const Color primary = Color(0xFF00E676);

  /// Primary text - white for labels and key information
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - lighter grey for placeholders and secondary info
  static const Color textSecondary = Color(0xFF9E9E9E);

  /// Muted grey for borders and dividers
  static const Color border = Color(0xFF424242);

  /// White background for secondary buttons (e.g. Google sign-in)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Dark grey text on light backgrounds (e.g. Google button label)
  static const Color textOnLight = Color(0xFF424242);
}
