import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/models/progress.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProgressChart extends StatelessWidget {
  final List<ProgressData> data;
  final double Function(ProgressData) valueGetter;
  final String unit;
  final Color color;
  final Function(ProgressData?)? onHover;

  const ProgressChart({
    super.key,
    required this.data,
    required this.valueGetter,
    required this.unit,
    required this.color,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxValue = data
        .map(valueGetter)
        .fold(0.0, (max, v) => v > max ? v : max);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.cardBackground.withOpacity(0.5),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 ||
                    index >= data.length ||
                    value != index.toDouble()) {
                  return const SizedBox();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    DateFormat('E').format(data[index].date),
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                );
              },
              reservedSize: 32,
              interval: 1,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), valueGetter(entry.value));
            }).toList(),
            isCurved: true,
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.35), color.withOpacity(0.01)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: maxValue > 0 ? maxValue * 1.2 : 10,
        minX: -0.2,
        maxX: 6.2,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchSpotThreshold: 20,
          mouseCursorResolver: (touchEvent, touchResponse) {
            if (touchResponse == null ||
                touchResponse.lineBarSpots == null ||
                touchResponse.lineBarSpots!.isEmpty) {
              return SystemMouseCursors.basic;
            }
            return SystemMouseCursors.click;
          },
          touchCallback:
              (FlTouchEvent event, LineTouchResponse? touchResponse) {
                if (onHover == null) return;

                if (!event.isInterestedForInteractions ||
                    touchResponse == null ||
                    touchResponse.lineBarSpots == null ||
                    touchResponse.lineBarSpots!.isEmpty) {
                  onHover!(null);
                  return;
                }

                final index = touchResponse.lineBarSpots!.first.spotIndex;
                if (index >= 0 && index < data.length) {
                  onHover!(data[index]);
                } else {
                  onHover!(null);
                }
              },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                AppTheme.cardBackground.withOpacity(0.9),
            //tooltipBorderRadius:,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots
                  .map((LineBarSpot touchedSpot) {
                    final index = touchedSpot.x.toInt();
                    if (index < 0 || index >= data.length) return null;

                    final date = data[index].date;
                    final dateStr = DateFormat('EEE, MMM d').format(date);
                    return LineTooltipItem(
                      '$dateStr\n',
                      const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: '${touchedSpot.y.toInt()} $unit',
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  })
                  .toList()
                  .whereType<LineTooltipItem>()
                  .toList();
            },
          ),
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: color.withOpacity(0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 6,
                            color: color,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          ),
                    ),
                  );
                }).toList();
              },
        ),
      ),
    );
  }
}
