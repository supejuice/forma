import 'package:flutter_test/flutter_test.dart';
import 'package:forma_flutter/core/app_exception.dart';
import 'package:forma_flutter/features/nutrition/domain/calorie_target_calculator.dart';

void main() {
  test('calculates target using Mifflin-St Jeor + activity + goal', () {
    const CalorieTargetInputs input = CalorieTargetInputs(
      sex: BiologicalSex.female,
      ageYears: 30,
      heightCm: 165,
      weightKg: 70,
      activityLevel: ActivityLevel.moderatelyActive,
      goalPace: GoalPace.loseSteady,
    );

    final CalorieTargetResult result = calculateScientificTarget(input);

    expect(result.bmr, closeTo(1420.25, 0.01));
    expect(result.estimatedTdee, closeTo(2201.38, 0.01));
    expect(result.goalAdjustment, -275);
    expect(result.targetCalories, 1926);
  });

  test('applies sex-based minimum floor for aggressive deficit', () {
    const CalorieTargetInputs maleInput = CalorieTargetInputs(
      sex: BiologicalSex.male,
      ageYears: 35,
      heightCm: 175,
      weightKg: 60,
      activityLevel: ActivityLevel.sedentary,
      goalPace: GoalPace.loseFast,
    );
    const CalorieTargetInputs femaleInput = CalorieTargetInputs(
      sex: BiologicalSex.female,
      ageYears: 35,
      heightCm: 175,
      weightKg: 60,
      activityLevel: ActivityLevel.sedentary,
      goalPace: GoalPace.loseFast,
    );

    final CalorieTargetResult male = calculateScientificTarget(maleInput);
    final CalorieTargetResult female = calculateScientificTarget(femaleInput);

    expect(male.targetCalories, 1500);
    expect(female.targetCalories, 1200);
  });

  test('throws AppException for invalid inputs', () {
    expect(
      () => calculateScientificTarget(
        const CalorieTargetInputs(
          sex: BiologicalSex.female,
          ageYears: 12,
          heightCm: 165,
          weightKg: 60,
          activityLevel: ActivityLevel.lightlyActive,
          goalPace: GoalPace.maintain,
        ),
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('estimates body fat with US Navy method when metrics provided', () {
    const CalorieProfile profile = CalorieProfile(
      sex: BiologicalSex.male,
      ageYears: 32,
      heightCm: 178,
      weightKg: 82,
      activityLevel: ActivityLevel.moderatelyActive,
      goalPace: GoalPace.maintain,
      neckCm: 40,
      waistCm: 92,
      hipCm: 100,
    );

    final BodyCompositionEstimate? estimate = estimateBodyComposition(profile);

    expect(estimate, isNotNull);
    expect(estimate!.bodyFatPercent, closeTo(26.7, 0.6));
    expect(estimate.categoryLabel, isNotEmpty);
    expect(estimate.waistToHeightRatio, closeTo(0.52, 0.01));
  });

  test('round-trips calorie profile json', () {
    const CalorieProfile profile = CalorieProfile(
      sex: BiologicalSex.female,
      ageYears: 28,
      heightCm: 165.2,
      weightKg: 61.4,
      activityLevel: ActivityLevel.lightlyActive,
      goalPace: GoalPace.loseSteady,
      neckCm: 33.2,
      waistCm: 74.5,
      hipCm: 96.1,
    );

    final Map<String, dynamic> json = profile.toJson();
    final CalorieProfile restored = CalorieProfile.fromJson(json);

    expect(restored.sex, profile.sex);
    expect(restored.ageYears, profile.ageYears);
    expect(restored.heightCm, closeTo(profile.heightCm, 0.001));
    expect(restored.weightKg, closeTo(profile.weightKg, 0.001));
    expect(restored.activityLevel, profile.activityLevel);
    expect(restored.goalPace, profile.goalPace);
    expect(restored.neckCm, closeTo(profile.neckCm!, 0.001));
    expect(restored.waistCm, closeTo(profile.waistCm!, 0.001));
    expect(restored.hipCm, closeTo(profile.hipCm!, 0.001));
  });
}
