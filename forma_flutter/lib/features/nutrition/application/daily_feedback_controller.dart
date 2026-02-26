import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/api_key_controller.dart';
import '../domain/daily_feedback_entry.dart';
import '../domain/mistral_usage_ledger.dart';
import '../infrastructure/mistral_daily_feedback_flow.dart';
import '../infrastructure/sqlite_nutrition_repository.dart';
import 'daily_feedback_notification_service.dart';
import 'daily_feedback_sync_runner.dart';
import 'nutrition_providers.dart';

final FutureProvider<List<DailyFeedbackEntry>> recentDailyFeedbackProvider =
    FutureProvider<List<DailyFeedbackEntry>>((Ref ref) {
      return ref
          .read(nutritionRepositoryProvider)
          .recentDailyFeedback(limit: 20);
    });

final Provider<DailyFeedbackController> dailyFeedbackControllerProvider =
    Provider<DailyFeedbackController>(DailyFeedbackController.new);

class DailyFeedbackController {
  const DailyFeedbackController(this._ref);

  final Ref _ref;

  Future<void> syncPendingEndOfDayFeedback() async {
    final String? apiKey = switch (_ref.read(apiKeyControllerProvider)) {
      AsyncData<String?>(:final value) => value?.trim(),
      _ => null,
    };

    final DailyFeedbackSyncRunner runner = DailyFeedbackSyncRunner(
      repository: _ref.read(nutritionRepositoryProvider),
      flow: _ref.read(dailyFeedbackFlowProvider),
      notificationService: _ref.read(dailyFeedbackNotificationServiceProvider),
      apiKey: apiKey,
      onUsage: (MistralTokenUsage usage) async {
        await _ref
            .read(mistralUsageLedgerControllerProvider)
            .recordUsage(usage);
      },
      onSaved: (_) async {
        _ref.invalidate(recentDailyFeedbackProvider);
      },
    );
    await runner.run(limit: 7);
    _ref.invalidate(recentDailyFeedbackProvider);
  }
}
