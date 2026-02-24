import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_exception.dart';
import '../../settings/application/api_key_controller.dart';
import '../domain/meal_log_entry.dart';
import '../infrastructure/mistral_nutrition_flow.dart';
import '../infrastructure/sqlite_nutrition_repository.dart';
import 'nutrition_providers.dart';

final NotifierProvider<MealEntryController, MealEntryState>
mealEntryControllerProvider =
    NotifierProvider<MealEntryController, MealEntryState>(
      MealEntryController.new,
    );

class MealEntryState {
  const MealEntryState({
    required this.isSubmitting,
    required this.latestEntry,
    required this.errorMessage,
    required this.statusMessage,
  });

  const MealEntryState.initial()
    : isSubmitting = false,
      latestEntry = null,
      errorMessage = null,
      statusMessage = null;

  final bool isSubmitting;
  final MealLogEntry? latestEntry;
  final String? errorMessage;
  final String? statusMessage;

  MealEntryState copyWith({
    bool? isSubmitting,
    MealLogEntry? latestEntry,
    bool resetLatestEntry = false,
    String? errorMessage,
    bool clearError = false,
    String? statusMessage,
    bool clearStatus = false,
  }) {
    return MealEntryState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      latestEntry: resetLatestEntry ? null : (latestEntry ?? this.latestEntry),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

class MealEntryController extends Notifier<MealEntryState> {
  @override
  MealEntryState build() => const MealEntryState.initial();

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearStatus() {
    state = state.copyWith(clearStatus: true);
  }

  Future<void> submitMeal(String rawMealText) async {
    final String mealText = rawMealText.trim();
    if (mealText.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Enter what you ate first.',
        clearStatus: true,
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearStatus: true,
    );

    try {
      final String? apiKey = switch (ref.read(apiKeyControllerProvider)) {
        AsyncData<String?>(:final value) => value,
        _ => null,
      };
      if (apiKey == null || apiKey.trim().isEmpty) {
        throw const AppException('Add a Mistral API key before logging meals.');
      }

      final flow = ref.read(nutritionFlowProvider);
      final extraction = await flow.extract(
        apiKey: apiKey,
        mealText: mealText.trim(),
      );

      final MealLogEntry entry = extraction.toMealLogEntry(rawText: mealText);
      final MealLogEntry savedEntry = await ref
          .read(nutritionRepositoryProvider)
          .saveMealLog(entry);

      state = state.copyWith(
        isSubmitting: false,
        latestEntry: savedEntry,
        statusMessage: 'Meal saved successfully.',
        clearError: true,
      );

      ref.invalidate(recentMealsProvider);
      ref.invalidate(recentMealTextsProvider);
      ref.invalidate(calorieTrendProvider);
    } on AppException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
        clearStatus: true,
      );
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to log meal right now. Please retry.',
        clearStatus: true,
      );
    }
  }
}
