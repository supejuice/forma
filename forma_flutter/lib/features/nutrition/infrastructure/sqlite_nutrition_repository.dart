import 'dart:collection';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/calorie_trend_point.dart';
import '../domain/calorie_target_calculator.dart';
import '../domain/daily_feedback_entry.dart';
import '../domain/daily_nutrition_totals.dart';
import '../domain/date_range_filter.dart';
import '../domain/meal_log_entry.dart';
import '../domain/mistral_usage_ledger.dart';
import '../domain/nutrition_data.dart';
import 'nutrition_repository.dart';

final Provider<NutritionRepository> nutritionRepositoryProvider =
    Provider<NutritionRepository>((Ref ref) {
      final Future<Database> database = SqliteNutritionRepository.open();
      ref.onDispose(() {
        database.then((Database db) => db.close());
      });
      return SqliteNutritionRepository(database);
    });

class SqliteNutritionRepository implements NutritionRepository {
  SqliteNutritionRepository(this._database);

  final Future<Database> _database;

  static const int _dbVersion = 2;

  static Future<Database> open() async {
    final String directory = await getDatabasesPath();
    final String dbPath = path.join(directory, 'forma_nutrition.db');
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE meal_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            raw_text TEXT NOT NULL,
            summary TEXT NOT NULL,
            logged_at TEXT NOT NULL,
            calories REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL,
            fiber_g REAL NOT NULL,
            sugar_g REAL NOT NULL,
            sodium_mg REAL NOT NULL,
            potassium_mg REAL NOT NULL,
            confidence REAL NOT NULL,
            notes TEXT NOT NULL
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_meal_logs_logged_at ON meal_logs(logged_at);',
        );

        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          );
        ''');

        await _createDailyFeedbackTable(db);

        await db.insert('settings', <String, Object>{
          'key': 'daily_calorie_target',
          'value': '1900',
        });
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await _addPotassiumColumnIfMissing(db);
          await _createDailyFeedbackTable(db);
        }
      },
    );
  }

  static Future<void> _addPotassiumColumnIfMissing(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE meal_logs ADD COLUMN potassium_mg REAL NOT NULL DEFAULT 0;',
      );
    } on DatabaseException {
      // Column may already exist for migrated environments.
    }
  }

  static Future<void> _createDailyFeedbackTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_feedback_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL UNIQUE,
        one_liner TEXT NOT NULL,
        calories REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        fiber_g REAL NOT NULL,
        sugar_g REAL NOT NULL,
        sodium_mg REAL NOT NULL,
        potassium_mg REAL NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_daily_feedback_day ON daily_feedback_logs(day);',
    );
  }

  @override
  Future<List<CalorieTrendPoint>> calorieTrend(DateRangeFilter range) async {
    final DateRangeFilter normalized = range.normalized();
    final Database db = await _database;

    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT substr(logged_at, 1, 10) AS day, SUM(calories) AS total_calories '
      'FROM meal_logs '
      'WHERE logged_at >= ? AND logged_at <= ? '
      'GROUP BY day '
      'ORDER BY day ASC',
      <Object?>[
        _dayStart(normalized.start).toIso8601String(),
        _dayEnd(normalized.end).toIso8601String(),
      ],
    );

    final Map<String, double> totalsByDay = <String, double>{};
    for (final Map<String, Object?> row in rows) {
      final String? day = row['day'] as String?;
      if (day == null) {
        continue;
      }
      totalsByDay[day] = _asDouble(row['total_calories']);
    }

    final List<CalorieTrendPoint> points = <CalorieTrendPoint>[];
    for (int i = 0; i < normalized.dayCount; i++) {
      final DateTime day = normalized.start.add(Duration(days: i));
      final String dayKey = _dayKey(day);
      points.add(
        CalorieTrendPoint(date: day, calories: totalsByDay[dayKey] ?? 0),
      );
    }

    return points;
  }

  @override
  Future<DailyNutritionTotals> dailyNutritionTotals(DateTime day) async {
    final DateTime normalizedDay = _dayStart(day);
    final String dayKey = _dayKey(normalizedDay);
    final Database db = await _database;

    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT '
      'SUM(calories) AS calories, '
      'SUM(protein_g) AS protein_g, '
      'SUM(carbs_g) AS carbs_g, '
      'SUM(fat_g) AS fat_g, '
      'SUM(fiber_g) AS fiber_g, '
      'SUM(sugar_g) AS sugar_g, '
      'SUM(sodium_mg) AS sodium_mg, '
      'SUM(potassium_mg) AS potassium_mg '
      'FROM meal_logs '
      'WHERE substr(logged_at, 1, 10) = ?',
      <Object?>[dayKey],
    );

    if (rows.isEmpty) {
      return DailyNutritionTotals(
        day: normalizedDay,
        calories: 0,
        proteinGrams: 0,
        carbGrams: 0,
        fatGrams: 0,
        fiberGrams: 0,
        sugarGrams: 0,
        sodiumMilligrams: 0,
        potassiumMilligrams: 0,
      );
    }

    final Map<String, Object?> row = rows.first;
    return DailyNutritionTotals(
      day: normalizedDay,
      calories: _asDouble(row['calories']),
      proteinGrams: _asDouble(row['protein_g']),
      carbGrams: _asDouble(row['carbs_g']),
      fatGrams: _asDouble(row['fat_g']),
      fiberGrams: _asDouble(row['fiber_g']),
      sugarGrams: _asDouble(row['sugar_g']),
      sodiumMilligrams: _asDouble(row['sodium_mg']),
      potassiumMilligrams: _asDouble(row['potassium_mg']),
    );
  }

  @override
  Future<List<DateTime>> pendingDailyFeedbackDays({int limit = 7}) async {
    final Database db = await _database;
    final String todayKey = _dayKey(DateTime.now());

    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT DISTINCT substr(m.logged_at, 1, 10) AS day '
      'FROM meal_logs m '
      'LEFT JOIN daily_feedback_logs d ON d.day = substr(m.logged_at, 1, 10) '
      'WHERE d.day IS NULL AND substr(m.logged_at, 1, 10) < ? '
      'ORDER BY day ASC '
      'LIMIT ?',
      <Object?>[todayKey, limit],
    );

    return rows
        .map((Map<String, Object?> row) => row['day'] as String? ?? '')
        .where((String value) => value.isNotEmpty)
        .map(_dayFromKey)
        .toList(growable: false);
  }

  @override
  Future<int?> readDailyCalorieTarget() async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'settings',
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>['daily_calorie_target'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final Object? value = rows.first['value'];
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  Future<DailyFeedbackEntry?> readDailyFeedback(DateTime day) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'daily_feedback_logs',
      where: 'day = ?',
      whereArgs: <Object?>[_dayKey(day)],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _dailyFeedbackFromRow(rows.first);
  }

  @override
  Future<List<MealLogEntry>> recentMeals({int limit = 20}) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'meal_logs',
      orderBy: 'logged_at DESC',
      limit: limit,
    );

    return rows.map(_entryFromRow).toList(growable: false);
  }

  @override
  Future<List<DailyFeedbackEntry>> recentDailyFeedback({int limit = 14}) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'daily_feedback_logs',
      orderBy: 'day DESC',
      limit: limit,
    );

    return rows.map(_dailyFeedbackFromRow).toList(growable: false);
  }

  @override
  Future<List<String>> recentMealTexts({int limit = 10}) async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'meal_logs',
      columns: <String>['raw_text'],
      orderBy: 'logged_at DESC',
      limit: 120,
    );

    final LinkedHashSet<String> deduplicated = LinkedHashSet<String>();
    for (final Map<String, Object?> row in rows) {
      final String text = (row['raw_text'] as String? ?? '').trim();
      if (text.isEmpty) {
        continue;
      }
      deduplicated.add(text);
      if (deduplicated.length >= limit) {
        break;
      }
    }
    return deduplicated.toList(growable: false);
  }

  @override
  Future<MistralUsageLedger?> readMistralUsageLedger() async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'settings',
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>['mistral_usage_ledger_v1'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final Object? value = rows.first['value'];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> payload =
          (jsonDecode(value) as Map<dynamic, dynamic>).cast<String, dynamic>();
      return MistralUsageLedger.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CalorieProfile?> readCalorieProfile() async {
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.query(
      'settings',
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>['calorie_profile_v1'],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final Object? value = rows.first['value'];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> payload =
          (jsonDecode(value) as Map<dynamic, dynamic>).cast<String, dynamic>();
      return CalorieProfile.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDailyCalorieTarget(int targetCalories) async {
    final Database db = await _database;
    await db.insert('settings', <String, Object>{
      'key': 'daily_calorie_target',
      'value': targetCalories.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveCalorieProfile(CalorieProfile profile) async {
    final Database db = await _database;
    await db.insert('settings', <String, Object>{
      'key': 'calorie_profile_v1',
      'value': jsonEncode(profile.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveDailyFeedback(DailyFeedbackEntry entry) async {
    final Database db = await _database;
    await db.insert('daily_feedback_logs', <String, Object>{
      'day': _dayKey(entry.day),
      'one_liner': entry.oneLiner,
      'calories': entry.totals.calories,
      'protein_g': entry.totals.proteinGrams,
      'carbs_g': entry.totals.carbGrams,
      'fat_g': entry.totals.fatGrams,
      'fiber_g': entry.totals.fiberGrams,
      'sugar_g': entry.totals.sugarGrams,
      'sodium_mg': entry.totals.sodiumMilligrams,
      'potassium_mg': entry.totals.potassiumMilligrams,
      'created_at': entry.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveMistralUsageLedger(MistralUsageLedger ledger) async {
    final Database db = await _database;
    await db.insert('settings', <String, Object>{
      'key': 'mistral_usage_ledger_v1',
      'value': jsonEncode(ledger.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<MealLogEntry> saveMealLog(MealLogEntry entry) async {
    final Database db = await _database;
    final int id = await db.insert('meal_logs', <String, Object>{
      'raw_text': entry.rawText,
      'summary': entry.summary,
      'logged_at': entry.loggedAt.toIso8601String(),
      'calories': entry.nutrition.calories,
      'protein_g': entry.nutrition.proteinGrams,
      'carbs_g': entry.nutrition.carbGrams,
      'fat_g': entry.nutrition.fatGrams,
      'fiber_g': entry.nutrition.fiberGrams,
      'sugar_g': entry.nutrition.sugarGrams,
      'sodium_mg': entry.nutrition.sodiumMilligrams,
      'potassium_mg': entry.nutrition.potassiumMilligrams,
      'confidence': entry.confidence,
      'notes': entry.notes,
    });
    return entry.copyWith(id: id);
  }

  @override
  Future<double> totalCalories(DateRangeFilter range) async {
    final DateRangeFilter normalized = range.normalized();
    final Database db = await _database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT SUM(calories) AS total_calories '
      'FROM meal_logs '
      'WHERE logged_at >= ? AND logged_at <= ?',
      <Object?>[
        _dayStart(normalized.start).toIso8601String(),
        _dayEnd(normalized.end).toIso8601String(),
      ],
    );

    if (rows.isEmpty) {
      return 0;
    }
    return _asDouble(rows.first['total_calories']);
  }

  DailyFeedbackEntry _dailyFeedbackFromRow(Map<String, Object?> row) {
    final DateTime day = _dayFromKey(row['day'] as String? ?? '');
    return DailyFeedbackEntry(
      id: row['id'] as int?,
      day: day,
      oneLiner: row['one_liner'] as String? ?? '',
      totals: DailyNutritionTotals(
        day: day,
        calories: _asDouble(row['calories']),
        proteinGrams: _asDouble(row['protein_g']),
        carbGrams: _asDouble(row['carbs_g']),
        fatGrams: _asDouble(row['fat_g']),
        fiberGrams: _asDouble(row['fiber_g']),
        sugarGrams: _asDouble(row['sugar_g']),
        sodiumMilligrams: _asDouble(row['sodium_mg']),
        potassiumMilligrams: _asDouble(row['potassium_mg']),
      ),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  MealLogEntry _entryFromRow(Map<String, Object?> row) {
    return MealLogEntry(
      id: row['id'] as int?,
      rawText: row['raw_text'] as String? ?? '',
      summary: row['summary'] as String? ?? '',
      loggedAt:
          DateTime.tryParse(row['logged_at'] as String? ?? '') ??
          DateTime.now(),
      nutrition: NutritionData(
        calories: _asDouble(row['calories']),
        proteinGrams: _asDouble(row['protein_g']),
        carbGrams: _asDouble(row['carbs_g']),
        fatGrams: _asDouble(row['fat_g']),
        fiberGrams: _asDouble(row['fiber_g']),
        sugarGrams: _asDouble(row['sugar_g']),
        sodiumMilligrams: _asDouble(row['sodium_mg']),
        potassiumMilligrams: _asDouble(row['potassium_mg']),
      ),
      confidence: _asDouble(row['confidence']).clamp(0, 1).toDouble(),
      notes: row['notes'] as String? ?? '',
    );
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  DateTime _dayEnd(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  DateTime _dayFromKey(String dayKey) {
    final DateTime? parsed = DateTime.tryParse(dayKey);
    if (parsed == null) {
      final DateTime now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _dayKey(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  DateTime _dayStart(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
