import 'daily_nutrition_totals.dart';

class DailyFeedbackEntry {
  const DailyFeedbackEntry({
    required this.id,
    required this.day,
    required this.oneLiner,
    required this.totals,
    required this.createdAt,
  });

  final int? id;
  final DateTime day;
  final String oneLiner;
  final DailyNutritionTotals totals;
  final DateTime createdAt;
}
