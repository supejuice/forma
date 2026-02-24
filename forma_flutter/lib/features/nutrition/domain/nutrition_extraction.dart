import 'meal_log_entry.dart';
import 'nutrition_data.dart';

class NutritionExtraction {
  const NutritionExtraction({
    required this.summary,
    required this.nutrition,
    required this.confidence,
    required this.notes,
  });

  final String summary;
  final NutritionData nutrition;
  final double confidence;
  final String notes;

  MealLogEntry toMealLogEntry({required String rawText, DateTime? loggedAt}) {
    return MealLogEntry(
      id: null,
      rawText: rawText,
      summary: summary,
      loggedAt: loggedAt ?? DateTime.now(),
      nutrition: nutrition,
      confidence: confidence,
      notes: notes,
    );
  }
}
