import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../domain/daily_feedback_entry.dart';

final Provider<DailyFeedbackNotificationService>
dailyFeedbackNotificationServiceProvider =
    Provider<DailyFeedbackNotificationService>((Ref ref) {
      return DailyFeedbackNotificationService(
        plugin: FlutterLocalNotificationsPlugin(),
      );
    });

class DailyFeedbackNotificationService {
  DailyFeedbackNotificationService({
    required FlutterLocalNotificationsPlugin plugin,
  }) : _plugin = plugin;

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initFuture;

  Future<void> ensureInitialized() {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return _initFuture ??= _initialize();
  }

  Future<void> showDailyFeedback(DailyFeedbackEntry entry) async {
    if (kIsWeb) {
      return;
    }

    try {
      await ensureInitialized();
      final DateFormat formatter = DateFormat('MMM d');
      await _plugin.show(
        _notificationId(entry.day),
        'Daily intake feedback',
        '${formatter.format(entry.day)}: ${entry.oneLiner}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_intake_feedback',
            'Daily Intake Feedback',
            channelDescription:
                'One-line end-of-day nutrition quality feedback.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Non-fatal: notification delivery should not block persistence.
    }
  }

  Future<void> _initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int _notificationId(DateTime day) {
    return day.year * 10000 + day.month * 100 + day.day;
  }
}
