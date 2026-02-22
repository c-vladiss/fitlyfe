import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/rest_timer_widget.dart';
import 'package:fitlyfe_frontend/models/workout.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/screens/active_workout_page.dart';

import 'package:fitlyfe_frontend/providers/translation_provider.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final TextEditingController _exerciseController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  int _selectedTab = 0; // 0 = Log Session, 1 = Rest Timer

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );

      // Initialize workouts based on user goal if not already customized
      if (workoutProvider.routines.length <= 1) {
        workoutProvider.initializeWorkoutsForGoal(appState.currentUser.goal);
      }
    });
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final tp = Provider.of<TranslationProvider>(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: AppTheme.accentGreen,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tp.translate('workout_log_book'),
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 44,
                      ), // Icon size + spacing
                      child: Text(
                        tp.translate('track_your_gains'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(tp.translate('log_session'), 0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(tp.translate('rest_timer'), 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildLogSessionTab(context, workoutProvider, tp)
                    : const RestTimerWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentGreen : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected ? AppTheme.backgroundColor : AppTheme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLogSessionTab(
    BuildContext context,
    WorkoutProvider provider,
    TranslationProvider tp,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended Playlists
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.accentYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommended For You',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.accentYellow),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.routines.length,
              itemBuilder: (context, index) {
                final routine = provider.routines[index];
                final isCurrent = provider.currentRoutine?.id == routine.id;
                return GestureDetector(
                  onTap: () => provider.setCurrentRoutine(routine),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: isCurrent
                          ? Border.all(color: AppTheme.accentGreen, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${routine.exercises.length} Exercises',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: AppTheme.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${routine.estimatedDuration.inMinutes}m',
                              style: Theme.of(context).textTheme.bodySmall,
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
          const SizedBox(height: 32),

          // Current Routine Header
          Text(
            tp.translate('active_workout'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (provider.currentRoutine != null)
            _buildRoutineCard(context, provider.currentRoutine!, tp),
          const SizedBox(height: 32),

          // Logged Exercises for Today
          if (provider.sessions.any(
            (s) => s.startTime.day == DateTime.now().day,
          )) ...[
            const SizedBox(height: 32),
            Text('Logged Today', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...provider.sessions
                .where((s) => s.startTime.day == DateTime.now().day)
                .expand((s) => s.exercises)
                .map((exercise) => _buildLoggedExerciseCard(exercise)),
          ],
          const SizedBox(height: 32),

          // Log Set Section
          Text(
            tp.translate('log_session'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Input Fields
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _exerciseController,
                  decoration: InputDecoration(
                    labelText: tp.translate('exercise_name'),
                    hintText: tp.translate('enter_exercise_name'),
                    prefixIcon: const Icon(
                      Icons.fitness_center,
                      color: AppTheme.accentGreen,
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.accentGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _repsController,
                        decoration: InputDecoration(
                          labelText: tp.translate('reps'),
                          hintText: '12',
                          filled: true,
                          fillColor: AppTheme.backgroundColor.withValues(
                            alpha: 0.3,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          hintText: '60',
                          filled: true,
                          fillColor: AppTheme.backgroundColor.withValues(
                            alpha: 0.3,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Log Set Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_exerciseController.text.isEmpty ||
                          _repsController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter exercise name and reps',
                            ),
                          ),
                        );
                        return;
                      }

                      // Check if there is an active session, if not start a "Quick Log" session
                      if (provider.activeSession == null) {
                        provider.startSession(
                          WorkoutRoutine(
                            id: 'quick_log',
                            name: 'Quick Log',
                            exercises: [],
                            estimatedDuration: Duration.zero,
                          ),
                        );
                      }

                      // Add exercise if it doesn't exist in active session
                      final existingExercise = provider.activeSession!.exercises
                          .firstWhere(
                            (e) =>
                                e.name.toLowerCase() ==
                                _exerciseController.text.toLowerCase(),
                            orElse: () {
                              provider.addExerciseToSession(
                                _exerciseController.text,
                              );
                              return provider.activeSession!.exercises.last;
                            },
                          );

                      provider.addSetToExercise(
                        existingExercise.id,
                        int.parse(_repsController.text),
                        double.tryParse(_weightController.text),
                      );

                      // End session immediately for "Quick Log" to save it
                      provider.endSession();

                      _repsController.clear();
                      _weightController.clear();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Set logged successfully!'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.backgroundColor,
                    ),
                    child: Text(tp.translate('log_set')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: AppTheme.accentGreen,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: exercise.sets.map((set) {
              return Chip(
                label: Text(
                  '${set.reps} reps ${set.weight != null ? '• ${set.weight}kg' : ''}',
                ),
                backgroundColor: AppTheme.backgroundColor,
                labelStyle: const TextStyle(fontSize: 12),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(
    BuildContext context,
    WorkoutRoutine routine,
    TranslationProvider tp,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppTheme.accentBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${routine.exercises.length} ${tp.translate('exercises')} • ${routine.estimatedDuration.inMinutes}m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (routine.description != null) ...[
            const SizedBox(height: 16),
            Text(
              routine.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryText,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Provider.of<WorkoutProvider>(
                  context,
                  listen: false,
                ).startSession(routine);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveWorkoutPage(routine: routine),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryText,
                foregroundColor: AppTheme.backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded),
                  SizedBox(width: 8),
                  Text('START SESSION'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
