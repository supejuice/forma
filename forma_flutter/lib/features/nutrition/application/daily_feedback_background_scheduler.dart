import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../../settings/data/api_key_storage.dart';
import '../domain/mistral_usage_ledger.dart';
import '../infrastructure/mistral_api_client.dart';
import '../infrastructure/mistral_daily_feedback_flow.dart';
import '../infrastructure/nutrition_repository.dart';
import '../infrastructure/sqlite_nutrition_repository.dart';
import 'daily_feedback_notification_service.dart';
import 'daily_feedback_sync_runner.dart';

const String dailyFeedbackTaskName = 'daily_feedback_end_of_day_task';
const String _dailyFeedbackTaskUniqueName =
    'daily_feedback_end_of_day_periodic';

class DailyFeedbackBackgroundScheduler {
  static Future<void> ensureScheduled() async {
    if (!_supportsBackgroundWorkmanager) {
      return;
    }

    await Workmanager().initialize(dailyFeedbackCallbackDispatcher);

    await Workmanager().registerPeriodicTask(
      _dailyFeedbackTaskUniqueName,
      dailyFeedbackTaskName,
      frequency: const Duration(hours: 1),
      initialDelay: _initialDelayToNearMidnight(),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }
}

@pragma('vm:entry-point')
void dailyFeedbackCallbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? _) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    if (task != dailyFeedbackTaskName) {
      return true;
    }

    try {
      final NutritionRepository repository = SqliteNutritionRepository(
        SqliteNutritionRepository.open(),
      );
      final MistralDailyFeedbackFlow flow = MistralDailyFeedbackFlow(
        client: MistralApiClient(
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 30),
            ),
          ),
        ),
      );
      final DailyFeedbackNotificationService notificationService =
          DailyFeedbackNotificationService(
            plugin: FlutterLocalNotificationsPlugin(),
          );
      final String? apiKey =
          await ResilientApiKeyStorage(
            primary: SecureApiKeyStorage(const FlutterSecureStorage()),
            fallback: SharedPrefsApiKeyStorage(),
          ).read();

      final DailyFeedbackSyncRunner runner = DailyFeedbackSyncRunner(
        repository: repository,
        flow: flow,
        notificationService: notificationService,
        apiKey: apiKey,
        onUsage: (MistralTokenUsage usage) async {
          final MistralUsageLedger current =
              (await repository.readMistralUsageLedger()) ??
              MistralUsageLedger.initial();
          final MistralUsageLedger normalized = current.normalizedFor(
            DateTime.now(),
          );
          final MistralUsageLedger updated = normalized.withRecordedRequest(
            usage,
          );
          await repository.saveMistralUsageLedger(updated);
        },
      );

      await runner.run(limit: 7);
      return true;
    } catch (_) {
      // Ask WorkManager to retry.
      return false;
    }
  });
}

bool get _supportsBackgroundWorkmanager {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Duration _initialDelayToNearMidnight() {
  final DateTime now = DateTime.now();
  final DateTime next = DateTime(now.year, now.month, now.day + 1, 0, 5);
  return next.difference(now);
}
