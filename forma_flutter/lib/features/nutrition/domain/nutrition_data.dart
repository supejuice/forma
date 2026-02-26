import 'dart:math' as math;

class NutritionData {
  const NutritionData({
    required this.calories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.sugarGrams,
    required this.sodiumMilligrams,
    required this.potassiumMilligrams,
  });

  final double calories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final double fiberGrams;
  final double sugarGrams;
  final double sodiumMilligrams;
  final double potassiumMilligrams;

  NutritionData normalized() {
    return NutritionData(
      calories: _nonNegative(calories),
      proteinGrams: _nonNegative(proteinGrams),
      carbGrams: _nonNegative(carbGrams),
      fatGrams: _nonNegative(fatGrams),
      fiberGrams: _nonNegative(fiberGrams),
      sugarGrams: _nonNegative(sugarGrams),
      sodiumMilligrams: _nonNegative(sodiumMilligrams),
      potassiumMilligrams: _nonNegative(potassiumMilligrams),
    );
  }

  NutritionData withFallbackCaloriesFromMacros() {
    if (calories > 0) {
      return normalized();
    }
    final double estimatedCalories =
        (proteinGrams * 4) + (carbGrams * 4) + (fatGrams * 9);
    return NutritionData(
      calories: _nonNegative(estimatedCalories),
      proteinGrams: _nonNegative(proteinGrams),
      carbGrams: _nonNegative(carbGrams),
      fatGrams: _nonNegative(fatGrams),
      fiberGrams: _nonNegative(fiberGrams),
      sugarGrams: _nonNegative(sugarGrams),
      sodiumMilligrams: _nonNegative(sodiumMilligrams),
      potassiumMilligrams: _nonNegative(potassiumMilligrams),
    );
  }

  Map<String, double> toJson() {
    return <String, double>{
      'calories': calories,
      'protein_g': proteinGrams,
      'carbs_g': carbGrams,
      'fat_g': fatGrams,
      'fiber_g': fiberGrams,
      'sugar_g': sugarGrams,
      'sodium_mg': sodiumMilligrams,
      'potassium_mg': potassiumMilligrams,
    };
  }

  static double _nonNegative(double value) => math.max(0, value);
}
