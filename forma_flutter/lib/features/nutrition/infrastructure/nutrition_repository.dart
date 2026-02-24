import '../domain/calorie_trend_point.dart';
import '../domain/date_range_filter.dart';
import '../domain/meal_log_entry.dart';

abstract interface class NutritionRepository {
  Future<MealLogEntry> saveMealLog(MealLogEntry entry);

  Future<List<MealLogEntry>> recentMeals({int limit = 20});

  Future<List<String>> recentMealTexts({int limit = 10});

  Future<List<CalorieTrendPoint>> calorieTrend(DateRangeFilter range);

  Future<double> totalCalories(DateRangeFilter range);

  Future<int?> readDailyCalorieTarget();

  Future<void> saveDailyCalorieTarget(int targetCalories);
}
