import 'package:flutter_test/flutter_test.dart';
import 'package:forma_flutter/features/nutrition/infrastructure/mistral_nutrition_flow.dart';

void main() {
  const NutritionResponseParser parser = NutritionResponseParser();

  test('parses strict JSON payload', () {
    const String response = '''
    {
      "meal_summary": "Chicken bowl",
      "nutrition": {
        "calories": 620,
        "protein_g": 42,
        "carbs_g": 55,
        "fat_g": 21,
        "fiber_g": 9,
        "sugar_g": 6,
        "sodium_mg": 820
      },
      "confidence": 0.82,
      "notes": "Assumes one bowl serving"
    }
    ''';

    final extraction = parser.parse(response, fallbackSummary: 'Fallback meal');

    expect(extraction.summary, 'Chicken bowl');
    expect(extraction.nutrition.calories, 620);
    expect(extraction.nutrition.proteinGrams, 42);
    expect(extraction.confidence, closeTo(0.82, 0.001));
  });

  test(
    'parses fenced JSON and calculates calories from macros when missing',
    () {
      const String response = '''
    ```json
    {
      "meal_summary": "Yogurt snack",
      "nutrition": {
        "calories": 0,
        "protein_g": 20,
        "carbs_g": 30,
        "fat_g": 10,
        "fiber_g": 2,
        "sugar_g": 14,
        "sodium_mg": 110
      },
      "confidence": 0.71,
      "notes": "Estimated from standard portions"
    }
    ```
    ''';

      final extraction = parser.parse(
        response,
        fallbackSummary: 'Fallback meal',
      );

      expect(extraction.summary, 'Yogurt snack');
      expect(extraction.nutrition.calories, 290); // 20*4 + 30*4 + 10*9
      expect(extraction.confidence, closeTo(0.71, 0.001));
    },
  );
}
