import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/app_exception.dart';
import '../../../core/formatters.dart';
import '../application/nutrition_providers.dart';
import '../domain/calorie_target_calculator.dart';
import '../domain/calorie_trend_point.dart';
import 'widgets/body_shape_diagram.dart';
import 'widgets/hero_banner.dart';
import 'widgets/section_card.dart';
import 'widgets/stat_tile.dart';
import 'widgets/trend_line_chart.dart';

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  bool _useWideLayout(BuildContext context, BoxConstraints constraints) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isLandscape = size.width > size.height;
    return constraints.maxWidth >= AppBreakpoints.large ||
        (isLandscape && constraints.maxWidth >= AppBreakpoints.medium);
  }

  double _horizontalPaddingForWidth(double width) {
    if (width >= AppBreakpoints.large) {
      return AppSpacing.xl;
    }
    if (width >= AppBreakpoints.medium) {
      return AppSpacing.lg;
    }
    return 0;
  }

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

  Future<void> _promptScientificTarget(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final CalorieProfile initialProfile =
        await ref.read(calorieProfileControllerProvider).read() ??
        const CalorieProfile(
          sex: BiologicalSex.female,
          ageYears: 30,
          heightCm: 170,
          weightKg: 70,
          activityLevel: ActivityLevel.moderatelyActive,
          goalPace: GoalPace.maintain,
        );
    if (!context.mounted) {
      return;
    }

    final TextEditingController ageController = TextEditingController(
      text: initialProfile.ageYears.toString(),
    );
    final TextEditingController heightController = TextEditingController(
      text: initialProfile.heightCm.toStringAsFixed(1),
    );
    final TextEditingController weightController = TextEditingController(
      text: initialProfile.weightKg.toStringAsFixed(1),
    );
    final TextEditingController neckController = TextEditingController(
      text: initialProfile.neckCm?.toStringAsFixed(1) ?? '',
    );
    final TextEditingController waistController = TextEditingController(
      text: initialProfile.waistCm?.toStringAsFixed(1) ?? '',
    );
    final TextEditingController hipController = TextEditingController(
      text: initialProfile.hipCm?.toStringAsFixed(1) ?? '',
    );
    BiologicalSex sex = initialProfile.sex;
    ActivityLevel activityLevel = initialProfile.activityLevel;
    GoalPace goalPace = initialProfile.goalPace;
    String? errorText;

    final _ScientificTargetOutput?
    output = await showDialog<_ScientificTargetOutput>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void refreshInputs() {
              setState(() {
                errorText = null;
              });
            }

            final int? liveAge = int.tryParse(ageController.text.trim());
            final double? liveHeight = double.tryParse(
              heightController.text.trim(),
            );
            final double? liveWeight = double.tryParse(
              weightController.text.trim(),
            );
            final String liveNeckText = neckController.text.trim();
            final String liveWaistText = waistController.text.trim();
            final String liveHipText = hipController.text.trim();
            final double? liveNeck =
                liveNeckText.isEmpty ? null : double.tryParse(liveNeckText);
            final double? liveWaist =
                liveWaistText.isEmpty ? null : double.tryParse(liveWaistText);
            final double? liveHip =
                liveHipText.isEmpty ? null : double.tryParse(liveHipText);
            final bool hasCoreInputs =
                liveAge != null && liveHeight != null && liveWeight != null;
            CalorieTargetResult? previewTarget;
            BodyCompositionEstimate? previewComposition;
            String? previewError;
            if (liveNeckText.isNotEmpty && liveNeck == null) {
              previewError = 'Neck must be a valid number.';
            } else if (liveWaistText.isNotEmpty && liveWaist == null) {
              previewError = 'Waist must be a valid number.';
            } else if (liveHipText.isNotEmpty && liveHip == null) {
              previewError = 'Hip must be a valid number.';
            } else if (hasCoreInputs) {
              try {
                final CalorieProfile profile = CalorieProfile(
                  sex: sex,
                  ageYears: liveAge,
                  heightCm: liveHeight,
                  weightKg: liveWeight,
                  activityLevel: activityLevel,
                  goalPace: goalPace,
                  neckCm: liveNeck,
                  waistCm: liveWaist,
                  hipCm: liveHip,
                );
                previewTarget = calculateScientificTargetFromProfile(profile);
                try {
                  previewComposition = estimateBodyComposition(profile);
                } on AppException catch (_) {
                  previewComposition = null;
                }
              } on AppException catch (error) {
                previewError = error.message;
              }
            }

            void submit() {
              final int? age = int.tryParse(ageController.text.trim());
              final double? height = double.tryParse(
                heightController.text.trim(),
              );
              final double? weight = double.tryParse(
                weightController.text.trim(),
              );
              final String neckText = neckController.text.trim();
              final String waistText = waistController.text.trim();
              final String hipText = hipController.text.trim();
              final double? neck =
                  neckText.isEmpty ? null : double.tryParse(neckText);
              final double? waist =
                  waistText.isEmpty ? null : double.tryParse(waistText);
              final double? hip =
                  hipText.isEmpty ? null : double.tryParse(hipText);
              if (age == null || height == null || weight == null) {
                setState(() {
                  errorText =
                      'Enter valid numeric values for age, height, and weight.';
                });
                return;
              }
              if (neckText.isNotEmpty && neck == null) {
                setState(() {
                  errorText = 'Neck must be a valid number.';
                });
                return;
              }
              if (waistText.isNotEmpty && waist == null) {
                setState(() {
                  errorText = 'Waist must be a valid number.';
                });
                return;
              }
              if (hipText.isNotEmpty && hip == null) {
                setState(() {
                  errorText = 'Hip must be a valid number.';
                });
                return;
              }

              try {
                final CalorieProfile profile = CalorieProfile(
                  sex: sex,
                  ageYears: age,
                  heightCm: height,
                  weightKg: weight,
                  activityLevel: activityLevel,
                  goalPace: goalPace,
                  neckCm: neck,
                  waistCm: waist,
                  hipCm: hip,
                );
                final CalorieTargetResult calculatedTarget =
                    calculateScientificTargetFromProfile(profile);
                final BodyCompositionEstimate? composition =
                    estimateBodyComposition(profile);
                Navigator.of(context).pop(
                  _ScientificTargetOutput(
                    profile: profile,
                    targetResult: calculatedTarget,
                    composition: composition,
                  ),
                );
              } on AppException catch (error) {
                setState(() {
                  errorText = error.message;
                });
              }
            }

            return AlertDialog(
              title: const Text('Scientific Calorie Target'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Uses Mifflin-St Jeor BMR and standard activity multipliers.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<BiologicalSex>(
                        initialValue: sex,
                        decoration: const InputDecoration(labelText: 'Sex'),
                        items: BiologicalSex.values
                            .map(
                              (BiologicalSex value) =>
                                  DropdownMenuItem<BiologicalSex>(
                                    value: value,
                                    child: Text(value.label),
                                  ),
                            )
                            .toList(growable: false),
                        onChanged: (BiologicalSex? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            sex = value;
                            errorText = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => refreshInputs(),
                        decoration: const InputDecoration(
                          labelText: 'Age (years)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => refreshInputs(),
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => refreshInputs(),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Optional for body-fat estimate (US Navy method)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: neckController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => refreshInputs(),
                        decoration: const InputDecoration(
                          labelText: 'Neck circumference (cm)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: waistController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => refreshInputs(),
                        decoration: const InputDecoration(
                          labelText: 'Waist circumference (cm)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: hipController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => refreshInputs(),
                        decoration: InputDecoration(
                          labelText:
                              sex == BiologicalSex.female
                                  ? 'Hip circumference (cm) - required for women'
                                  : 'Hip circumference (cm)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<ActivityLevel>(
                        initialValue: activityLevel,
                        decoration: const InputDecoration(
                          labelText: 'Activity level',
                        ),
                        items: ActivityLevel.values
                            .map(
                              (ActivityLevel value) =>
                                  DropdownMenuItem<ActivityLevel>(
                                    value: value,
                                    child: Text(value.label),
                                  ),
                            )
                            .toList(growable: false),
                        onChanged: (ActivityLevel? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            activityLevel = value;
                            errorText = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<GoalPace>(
                        initialValue: goalPace,
                        decoration: const InputDecoration(labelText: 'Goal'),
                        items: GoalPace.values
                            .map(
                              (GoalPace value) => DropdownMenuItem<GoalPace>(
                                value: value,
                                child: Text(value.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (GoalPace? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            goalPace = value;
                            errorText = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLowest,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Live estimate',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            if (previewTarget != null) ...<Widget>[
                              Text(
                                'Target: ${previewTarget.targetCalories} kcal/day',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'BMR: ${previewTarget.bmr.toStringAsFixed(0)} kcal',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Estimated TDEE: ${previewTarget.estimatedTdee.toStringAsFixed(0)} kcal',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                previewComposition == null
                                    ? 'Body fat estimate unavailable until required measurements are entered.'
                                    : 'Body fat est: ${previewComposition.bodyFatPercent.toStringAsFixed(1)}% (${previewComposition.categoryLabel})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ] else if (previewError != null) ...<Widget>[
                              Text(
                                previewError,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ] else ...<Widget>[
                              Text(
                                hasCoreInputs
                                    ? 'Adjust values to preview estimate.'
                                    : 'Enter age, height, and weight to see estimate.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (errorText != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submit,
                  child: const Text('Calculate & Use'),
                ),
              ],
            );
          },
        );
      },
    );

    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    neckController.dispose();
    waistController.dispose();
    hipController.dispose();

    if (output == null) {
      return;
    }

    await ref.read(calorieProfileControllerProvider).save(output.profile);
    await ref
        .read(calorieTargetControllerProvider.notifier)
        .setTarget(output.targetResult.targetCalories);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Target set to ${output.targetResult.targetCalories} kcal '
              '(BMR ${output.targetResult.bmr.toStringAsFixed(0)}, '
              'TDEE ${output.targetResult.estimatedTdee.toStringAsFixed(0)})'
              '${output.composition == null ? '.' : ', ${output.composition!.bodyFatPercent.toStringAsFixed(1)}% body fat est.'}',
            ),
          ),
        );
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
    final AsyncValue<CalorieProfile?> profileAsync = ref.watch(
      calorieProfileProvider,
    );
    final int target = switch (targetAsync) {
      AsyncData<int>(:final value) => value,
      _ => 1900,
    };

    final Widget rangeSection = SectionCard(
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
    );

    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget targetSection = SectionCard(
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
                          ?.copyWith(color: scheme.primary),
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
                style: IconButton.styleFrom(backgroundColor: scheme.primary),
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
              const SizedBox(width: AppSpacing.xs),
              IconButton.outlined(
                tooltip: 'Scientific calculator',
                onPressed: () => _promptScientificTarget(context, ref),
                icon: const Icon(Icons.calculate_rounded),
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
    );

    final Widget chartSection = SectionCard(
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
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  StatTile(
                    label: 'Total',
                    value: formatCalories(stats.totalCalories),
                    tint: scheme.primary,
                  ),
                  StatTile(
                    label: 'Daily Avg',
                    value: formatCalories(stats.dailyAverage),
                    tint: AppColors.coral,
                  ),
                  StatTile(
                    label: 'Over Target',
                    value: '${stats.daysOverTarget} days',
                    tint:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        scheme.onSurface,
                  ),
                  StatTile(
                    label: 'Rollover',
                    value: _formatRollover(stats.rolloverCalories),
                    tint:
                        stats.rolloverCalories >= 0
                            ? scheme.primary
                            : scheme.error,
                  ),
                ],
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
    );

    final Widget bodyInsightsSection = profileAsync.when(
      data: (CalorieProfile? profile) {
        if (profile == null) {
          return SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Body composition',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Open the scientific calculator to save your profile and view body-shape and body-fat estimates.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        CalorieTargetResult? computedTarget;
        BodyShapeModel? shape;
        String? profileError;
        try {
          computedTarget = calculateScientificTargetFromProfile(profile);
          shape = buildBodyShapeModel(profile);
        } on AppException catch (error) {
          profileError = error.message;
        }
        if (computedTarget == null || shape == null) {
          return SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Body composition',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  profileError ?? 'Saved profile could not be loaded.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text('Open the scientific calculator and save again.'),
              ],
            ),
          );
        }
        final CalorieTargetResult targetMetrics = computedTarget;
        final BodyShapeModel shapeModel = shape;
        BodyCompositionEstimate? composition;
        String? compositionError;
        try {
          composition = estimateBodyComposition(profile);
        } on AppException catch (error) {
          compositionError = error.message;
        }

        return SectionCard(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 700;
              final Widget diagram = BodyShapeDiagram(
                shape: shapeModel,
                label: 'Estimated ${shapeModel.label} silhouette',
                bodyFatPercent: composition?.bodyFatPercent,
              );
              final Widget stats = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Body composition',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Based on your saved profile and measurements.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Scientific target: ${targetMetrics.targetCalories} kcal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'BMR: ${targetMetrics.bmr.toStringAsFixed(0)} kcal',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Estimated TDEE: ${targetMetrics.estimatedTdee.toStringAsFixed(0)} kcal',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (composition != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Body-fat category: ${composition.categoryLabel}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Fat mass: ${composition.fatMassKg.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Lean mass: ${composition.leanMassKg.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Waist-to-height: ${composition.waistToHeightRatio.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (composition.waistToHipRatio != null)
                      Text(
                        'Waist-to-hip: ${composition.waistToHipRatio!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ] else ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      compositionError ??
                          'Add neck + waist measurements (and hip for women) in calculator to estimate body fat.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(child: diagram),
                    const SizedBox(height: AppSpacing.sm),
                    stats,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: diagram),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: stats),
                ],
              );
            },
          ),
        );
      },
      loading:
          () => const SectionCard(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error: (Object error, StackTrace stackTrace) {
        return SectionCard(child: Text('Failed to load profile: $error'));
      },
    );

    const Widget guidanceSection = SectionCard(
      child: Text(
        'To improve weight-loss consistency: log meals right after eating, verify portions weekly, and focus on keeping your 7-day average below target.',
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useWideLayout = _useWideLayout(context, constraints);
        final double horizontalPadding = _horizontalPaddingForWidth(
          constraints.maxWidth,
        );
        final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          120,
        );

        if (!useWideLayout) {
          return ListView(
            padding: contentPadding,
            children: <Widget>[
              const HeroBanner(
                imageUrl: AppImages.trend,
                title: 'Calorie trends',
                subtitle:
                    'Watch progress over 7 days, 30 days, 90 days, or custom.',
              ),
              const SizedBox(height: AppSpacing.lg),
              rangeSection,
              const SizedBox(height: AppSpacing.md),
              targetSection,
              const SizedBox(height: AppSpacing.md),
              bodyInsightsSection,
              const SizedBox(height: AppSpacing.md),
              chartSection,
              const SizedBox(height: AppSpacing.md),
              guidanceSection,
            ],
          );
        }

        return SingleChildScrollView(
          padding: contentPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const HeroBanner(
                      imageUrl: AppImages.trend,
                      title: 'Calorie trends',
                      subtitle:
                          'Watch progress over 7 days, 30 days, 90 days, or custom.',
                      height: 220,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    rangeSection,
                    const SizedBox(height: AppSpacing.md),
                    targetSection,
                    const SizedBox(height: AppSpacing.md),
                    bodyInsightsSection,
                    const SizedBox(height: AppSpacing.md),
                    guidanceSection,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 7, child: chartSection),
            ],
          ),
        );
      },
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
    required this.totalBudgetCalories,
    required this.rolloverCalories,
  });

  factory _TrendStats.from(List<CalorieTrendPoint> points, int target) {
    if (points.isEmpty) {
      return const _TrendStats(
        totalCalories: 0,
        dailyAverage: 0,
        daysOverTarget: 0,
        totalBudgetCalories: 0,
        rolloverCalories: 0,
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

    final double totalBudget = (target * points.length).toDouble();

    return _TrendStats(
      totalCalories: total,
      dailyAverage: total / points.length,
      daysOverTarget: over,
      totalBudgetCalories: totalBudget,
      rolloverCalories: totalBudget - total,
    );
  }

  final double totalCalories;
  final double dailyAverage;
  final int daysOverTarget;
  final double totalBudgetCalories;
  final double rolloverCalories;
}

String _formatRollover(double calories) {
  final String sign = calories >= 0 ? '+' : '-';
  return '$sign${calories.abs().toStringAsFixed(0)} kcal';
}

class _ScientificTargetOutput {
  const _ScientificTargetOutput({
    required this.profile,
    required this.targetResult,
    required this.composition,
  });

  final CalorieProfile profile;
  final CalorieTargetResult targetResult;
  final BodyCompositionEstimate? composition;
}
