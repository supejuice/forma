import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/calorie_trend_point.dart';
import '../domain/date_range_filter.dart';
import '../domain/meal_log_entry.dart';
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

  static Future<Database> open() async {
    final String directory = await getDatabasesPath();
    final String dbPath = path.join(directory, 'forma_nutrition.db');
    return openDatabase(
      dbPath,
      version: 1,
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

        await db.insert('settings', <String, Object>{
          'key': 'daily_calorie_target',
          'value': '1900',
        });
      },
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
  Future<void> saveDailyCalorieTarget(int targetCalories) async {
    final Database db = await _database;
    await db.insert('settings', <String, Object>{
      'key': 'daily_calorie_target',
      'value': targetCalories.toString(),
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

  String _dayKey(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  DateTime _dayStart(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
