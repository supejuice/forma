import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/app_exception.dart';
import '../../../core/formatters.dart';
import '../application/nutrition_providers.dart';
import '../domain/calorie_trend_point.dart';
import 'widgets/hero_banner.dart';
import 'widgets/section_card.dart';
import 'widgets/stat_tile.dart';
import 'widgets/trend_line_chart.dart';

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  Future<void> _pickCustomRange(
    BuildContext context,
    WidgetRef ref,
    TrendSelection selection,
  ) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 3)),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: selection.range.start,
        end: selection.range.end,
      ),
    );

    if (picked == null) {
      return;
    }
    ref.read(trendSelectionProvider.notifier).selectCustom(picked);
  }

  Future<void> _promptTarget(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: current.toString(),
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Daily Calorie Target'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 1800'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    try {
      await ref
          .read(calorieTargetControllerProvider.notifier)
          .validateAndSetFromText(controller.text);
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TrendSelection selection = ref.watch(trendSelectionProvider);
    final AsyncValue<List<CalorieTrendPoint>> trendAsync = ref.watch(
      calorieTrendProvider,
    );
    final AsyncValue<int> targetAsync = ref.watch(
      calorieTargetControllerProvider,
    );
    final int target = switch (targetAsync) {
      AsyncData<int>(:final value) => value,
      _ => 1900,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        const HeroBanner(
          imageUrl: AppImages.trend,
          title: 'Calorie trends',
          subtitle: 'Watch progress over 7 days, 30 days, 90 days, or custom.',
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Range', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  _RangeChip(
                    label: '7D',
                    selected: selection.preset == TrendPreset.week,
                    onTap:
                        () => ref
                            .read(trendSelectionProvider.notifier)
                            .selectPreset(TrendPreset.week),
                  ),
                  _RangeChip(
                    label: '30D',
                    selected: selection.preset == TrendPreset.month,
                    onTap:
                        () => ref
                            .read(trendSelectionProvider.notifier)
                            .selectPreset(TrendPreset.month),
                  ),
                  _RangeChip(
                    label: '90D',
                    selected: selection.preset == TrendPreset.quarter,
                    onTap:
                        () => ref
                            .read(trendSelectionProvider.notifier)
                            .selectPreset(TrendPreset.quarter),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickCustomRange(context, ref, selection),
                    icon: const Icon(Icons.date_range_rounded),
                    label: const Text('Custom'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Showing ${selection.range.label}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          child: targetAsync.when(
            data: (int value) {
              return Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Daily calorie target',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '$value kcal',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.leafDark),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed:
                        () => ref
                            .read(calorieTargetControllerProvider.notifier)
                            .bumpBy(-50),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.leaf,
                    ),
                    onPressed:
                        () => ref
                            .read(calorieTargetControllerProvider.notifier)
                            .bumpBy(50),
                    icon: const Icon(Icons.add_rounded),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.outlined(
                    onPressed: () => _promptTarget(context, ref, value),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              );
            },
            loading:
                () => const SizedBox(
                  height: 52,
                  child: Center(child: CircularProgressIndicator()),
                ),
            error: (Object error, StackTrace stackTrace) {
              return Text('Failed to load target: $error');
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          child: trendAsync.when(
            data: (List<CalorieTrendPoint> points) {
              final _TrendStats stats = _TrendStats.from(points, target);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Calories over time',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TrendLineChart(points: points),
                  const SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        StatTile(
                          label: 'Total',
                          value: formatCalories(stats.totalCalories),
                          tint: AppColors.leafDark,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatTile(
                          label: 'Daily Avg',
                          value: formatCalories(stats.dailyAverage),
                          tint: AppColors.coral,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatTile(
                          label: 'Over Target',
                          value: '${stats.daysOverTarget} days',
                          tint: AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading:
                () => const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
            error: (Object error, StackTrace stackTrace) {
              return Text('Failed to load trends: $error');
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SectionCard(
          child: Text(
            'To improve weight-loss consistency: log meals right after eating, verify portions weekly, and focus on keeping your 7-day average below target.',
          ),
        ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}

class _TrendStats {
  const _TrendStats({
    required this.totalCalories,
    required this.dailyAverage,
    required this.daysOverTarget,
  });

  factory _TrendStats.from(List<CalorieTrendPoint> points, int target) {
    if (points.isEmpty) {
      return const _TrendStats(
        totalCalories: 0,
        dailyAverage: 0,
        daysOverTarget: 0,
      );
    }

    double total = 0;
    int over = 0;
    for (final CalorieTrendPoint point in points) {
      total += point.calories;
      if (point.calories > target) {
        over++;
      }
    }

    return _TrendStats(
      totalCalories: total,
      dailyAverage: total / points.length,
      daysOverTarget: over,
    );
  }

  final double totalCalories;
  final double dailyAverage;
  final int daysOverTarget;
}
