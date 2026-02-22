import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:fitlyfe_frontend/l10n/generated/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form State
  final TextEditingController _nameController = TextEditingController();
  double _height = 175;
  double _weight = 70;
  String _selectedGoal = 'stay_fit'; // Matches key in ARB mapping
  DateTime _selectedDate = DateTime(2000, 1, 1);

  final List<String> _goals = [
    'lose_weight',
    'build_muscle',
    'stay_fit',
    'improve_endurance',
  ];

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // On the first page, back = cancel sign-up → sign out.
      // _onAppStateChanged in main.dart will navigate back to WelcomeScreen.
      Supabase.instance.client.auth.signOut();
    }
  }

  void _completeOnboarding() {
    final appState = Provider.of<AppState>(context, listen: false);

    // Calculate age from DOB
    final now = DateTime.now();
    int age = now.year - _selectedDate.year;
    if (now.month < _selectedDate.month ||
        (now.month == _selectedDate.month && now.day < _selectedDate.day)) {
      age--;
    }

    // Update user profile with onboarding data
    appState.updateUserProfile(
      name: _nameController.text.isEmpty
          ? 'Fitness User'
          : _nameController.text,
      height: _height,
      weight: _weight,
      age: age,
      goal: _selectedGoal,
    );

    // Initialize workouts based on the selected goal immediately
    Provider.of<WorkoutProvider>(
      context,
      listen: false,
    ).initializeWorkoutsForGoal(_selectedGoal);

    // Mark onboarding complete — AppState notifies listeners, which triggers
    // _onAppStateChanged in main.dart to navigate to MainScreen.
    appState.completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the generated localization delegate
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentGreen.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Header with Back Button and Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Back Button
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: _currentPage > 0
                            ? IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppTheme.primaryText,
                                  size: 20,
                                ),
                                onPressed: _previousPage,
                              )
                            : null,
                      ),
                      // Progress Bar
                      Expanded(
                        child: Row(
                          children: List.generate(5, (index) {
                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: index <= _currentPage
                                      ? AppTheme.accentGreen
                                      : AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 48, height: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildNameStep(l10n),
                      _buildDOBStep(l10n),
                      _buildHeightStep(l10n),
                      _buildWeightStep(l10n),
                      _buildGoalStep(l10n),
                    ],
                  ),
                ),

                // Bottom Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Hero(
                    tag: 'onboarding_button',
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: AppTheme.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == 4 ? l10n.getStarted : l10n.continueText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer(String title, String subtitle, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 32, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 60),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildNameStep(AppLocalizations l10n) {
    return _buildStepContainer(
      l10n.nameTitle,
      l10n.nameSubtitle,
      Container(
        alignment: const Alignment(0.0, -0.3),
        child: TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(fontSize: 24, color: AppTheme.primaryText),
          decoration: InputDecoration(
            hintText: l10n.yourName,
            hintStyle: TextStyle(
              color: AppTheme.secondaryText.withValues(alpha: 0.3),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.cardBackground, width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.accentGreen, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDOBStep(AppLocalizations l10n) {
    return _buildStepContainer(
      l10n.dobTitle,
      l10n.dobSubtitle,
      Container(
        alignment: const Alignment(0.0, -0.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final ThemeData pickerTheme = Theme.of(context);
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  builder: (context, child) {
                    return Theme(
                      data: pickerTheme.copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.accentGreen,
                          onPrimary: AppTheme.backgroundColor,
                          surface: AppTheme.cardBackground,
                          onSurface: AppTheme.primaryText,
                          secondary: AppTheme.accentGreen,
                        ),
                        dividerColor: Colors.transparent,
                        dialogTheme: DialogThemeData(
                          backgroundColor: AppTheme.backgroundColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppTheme.accentGreen,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              // Using correctly mapped years_old key from AppLocalizations
              "${_calculateAge(_selectedDate)} ${l10n.years_old}",
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.secondaryText.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildHeightStep(AppLocalizations l10n) {
    return _buildStepContainer(
      l10n.heightTitle,
      l10n.heightSubtitle,
      Container(
        alignment: const Alignment(0.0, -0.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onDoubleTap: () async {
                final TextEditingController controller = TextEditingController(
                  text: _height.toInt().toString(),
                );
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardBackground,
                    title: Text(
                      l10n.manualHeightEntry,
                      style: const TextStyle(color: AppTheme.primaryText),
                    ),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(color: AppTheme.primaryText),
                      decoration: const InputDecoration(
                        suffixText: 'cm',
                        hintText: 'e.g. 180',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel.toUpperCase(),
                          style: const TextStyle(color: AppTheme.secondaryText),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text),
                        child: Text(
                          l10n.save.toUpperCase(),
                          style: const TextStyle(color: AppTheme.accentGreen),
                        ),
                      ),
                    ],
                  ),
                );

                if (result != null) {
                  final double? newValue = double.tryParse(result);
                  if (newValue != null && newValue >= 100 && newValue <= 230) {
                    setState(() {
                      _height = newValue;
                    });
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _height.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'cm',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Slider(
              value: _height,
              min: 100,
              max: 230,
              activeColor: AppTheme.accentGreen,
              inactiveColor: AppTheme.cardBackground,
              onChanged: (value) {
                setState(() {
                  _height = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightStep(AppLocalizations l10n) {
    return _buildStepContainer(
      l10n.weightTitle,
      l10n.weightSubtitle,
      Container(
        alignment: const Alignment(0.0, -0.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onDoubleTap: () async {
                final TextEditingController controller = TextEditingController(
                  text: _weight.toStringAsFixed(1),
                );
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardBackground,
                    title: Text(
                      l10n.manualWeightEntry,
                      style: const TextStyle(color: AppTheme.primaryText),
                    ),
                    content: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                      style: const TextStyle(color: AppTheme.primaryText),
                      decoration: const InputDecoration(
                        suffixText: 'kg',
                        hintText: 'e.g. 72.5',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel.toUpperCase(),
                          style: const TextStyle(color: AppTheme.secondaryText),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text),
                        child: Text(
                          l10n.save.toUpperCase(),
                          style: const TextStyle(color: AppTheme.accentGreen),
                        ),
                      ),
                    ],
                  ),
                );

                if (result != null) {
                  final double? newValue = double.tryParse(result);
                  if (newValue != null && newValue >= 30 && newValue <= 200) {
                    setState(() {
                      _weight = newValue;
                    });
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _weight.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Slider(
              value: _weight,
              min: 30,
              max: 200,
              activeColor: AppTheme.accentGreen,
              inactiveColor: AppTheme.cardBackground,
              onChanged: (value) {
                setState(() {
                  _weight = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalStep(AppLocalizations l10n) {
    return _buildStepContainer(
      l10n.goalTitle,
      l10n.goalSubtitle,
      ListView.builder(
        itemCount: _goals.length,
        itemBuilder: (context, index) {
          final goal = _goals[index];
          final isSelected = _selectedGoal == goal;

          // Map goal keys to camelCase for AppLocalizations
          String translatedLabel = '';
          switch (goal) {
            case 'lose_weight':
              translatedLabel = l10n.loseWeight;
              break;
            case 'build_muscle':
              translatedLabel = l10n.buildMuscle;
              break;
            case 'stay_fit':
              translatedLabel = l10n.stayFit;
              break;
            case 'improve_endurance':
              translatedLabel = l10n.improveEndurance;
              break;
            default:
              translatedLabel = goal;
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedGoal = goal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentGreen
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.accentGreen.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    _getGoalIcon(goal),
                    color: isSelected
                        ? AppTheme.backgroundColor
                        : AppTheme.accentGreen,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    translatedLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.backgroundColor
                          : AppTheme.primaryText,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.backgroundColor,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'lose_weight':
        return Icons.trending_down;
      case 'build_muscle':
        return Icons.fitness_center;
      case 'stay_fit':
        return Icons.favorite;
      case 'improve_endurance':
        return Icons.bolt;
      default:
        return Icons.star;
    }
  }
}
