import 'package:intl/intl.dart';

String formatCalories(double value) => '${value.toStringAsFixed(0)} kcal';

String formatGrams(double value) => '${value.toStringAsFixed(1)} g';

String formatMilligrams(double value) => '${value.toStringAsFixed(0)} mg';

String formatShortDate(DateTime dateTime) =>
    DateFormat('MMM d').format(dateTime);

String formatLongDate(DateTime dateTime) =>
    DateFormat('EEE, MMM d').format(dateTime);
