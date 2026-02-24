import '../domain/nutrition_extraction.dart';

abstract interface class NutritionFlow {
  Future<NutritionExtraction> extract({
    required String apiKey,
    required String mealText,
  });
}
