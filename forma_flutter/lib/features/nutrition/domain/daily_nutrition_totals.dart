class DailyNutritionTotals {
  const DailyNutritionTotals({
    required this.day,
    required this.calories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.sugarGrams,
    required this.sodiumMilligrams,
    required this.potassiumMilligrams,
  });

  final DateTime day;
  final double calories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final double fiberGrams;
  final double sugarGrams;
  final double sodiumMilligrams;
  final double potassiumMilligrams;

  bool get hasIntake =>
      calories > 0 ||
      proteinGrams > 0 ||
      carbGrams > 0 ||
      fatGrams > 0 ||
      fiberGrams > 0 ||
      sugarGrams > 0 ||
      sodiumMilligrams > 0 ||
      potassiumMilligrams > 0;

  Map<String, double> toMacroMap() {
    return <String, double>{
      'calories': calories,
      'protein_g': proteinGrams,
      'carbs_g': carbGrams,
      'fat_g': fatGrams,
    };
  }

  Map<String, double> toMicroMap() {
    return <String, double>{
      'fiber_g': fiberGrams,
      'sugar_g': sugarGrams,
      'sodium_mg': sodiumMilligrams,
      'potassium_mg': potassiumMilligrams,
    };
  }
}
