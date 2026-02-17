import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class RestTimerWidget extends StatefulWidget {
  const RestTimerWidget({super.key});

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  int _selectedDuration = 60; // in seconds
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _isRunning = false;

  final List<int> _presetDurations = [30, 60, 90, 120];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final tp = Provider.of<TranslationProvider>(context, listen: false);
    if (_isRunning) {
      _pauseTimer();
      return;
    }

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _resetTimer();
        // Show completion notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tp.translate('rest_period_completed')),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedDuration;
    });
  }

  void _selectDuration(int seconds) {
    if (!_isRunning) {
      setState(() {
        _selectedDuration = seconds;
        _remainingSeconds = seconds;
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TranslationProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: AppTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                tp.translate('rest_timer'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Timer Display
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.cardBackground,
            ),
            child: Center(
              child: Text(
                _formatTime(_remainingSeconds),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: AppTheme.backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isRunning ? tp.translate('pause') : tp.translate('start')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetTimer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryText,
                    side: const BorderSide(color: AppTheme.cardBackground),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(tp.translate('reset')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Preset Durations
          Text(
            tp.translate('quick_select'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _presetDurations.map((duration) {
              final isSelected = _selectedDuration == duration && !_isRunning;
              return GestureDetector(
                onTap: () => _selectDuration(duration),
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentGreen
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${duration}s',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? AppTheme.backgroundColor
                          : AppTheme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
