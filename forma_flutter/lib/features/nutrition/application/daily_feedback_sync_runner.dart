import '../domain/daily_feedback_entry.dart';
import '../domain/daily_nutrition_totals.dart';
import '../domain/mistral_usage_ledger.dart';
import '../infrastructure/mistral_daily_feedback_flow.dart';
import '../infrastructure/nutrition_repository.dart';
import 'daily_feedback_notification_service.dart';

class DailyFeedbackSyncRunner {
  const DailyFeedbackSyncRunner({
    required this.repository,
    required this.flow,
    required this.notificationService,
    required this.apiKey,
    this.onUsage,
    this.onSaved,
  });

  final NutritionRepository repository;
  final MistralDailyFeedbackFlow flow;
  final DailyFeedbackNotificationService notificationService;
  final String? apiKey;
  final Future<void> Function(MistralTokenUsage usage)? onUsage;
  final Future<void> Function(DailyFeedbackEntry entry)? onSaved;

  Future<void> run({int limit = 7}) async {
    final List<DateTime> pendingDays = await repository
        .pendingDailyFeedbackDays(limit: limit);
    if (pendingDays.isEmpty) {
      return;
    }

    await notificationService.ensureInitialized();

    for (final DateTime day in pendingDays) {
      final DailyNutritionTotals totals = await repository.dailyNutritionTotals(
        day,
      );
      if (!totals.hasIntake) {
        continue;
      }

      final String oneLiner = await _generateOneLiner(totals);
      final DailyFeedbackEntry entry = DailyFeedbackEntry(
        id: null,
        day: totals.day,
        oneLiner: oneLiner,
        totals: totals,
        createdAt: DateTime.now(),
      );

      await repository.saveDailyFeedback(entry);
      if (onSaved != null) {
        await onSaved!(entry);
      }
      await notificationService.showDailyFeedback(entry);
    }
  }

  Future<String> _generateOneLiner(DailyNutritionTotals totals) async {
    final String trimmedApiKey = apiKey?.trim() ?? '';
    if (trimmedApiKey.isEmpty) {
      return flow.fallbackOneLiner(totals);
    }

    try {
      final DailyFeedbackResult result = await flow.generate(
        apiKey: trimmedApiKey,
        totals: totals,
      );
      if (result.usage != null && onUsage != null) {
        await onUsage!(result.usage!);
      }
      return result.oneLiner;
    } catch (_) {
      return flow.fallbackOneLiner(totals);
    }
  }
}
