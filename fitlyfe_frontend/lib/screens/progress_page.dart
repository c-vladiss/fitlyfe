import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitlyfe_frontend/providers/app_state.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:fitlyfe_frontend/providers/progress_provider.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/widgets/progress_chart.dart';
import 'package:fitlyfe_frontend/models/progress.dart';
import 'package:intl/intl.dart';
import 'package:fitlyfe_frontend/screens/goals_page.dart';
import 'package:fitlyfe_frontend/screens/achievements_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late int _currentPage;
  late PageController _pageController;
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppState>(context, listen: false);
    _currentPage = _appState.progressMetricIndex;
    _pageController = PageController(initialPage: _currentPage);
    
    // Listen to changes in progressMetricIndex
    _appState.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    if (_appState.progressMetricIndex != _currentPage) {
      setState(() {
        _currentPage = _appState.progressMetricIndex;
      });
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context);
    final tp = Provider.of<TranslationProvider>(context);
    final appState = Provider.of<AppState>(context);
    final last7Days = progressProvider.last7DaysData;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: AppTheme.accentGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tp.translate('progress'),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Progress Charts (Calories and Steps)
              SizedBox(
                height: 320,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (index != _currentPage) {
                      setState(() {
                        _currentPage = index;
                      });
                      Provider.of<AppState>(context, listen: false)
                          .setProgressMetricIndex(index);
                    }
                  },
                  clipBehavior: Clip.none,
                  children: [
                    _buildChartSection(
                      context,
                      '${tp.translate('calories_burnt')} (${tp.translate('last_7_days')})',
                      AppTheme.accentGreen,
                      'kcal',
                      (d) => d.caloriesBurned,
                      last7Days,
                    ),
                    _buildChartSection(
                      context,
                      '${tp.translate('steps_count')} (${tp.translate('last_7_days')})',
                      AppTheme.accentBlue,
                      'steps',
                      (d) => (d.steps ?? 0).toDouble(),
                      last7Days,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(2, (index) {
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.accentGreen
                              : AppTheme.secondaryText.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Summary Statistics
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    context,
                    tp.translate('total_workout'),
                    progressProvider.totalWorkoutHours.toStringAsFixed(1),
                    tp.translate('hrs'),
                  ),
                  _buildStatCard(
                    context,
                    tp.translate('total_steps'),
                    (progressProvider.totalSteps / 1000).toStringAsFixed(1),
                    tp.translate('k'),
                  ),
                  _buildStatCard(
                    context,
                    tp.translate('weight_lost'),
                    progressProvider.totalWeightLost.toStringAsFixed(1),
                    tp.translate('kg'),
                  ),
                  _buildStatCard(
                    context,
                    tp.translate('avg_calories'),
                    (progressProvider.totalSteps > 0 ? 450 : 0).toString(),
                    tp.translate('kcal'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildActionCard(
                context,
                icon: Icons.flag,
                title: tp.translate('goals'),
                subtitle: '${progressProvider.goals.where((g) => g.isCompleted).length}/${progressProvider.goals.length} ${tp.translate('completed')}',
                iconColor: AppTheme.accentOrange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalsPage()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Achievements
              _buildActionCard(
                context,
                icon: Icons.emoji_events,
                title: tp.translate('achievements'),
                subtitle: '${progressProvider.achievements.where((a) => a.isUnlocked).length} ${tp.translate('unlocked')}',
                iconColor: AppTheme.accentYellow,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementsPage()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Tips to Improve
              _buildActionCard(
                context,
                icon: Icons.lightbulb,
                title: tp.translate('tips_to_improve'),
                subtitle: tp.translate('ask_ai'),
                iconColor: AppTheme.accentGreen,
                isHighlighted: true,
                onTap: () {
                  final appState = Provider.of<AppState>(context, listen: false);
                  appState.setPageIndex(4);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    String title,
    Color color,
    String unit,
    double Function(ProgressData) valueGetter,
    List<ProgressData> data,
  ) {
    return _ChartSection(
      title: title,
      color: color,
      unit: unit,
      valueGetter: valueGetter,
      data: data,
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.accentGreen,
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

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: isHighlighted
              ? Border.all(color: AppTheme.accentGreen.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isHighlighted ? AppTheme.accentGreen : AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isHighlighted ? AppTheme.accentGreen : AppTheme.secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSection extends StatefulWidget {
  final String title;
  final Color color;
  final String unit;
  final double Function(ProgressData) valueGetter;
  final List<ProgressData> data;

  const _ChartSection({
    required this.title,
    required this.color,
    required this.unit,
    required this.valueGetter,
    required this.data,
  });

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  ProgressData? _hoveredData;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hoveredData != null
                          ? DateFormat('EEEE, MMM d').format(_hoveredData!.date)
                          : Provider.of<TranslationProvider>(context, listen: false).translate('last_7_days'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryText.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              if (_hoveredData != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.valueGetter(_hoveredData!).toInt()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: widget.color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      widget.unit,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.color.withOpacity(0.8),
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ProgressChart(
              data: widget.data,
              valueGetter: widget.valueGetter,
              unit: widget.unit,
              color: widget.color,
              onHover: (data) {
                setState(() {
                  _hoveredData = data;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
