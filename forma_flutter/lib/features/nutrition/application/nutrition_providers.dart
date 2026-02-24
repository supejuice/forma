import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_exception.dart';
import '../domain/calorie_trend_point.dart';
import '../domain/date_range_filter.dart';
import '../domain/meal_log_entry.dart';
import '../infrastructure/sqlite_nutrition_repository.dart';

final FutureProvider<List<MealLogEntry>> recentMealsProvider =
    FutureProvider<List<MealLogEntry>>((Ref ref) {
      return ref.read(nutritionRepositoryProvider).recentMeals(limit: 20);
    });

final FutureProvider<List<String>> recentMealTextsProvider =
    FutureProvider<List<String>>((Ref ref) {
      return ref.read(nutritionRepositoryProvider).recentMealTexts(limit: 8);
    });

enum TrendPreset { week, month, quarter, custom }

class TrendSelection {
  const TrendSelection({required this.preset, required this.range});

  final TrendPreset preset;
  final DateRangeFilter range;
}

final NotifierProvider<TrendSelectionController, TrendSelection>
trendSelectionProvider =
    NotifierProvider<TrendSelectionController, TrendSelection>(
      TrendSelectionController.new,
    );

class TrendSelectionController extends Notifier<TrendSelection> {
  @override
  TrendSelection build() {
    return TrendSelection(
      preset: TrendPreset.week,
      range: DateRangeFilter.lastDays(days: 7, label: '7 days'),
    );
  }

  void selectCustom(DateTimeRange dateRange) {
    final DateFormat formatter = DateFormat('MMM d');
    final String label =
        '${formatter.format(dateRange.start)} - ${formatter.format(dateRange.end)}';
    state = TrendSelection(
      preset: TrendPreset.custom,
      range: DateRangeFilter(
        start: DateTime(
          dateRange.start.year,
          dateRange.start.month,
          dateRange.start.day,
        ),
        end: DateTime(
          dateRange.end.year,
          dateRange.end.month,
          dateRange.end.day,
        ),
        label: label,
      ),
    );
  }

  void selectPreset(TrendPreset preset) {
    switch (preset) {
      case TrendPreset.week:
        state = TrendSelection(
          preset: preset,
          range: DateRangeFilter.lastDays(days: 7, label: '7 days'),
        );
      case TrendPreset.month:
        state = TrendSelection(
          preset: preset,
          range: DateRangeFilter.lastDays(days: 30, label: '30 days'),
        );
      case TrendPreset.quarter:
        state = TrendSelection(
          preset: preset,
          range: DateRangeFilter.lastDays(days: 90, label: '90 days'),
        );
      case TrendPreset.custom:
        break;
    }
  }
}

final FutureProvider<List<CalorieTrendPoint>> calorieTrendProvider =
    FutureProvider<List<CalorieTrendPoint>>((Ref ref) {
      final DateRangeFilter range = ref.watch(trendSelectionProvider).range;
      return ref.read(nutritionRepositoryProvider).calorieTrend(range);
    });

final AsyncNotifierProvider<CalorieTargetController, int>
calorieTargetControllerProvider =
    AsyncNotifierProvider<CalorieTargetController, int>(
      CalorieTargetController.new,
    );

class CalorieTargetController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final int? saved =
        await ref.read(nutritionRepositoryProvider).readDailyCalorieTarget();
    return saved ?? 1900;
  }

  Future<void> bumpBy(int delta) async {
    final int current = switch (state) {
      AsyncData<int>(:final value) => value,
      _ =>
        (await ref
                .read(nutritionRepositoryProvider)
                .readDailyCalorieTarget()) ??
            1900,
    };
    await setTarget(current + delta);
  }

  Future<void> setTarget(int newTarget) async {
    final int clamped = newTarget.clamp(1200, 4200).toInt();
    state = const AsyncValue<int>.loading();
    state = await AsyncValue.guard<int>(() async {
      await ref
          .read(nutritionRepositoryProvider)
          .saveDailyCalorieTarget(clamped);
      return clamped;
    });
  }

  Future<void> validateAndSetFromText(String value) async {
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null) {
      throw const AppException('Daily target must be a number.');
    }
    await setTarget(parsed);
  }
}
