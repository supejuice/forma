import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/nutrition/application/daily_feedback_background_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DailyFeedbackBackgroundScheduler.ensureScheduled();
  runApp(const ProviderScope(child: FormaApp()));
}
