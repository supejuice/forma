import 'dart:math' as math;

import '../../../core/app_exception.dart';

enum BiologicalSex { male, female }

extension BiologicalSexLabel on BiologicalSex {
  String get label => this == BiologicalSex.male ? 'Male' : 'Female';
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

extension ActivityLevelData on ActivityLevel {
  String get label => switch (this) {
    ActivityLevel.sedentary => 'Sedentary (little/no exercise)',
    ActivityLevel.lightlyActive => 'Lightly active (1-3 days/week)',
    ActivityLevel.moderatelyActive => 'Moderately active (3-5 days/week)',
    ActivityLevel.veryActive => 'Very active (6-7 days/week)',
    ActivityLevel.extraActive => 'Extra active (athlete/manual labor)',
  };

  double get multiplier => switch (this) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.lightlyActive => 1.375,
    ActivityLevel.moderatelyActive => 1.55,
    ActivityLevel.veryActive => 1.725,
    ActivityLevel.extraActive => 1.9,
  };
}

enum GoalPace { loseFast, loseSteady, maintain, gainSteady, gainFast }

extension GoalPaceData on GoalPace {
  String get label => switch (this) {
    GoalPace.loseFast => 'Lose ~0.5 kg/week',
    GoalPace.loseSteady => 'Lose ~0.25 kg/week',
    GoalPace.maintain => 'Maintain weight',
    GoalPace.gainSteady => 'Gain ~0.25 kg/week',
    GoalPace.gainFast => 'Gain ~0.5 kg/week',
  };

  int get dailyAdjustment => switch (this) {
    GoalPace.loseFast => -550,
    GoalPace.loseSteady => -275,
    GoalPace.maintain => 0,
    GoalPace.gainSteady => 275,
    GoalPace.gainFast => 550,
  };
}

class CalorieTargetInputs {
  const CalorieTargetInputs({
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goalPace,
  });

  final BiologicalSex sex;
  final int ageYears;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final GoalPace goalPace;
}

class CalorieProfile {
  const CalorieProfile({
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goalPace,
    this.neckCm,
    this.waistCm,
    this.hipCm,
  });

  factory CalorieProfile.fromJson(Map<String, dynamic> json) {
    final String sexName =
        (json['sex'] as String?) ?? BiologicalSex.female.name;
    final String activityName =
        (json['activity_level'] as String?) ??
        ActivityLevel.moderatelyActive.name;
    final String goalName =
        (json['goal_pace'] as String?) ?? GoalPace.maintain.name;
    return CalorieProfile(
      sex: BiologicalSex.values.firstWhere(
        (BiologicalSex value) => value.name == sexName,
        orElse: () => BiologicalSex.female,
      ),
      ageYears: (json['age_years'] as num?)?.toInt() ?? 30,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 170,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 70,
      activityLevel: ActivityLevel.values.firstWhere(
        (ActivityLevel value) => value.name == activityName,
        orElse: () => ActivityLevel.moderatelyActive,
      ),
      goalPace: GoalPace.values.firstWhere(
        (GoalPace value) => value.name == goalName,
        orElse: () => GoalPace.maintain,
      ),
      neckCm: (json['neck_cm'] as num?)?.toDouble(),
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
      hipCm: (json['hip_cm'] as num?)?.toDouble(),
    );
  }

  final BiologicalSex sex;
  final int ageYears;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final GoalPace goalPace;
  final double? neckCm;
  final double? waistCm;
  final double? hipCm;

  CalorieTargetInputs toTargetInputs() {
    return CalorieTargetInputs(
      sex: sex,
      ageYears: ageYears,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goalPace: goalPace,
    );
  }

  CalorieProfile copyWith({
    BiologicalSex? sex,
    int? ageYears,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    GoalPace? goalPace,
    double? neckCm,
    bool clearNeck = false,
    double? waistCm,
    bool clearWaist = false,
    double? hipCm,
    bool clearHip = false,
  }) {
    return CalorieProfile(
      sex: sex ?? this.sex,
      ageYears: ageYears ?? this.ageYears,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalPace: goalPace ?? this.goalPace,
      neckCm: clearNeck ? null : (neckCm ?? this.neckCm),
      waistCm: clearWaist ? null : (waistCm ?? this.waistCm),
      hipCm: clearHip ? null : (hipCm ?? this.hipCm),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sex': sex.name,
      'age_years': ageYears,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel.name,
      'goal_pace': goalPace.name,
      'neck_cm': neckCm,
      'waist_cm': waistCm,
      'hip_cm': hipCm,
    };
  }
}

class CalorieTargetResult {
  const CalorieTargetResult({
    required this.bmr,
    required this.estimatedTdee,
    required this.goalAdjustment,
    required this.targetCalories,
  });

  final double bmr;
  final double estimatedTdee;
  final int goalAdjustment;
  final int targetCalories;
}

class BodyCompositionEstimate {
  const BodyCompositionEstimate({
    required this.bodyFatPercent,
    required this.fatMassKg,
    required this.leanMassKg,
    required this.waistToHeightRatio,
    required this.waistToHipRatio,
    required this.categoryLabel,
  });

  final double bodyFatPercent;
  final double fatMassKg;
  final double leanMassKg;
  final double waistToHeightRatio;
  final double? waistToHipRatio;
  final String categoryLabel;
}

class BodyShapeModel {
  const BodyShapeModel({
    required this.shoulderWidthFactor,
    required this.waistWidthFactor,
    required this.hipWidthFactor,
    required this.label,
  });

  final double shoulderWidthFactor;
  final double waistWidthFactor;
  final double hipWidthFactor;
  final String label;
}

CalorieTargetResult calculateScientificTarget(CalorieTargetInputs inputs) {
  if (inputs.ageYears < 13 || inputs.ageYears > 120) {
    throw const AppException('Age must be between 13 and 120.');
  }
  if (inputs.heightCm < 120 || inputs.heightCm > 250) {
    throw const AppException('Height must be between 120 and 250 cm.');
  }
  if (inputs.weightKg < 30 || inputs.weightKg > 350) {
    throw const AppException('Weight must be between 30 and 350 kg.');
  }

  final double sexOffset = inputs.sex == BiologicalSex.male ? 5 : -161;
  final double bmr =
      (10 * inputs.weightKg) +
      (6.25 * inputs.heightCm) -
      (5 * inputs.ageYears) +
      sexOffset;
  final double tdee = bmr * inputs.activityLevel.multiplier;
  final int adjustment = inputs.goalPace.dailyAdjustment;
  final int minimumCalories = inputs.sex == BiologicalSex.male ? 1500 : 1200;
  final int target = (tdee + adjustment).round().clamp(minimumCalories, 4200);

  return CalorieTargetResult(
    bmr: bmr,
    estimatedTdee: tdee,
    goalAdjustment: adjustment,
    targetCalories: target,
  );
}

CalorieTargetResult calculateScientificTargetFromProfile(
  CalorieProfile profile,
) {
  return calculateScientificTarget(profile.toTargetInputs());
}

BodyCompositionEstimate? estimateBodyComposition(CalorieProfile profile) {
  final double? neck = profile.neckCm;
  final double? waist = profile.waistCm;
  final double? hip = profile.hipCm;
  if (neck == null || waist == null) {
    return null;
  }
  if (profile.sex == BiologicalSex.female && hip == null) {
    return null;
  }
  if (neck <= 0 || waist <= 0) {
    throw const AppException('Neck and waist measurements must be positive.');
  }
  if (profile.sex == BiologicalSex.male) {
    if (waist <= neck) {
      throw const AppException(
        'For body-fat estimate, waist must be larger than neck.',
      );
    }
  } else {
    final double hipValue = hip!;
    if (hipValue <= 0) {
      throw const AppException('Hip measurement must be positive.');
    }
    if ((waist + hipValue) <= neck) {
      throw const AppException(
        'For body-fat estimate, waist + hip must be larger than neck.',
      );
    }
  }

  final double bodyFatPercent;
  if (profile.sex == BiologicalSex.male) {
    bodyFatPercent =
        (86.010 * math.log((waist - neck)) / math.ln10) -
        (70.041 * math.log(profile.heightCm) / math.ln10) +
        36.76;
  } else {
    final double hipValue = hip!;
    bodyFatPercent =
        (163.205 * math.log((waist + hipValue - neck)) / math.ln10) -
        (97.684 * math.log(profile.heightCm) / math.ln10) -
        78.387;
  }

  final double clamped = bodyFatPercent.clamp(2.0, 65.0);
  final double fatMassKg = profile.weightKg * (clamped / 100);
  final double leanMassKg = profile.weightKg - fatMassKg;
  final double waistToHeight = waist / profile.heightCm;
  final double? waistToHip = hip == null ? null : waist / hip;
  final String category = _bodyFatCategory(profile.sex, clamped);

  return BodyCompositionEstimate(
    bodyFatPercent: clamped,
    fatMassKg: fatMassKg,
    leanMassKg: leanMassKg,
    waistToHeightRatio: waistToHeight,
    waistToHipRatio: waistToHip,
    categoryLabel: category,
  );
}

BodyShapeModel buildBodyShapeModel(CalorieProfile profile) {
  final double waist = profile.waistCm ?? _estimatedWaistCm(profile);
  final double hip = profile.hipCm ?? (waist * 1.06);
  final double waistToHeight = waist / profile.heightCm;
  final double waistToHip = waist / hip;
  final bool male = profile.sex == BiologicalSex.male;

  final double shoulder = ((male ? 0.70 : 0.62) +
          ((0.52 - waistToHeight).clamp(-0.16, 0.16) * 0.35) +
          ((0.95 - waistToHip).clamp(-0.22, 0.22) * 0.18))
      .clamp(0.52, 0.84);
  final double waistWidth = ((male ? 0.50 : 0.44) +
          ((waistToHeight - 0.46).clamp(-0.2, 0.2) * 0.85))
      .clamp(0.30, 0.72);
  final double hipWidth = ((male ? 0.56 : 0.66) +
          (((hip / profile.heightCm) - 0.54).clamp(-0.12, 0.12) * 0.95))
      .clamp(0.44, 0.78);

  return BodyShapeModel(
    shoulderWidthFactor: shoulder,
    waistWidthFactor: waistWidth,
    hipWidthFactor: hipWidth,
    label: _shapeLabel(profile.sex, waistToHeight, waistToHip),
  );
}

double _estimatedWaistCm(CalorieProfile profile) {
  final double heightM = profile.heightCm / 100;
  final double bmi = profile.weightKg / (heightM * heightM);
  return profile.heightCm * (0.43 + ((bmi - 22).clamp(-8, 14) * 0.007));
}

String _bodyFatCategory(BiologicalSex sex, double bodyFatPercent) {
  if (sex == BiologicalSex.male) {
    if (bodyFatPercent < 6) {
      return 'Essential fat range';
    }
    if (bodyFatPercent < 14) {
      return 'Athletic range';
    }
    if (bodyFatPercent < 18) {
      return 'Fitness range';
    }
    if (bodyFatPercent < 25) {
      return 'Average range';
    }
    return 'High range';
  }

  if (bodyFatPercent < 14) {
    return 'Essential fat range';
  }
  if (bodyFatPercent < 21) {
    return 'Athletic range';
  }
  if (bodyFatPercent < 25) {
    return 'Fitness range';
  }
  if (bodyFatPercent < 32) {
    return 'Average range';
  }
  return 'High range';
}

String _shapeLabel(BiologicalSex sex, double waistToHeight, double waistToHip) {
  if (waistToHeight >= 0.62) {
    return 'Round';
  }
  if (sex == BiologicalSex.female) {
    if (waistToHip < 0.75) {
      return 'Pear';
    }
    if (waistToHip <= 0.86) {
      return 'Hourglass';
    }
    return 'Apple';
  }
  if (waistToHip < 0.9) {
    return 'V-shape';
  }
  if (waistToHip <= 1.0) {
    return 'Rectangle';
  }
  return 'Oval';
}
