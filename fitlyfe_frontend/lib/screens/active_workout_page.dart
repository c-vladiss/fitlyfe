import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/models/workout.dart';
import 'package:fitlyfe_frontend/providers/workout_provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/rest_timer_widget.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final WorkoutRoutine routine;

  const ActiveWorkoutPage({super.key, required this.routine});

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  DateTime? _startTime;
  bool _showRestTimer = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primaryText),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Text(
          widget.routine.name,
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showRestTimer ? Icons.timer_off : Icons.timer,
              color: AppTheme.accentGreen,
            ),
            onPressed: () {
              setState(() {
                _showRestTimer = !_showRestTimer;
              });
            },
            tooltip: 'Toggle Rest Timer',
          ),
          TextButton(
            onPressed: () => _finishWorkout(context, workoutProvider),
            child: const Text(
              'FINISH',
              style: TextStyle(
                color: AppTheme.accentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                final duration = DateTime.now().difference(_startTime!);
                final minutes = duration.inMinutes.toString().padLeft(2, '0');
                final seconds = (duration.inSeconds % 60).toString().padLeft(
                  2,
                  '0',
                );
                return Column(
                  children: [
                    const Text(
                      'ELAPSED TIME',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$minutes:$seconds',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          if (_showRestTimer) ...[
            const Divider(color: AppTheme.cardBackground, thickness: 2),
            const RestTimerWidget(),
          ],

          const Divider(color: AppTheme.cardBackground, thickness: 2),

          // Exercises List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: widget.routine.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.routine.exercises[index];
                return _buildExerciseCard(exercise);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.1)),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const Icon(
                Icons.check_circle_outline,
                color: AppTheme.secondaryText,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sets logic can go here (simplified for now)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'TARGET',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    Text(
                      '3 Sets x 12 Reps',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                VerticalDivider(color: Colors.white24),
                Column(
                  children: [
                    Text(
                      'REST',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    Text('60s', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showRestTimer = true;
                  });
                },
                icon: const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppTheme.accentGreen,
                ),
                label: const Text(
                  'START REST',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Leave workout?',
          style: TextStyle(color: AppTheme.primaryText),
        ),
        content: const Text(
          'Your progress in this session will not be saved.',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              appState.setPageIndex(2);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Navigate back
            },
            child: const Text(
              'LEAVE',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  void _finishWorkout(BuildContext context, WorkoutProvider provider) {
    provider.endSession();

    // Ensure we switch to the Workout tab in the background
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setPageIndex(2);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout completed! High five! ✋'),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(
      context,
    ); // Return to whoever called it, but AppState will ensure tab 2 is active
  }
}
