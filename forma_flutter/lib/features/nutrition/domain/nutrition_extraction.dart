import 'meal_log_entry.dart';
import 'mistral_usage_ledger.dart';
import 'nutrition_data.dart';

class NutritionExtraction {
  const NutritionExtraction({
    required this.summary,
    required this.nutrition,
    required this.confidence,
    required this.notes,
    this.usage,
  });

  final String summary;
  final NutritionData nutrition;
  final double confidence;
  final String notes;
  final MistralTokenUsage? usage;

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
