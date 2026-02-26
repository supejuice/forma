import '../domain/calorie_trend_point.dart';
import '../domain/calorie_target_calculator.dart';
import '../domain/daily_feedback_entry.dart';
import '../domain/daily_nutrition_totals.dart';
import '../domain/date_range_filter.dart';
import '../domain/meal_log_entry.dart';
import '../domain/mistral_usage_ledger.dart';

abstract interface class NutritionRepository {
  Future<MealLogEntry> saveMealLog(MealLogEntry entry);

  Future<List<MealLogEntry>> recentMeals({int limit = 20});

  Future<List<String>> recentMealTexts({int limit = 10});

  Future<List<CalorieTrendPoint>> calorieTrend(DateRangeFilter range);

  Future<double> totalCalories(DateRangeFilter range);

  Future<int?> readDailyCalorieTarget();

  Future<void> saveDailyCalorieTarget(int targetCalories);

  Future<CalorieProfile?> readCalorieProfile();

  Future<void> saveCalorieProfile(CalorieProfile profile);

  Future<MistralUsageLedger?> readMistralUsageLedger();

  Future<void> saveMistralUsageLedger(MistralUsageLedger ledger);

  Future<DailyNutritionTotals> dailyNutritionTotals(DateTime day);

  Future<List<DateTime>> pendingDailyFeedbackDays({int limit = 7});

  Future<DailyFeedbackEntry?> readDailyFeedback(DateTime day);

  Future<List<DailyFeedbackEntry>> recentDailyFeedback({int limit = 14});

  Future<void> saveDailyFeedback(DailyFeedbackEntry entry);
}
