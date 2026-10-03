import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/logout_button.dart';

import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';
import 'package:fitlyfe_frontend/l10n/l10n_extensions.dart';
import 'package:fitlyfe_frontend/providers/locale_provider.dart';
import 'package:fitlyfe_frontend/widgets/language_selector.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final user = appState.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.primaryText,
                  ),
                  Expanded(
                    child: Text(
                      l10n.profile,
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
              const SizedBox(height: 32),

              // User Information Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Profile Picture
                    GestureDetector(
                      onTap: () => _showAvatarSelection(context, appState, l10n),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentGreen.withValues(
                                alpha: 0.2,
                              ),
                              border: Border.all(
                                color: AppTheme.accentGreen.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                              ),
                            ),
                            child: user.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.network(
                                      user.imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.accentGreen,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: AppTheme.backgroundColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Fitness Metrics
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditMetricsDialog(
                              context,
                              appState,
                              l10n,
                              'weight',
                            ),
                            child: _buildMetricCard(
                              context,
                              l10n.weight.toUpperCase(),
                              user.weight.toInt().toString(),
                              'kg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditMetricsDialog(
                              context,
                              appState,
                              l10n,
                              'height',
                            ),
                            child: _buildMetricCard(
                              context,
                              l10n.height.toUpperCase(),
                              user.height.toInt().toString(),
                              'cm',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditMetricsDialog(
                              context,
                              appState,
                              l10n,
                              'age',
                            ),
                            child: _buildMetricCard(
                              context,
                              l10n.age.toUpperCase(),
                              user.age.toString(),
                              'yo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Primary Goal Selector
              GestureDetector(
                onTap: () => _showEditGoalDialog(context, appState, l10n),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.primaryGoal,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondaryText,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.goalLabel(user.goal),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit,
                        color: AppTheme.secondaryText,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Account Section
              _buildSectionHeader(
                context,
                l10n.account.toUpperCase(),
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                context,
                icon: Icons.person_outline,
                title: l10n.personalDetails,
                subtitle: l10n.nameEmail,
                onTap: () => _showEditProfileDialog(context, appState, l10n),
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                context,
                icon: Icons.security,
                title: l10n.privacySecurity,
                subtitle: l10n.password2fa,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy settings are up to date!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Preferences Section
              _buildSectionHeader(
                context,
                l10n.preferences.toUpperCase(),
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                context,
                icon: Icons.notifications_outlined,
                title: l10n.notifications,
                subtitle: l10n.pushEmail,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings updated!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                context,
                icon: Icons.language,
                title: l10n.language,
                subtitle: localeProvider.locale == null
                    ? l10n.languageSystemDefault
                    : LocaleProvider.nativeName(localeProvider.locale!),
                onTap: () => _showLanguageSheet(context, l10n),
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                context,
                icon: Icons.palette_outlined,
                title: l10n.appearance,
                subtitle: l10n.colorTheme,
                onTap: () => _showAppearanceDialog(context, appState, l10n),
              ),
              const SizedBox(height: 12),
              const LogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.language, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const LanguageSelector(),
          ],
        ),
      ),
    );
  }

  void _showAvatarSelection(
    BuildContext context,
    AppState appState,
    AppLocalizations l10n,
  ) {
    final avatars = [
      'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix',
      'https://api.dicebear.com/7.x/avataaars/svg?seed=Anya',
      'https://api.dicebear.com/7.x/avataaars/svg?seed=Jack',
      'https://api.dicebear.com/7.x/avataaars/svg?seed=Luna',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CHOOSE AVATAR',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: avatars
                  .map(
                    (url) => GestureDetector(
                      onTap: () {
                        appState.updateUser(
                          appState.currentUser.copyWith(imageUrl: url),
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentGreen,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.network(url),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    AppState appState,
    AppLocalizations l10n,
  ) {
    final nameController = TextEditingController(
      text: appState.currentUser.name,
    );
    final emailController = TextEditingController(
      text: appState.currentUser.email,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(l10n.personalDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.yourName),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              appState.updateUserProfile(
                name: nameController.text,
                email: emailController.text,
              );
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _showEditMetricsDialog(
    BuildContext context,
    AppState appState,
    AppLocalizations l10n,
    String type,
  ) {
    final controller = TextEditingController(
      text: type == 'weight'
          ? appState.currentUser.weight.toInt().toString()
          : type == 'height'
          ? appState.currentUser.height.toInt().toString()
          : appState.currentUser.age.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Edit ${type.toUpperCase()}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: type == 'weight'
                ? 'kg'
                : type == 'height'
                ? 'cm'
                : 'years',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              if (type == 'weight') appState.updateUserProfile(weight: val);
              if (type == 'height') appState.updateUserProfile(height: val);
              if (type == 'age') appState.updateUserProfile(age: val.toInt());
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.accentGreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryText, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(
    BuildContext context,
    AppState appState,
    AppLocalizations l10n,
  ) {
    final goals = [
      'lose_weight',
      'build_muscle',
      'improve_endurance',
      'stay_fit',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectGoal,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ...goals.map((goal) {
              final isSelected = appState.currentUser.goal == goal;
              return GestureDetector(
                onTap: () {
                  // Update AppState
                  appState.updateUserProfile(goal: goal);

                  // Update Workout Recommendations IMMEDIATELY
                  Provider.of<WorkoutProvider>(
                    context,
                    listen: false,
                  ).initializeWorkoutsForGoal(goal);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.goalUpdatedTo(l10n.goalLabel(goal)),
                      ),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentGreen.withValues(alpha: 0.1)
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentGreen
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? AppTheme.accentGreen
                            : AppTheme.secondaryText,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.goalLabel(goal),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppTheme.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAppearanceDialog(
    BuildContext context,
    AppState appState,
    AppLocalizations l10n,
  ) {
    final colors = [
      {'name': 'Green', 'color': AppTheme.accentGreen},
      {'name': 'Blue', 'color': AppTheme.accentBlue},
      {'name': 'Orange', 'color': AppTheme.accentOrange},
      {'name': 'Purple', 'color': AppTheme.accentPurple},
      {'name': 'Red', 'color': AppTheme.accentRed},
      {'name': 'Yellow', 'color': AppTheme.accentYellow},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.chooseTheme,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: colors.map((item) {
                final color = item['color'] as Color;
                final name = item['name'] as String;
                final isSelected = appState.themeColor == color;

                return GestureDetector(
                  onTap: () {
                    appState.setThemeColor(color);
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryText,
                                  width: 3,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppTheme.backgroundColor,
                                size: 30,
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppTheme.primaryText
                              : AppTheme.secondaryText,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
