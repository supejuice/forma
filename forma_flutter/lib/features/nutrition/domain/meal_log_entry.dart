import 'nutrition_data.dart';

class MealLogEntry {
  const MealLogEntry({
    required this.id,
    required this.rawText,
    required this.summary,
    required this.loggedAt,
    required this.nutrition,
    required this.confidence,
    required this.notes,
  });

  final int? id;
  final String rawText;
  final String summary;
  final DateTime loggedAt;
  final NutritionData nutrition;
  final double confidence;
  final String notes;

  MealLogEntry copyWith({
    int? id,
    String? rawText,
    String? summary,
    DateTime? loggedAt,
    NutritionData? nutrition,
    double? confidence,
    String? notes,
  }) {
    return MealLogEntry(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      summary: summary ?? this.summary,
      loggedAt: loggedAt ?? this.loggedAt,
      nutrition: nutrition ?? this.nutrition,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
    );
  }
}
