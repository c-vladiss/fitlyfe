import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';

extension GoalLabels on AppLocalizations {
  /// Translated label for a fitness goal.
  ///
  /// Goals are stored both as labels ("Lose Weight", from onboarding) and as
  /// keys ("lose_weight", from the profile page), so accept either form.
  /// Unknown goals are shown as stored.
  String goalLabel(String goal) {
    return switch (goal.trim().toLowerCase().replaceAll(' ', '_')) {
      'lose_weight' => loseWeight,
      'build_muscle' => buildMuscle,
      'improve_endurance' => improveEndurance,
      'stay_fit' => stayFit,
      _ => goal,
    };
  }
}
