import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/formatters.dart';
import '../../domain/calorie_trend_point.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({required this.points, super.key});

  final List<CalorieTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (points.isEmpty) {
      return const SizedBox(height: 200);
    }

    final List<FlSpot> spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < points.length; i++) {
      final double value = points[i].calories;
      maxY = math.max(maxY, value);
      spots.add(FlSpot(i.toDouble(), value));
    }
    final double safeMaxY = math.max(1200, (maxY * 1.2).ceilToDouble());
    final int interval = points.length <= 8 ? 1 : (points.length / 6).ceil();

    return SizedBox(
      height: 220,
      child: LineChart(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: safeMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: safeMaxY / 4,
            getDrawingHorizontalLine:
                (double value) =>
                    FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: safeMaxY / 4,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: interval.toDouble(),
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % interval != 0 && index != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      formatShortDate(points[index].date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots
                    .map((LineBarSpot spot) {
                      final CalorieTrendPoint point = points[spot.x.toInt()];
                      return LineTooltipItem(
                        '${formatShortDate(point.date)}\n${spot.y.toStringAsFixed(0)} kcal',
                        TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    })
                    .toList(growable: false);
              },
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: scheme.primary,
              curveSmoothness: 0.28,
              barWidth: 3,
              dotData: FlDotData(show: points.length <= 14),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.primary.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
