import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_exception.dart';
import '../domain/nutrition_data.dart';
import '../domain/nutrition_extraction.dart';
import 'mistral_api_client.dart';
import 'nutrition_flow.dart';

final Provider<NutritionFlow> nutritionFlowProvider = Provider<NutritionFlow>(
  (Ref ref) => MistralNutritionFlow(
    client: ref.watch(mistralApiClientProvider),
    promptFactory: const NutritionPromptFactory(),
    parser: const NutritionResponseParser(),
  ),
);

class MistralNutritionFlow implements NutritionFlow {
  const MistralNutritionFlow({
    required this.client,
    required this.promptFactory,
    required this.parser,
  });

  final MistralApiClient client;
  final NutritionPromptFactory promptFactory;
  final NutritionResponseParser parser;

  @override
  Future<NutritionExtraction> extract({
    required String apiKey,
    required String mealText,
  }) async {
    if (mealText.trim().isEmpty) {
      throw const AppException('Please enter what you ate first.');
    }

    final List<Map<String, String>> messages = promptFactory.messages(mealText);
    final ChatCompletionResult completion = await client.chatCompletions(
      apiKey: apiKey,
      messages: messages,
    );
    final NutritionExtraction parsed = parser.parse(
      completion.content,
      fallbackSummary: mealText,
    );
    return NutritionExtraction(
      summary: parsed.summary,
      nutrition: parsed.nutrition,
      confidence: parsed.confidence,
      notes: parsed.notes,
      usage: completion.usage,
    );
  }
}

class NutritionPromptFactory {
  const NutritionPromptFactory();

  List<Map<String, String>> messages(String mealText) {
    return <Map<String, String>>[
      <String, String>{'role': 'system', 'content': _systemPrompt},
      <String, String>{'role': 'user', 'content': mealText},
    ];
  }

  static const String _systemPrompt =
      'You are a nutrition extraction engine. Convert meal text into a strict JSON object only. '
      'Use realistic portion assumptions and total all listed foods. '
      'Output schema: '
      '{"meal_summary": string, "nutrition": {"calories": number, "protein_g": number, '
      '"carbs_g": number, "fat_g": number, "fiber_g": number, "sugar_g": number, "sodium_mg": number}, '
      '"confidence": number, "notes": string}. '
      'Rules: no markdown, no prose, confidence 0 to 1, no null values, nutrition numbers must be >= 0.';
}

class NutritionResponseParser {
  const NutritionResponseParser();

  NutritionExtraction parse(
    String rawResponse, {
    required String fallbackSummary,
  }) {
    final Map<String, dynamic> decoded = _decodeJsonMap(
      _extractJsonObject(rawResponse),
    );

    final Map<String, dynamic> nutritionMap = _mapValue(decoded, 'nutrition');
    final NutritionData nutrition =
        NutritionData(
          calories: _numericValue(nutritionMap, 'calories'),
          proteinGrams: _numericValue(nutritionMap, 'protein_g'),
          carbGrams: _numericValue(nutritionMap, 'carbs_g'),
          fatGrams: _numericValue(nutritionMap, 'fat_g'),
          fiberGrams: _numericValue(nutritionMap, 'fiber_g'),
          sugarGrams: _numericValue(nutritionMap, 'sugar_g'),
          sodiumMilligrams: _numericValue(nutritionMap, 'sodium_mg'),
        ).withFallbackCaloriesFromMacros();

    final String summary =
        _stringValue(decoded, 'meal_summary').trim().isEmpty
            ? fallbackSummary.trim()
            : _stringValue(decoded, 'meal_summary').trim();

    final String notes = _stringValue(decoded, 'notes').trim();

    return NutritionExtraction(
      summary: summary,
      nutrition: nutrition,
      confidence: _confidenceValue(decoded, 'confidence'),
      notes: notes,
    );
  }

  String _extractJsonObject(String rawResponse) {
    final String trimmed = rawResponse.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final RegExp fencedPattern = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    final RegExpMatch? match = fencedPattern.firstMatch(trimmed);
    if (match != null) {
      final String? captured = match.group(1);
      if (captured != null && captured.trim().isNotEmpty) {
        return captured.trim();
      }
    }

    final int firstBrace = trimmed.indexOf('{');
    final int lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace == -1 || lastBrace <= firstBrace) {
      throw const AppException(
        'Unable to parse nutrition data from Mistral response.',
      );
    }

    return trimmed.substring(firstBrace, lastBrace + 1);
  }

  Map<String, dynamic> _decodeJsonMap(String rawJson) {
    final dynamic decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const AppException('Mistral response must be a JSON object.');
    }
    return decoded;
  }

  Map<String, dynamic> _mapValue(Map<String, dynamic> map, String key) {
    final dynamic value = map[key];
    if (value is! Map<String, dynamic>) {
      throw AppException('Missing or invalid "$key" object in response.');
    }
    return value;
  }

  String _stringValue(Map<String, dynamic> map, String key) {
    final dynamic value = map[key];
    if (value is String) {
      return value;
    }
    return '';
  }

  double _confidenceValue(Map<String, dynamic> map, String key) {
    final double parsed = _asDouble(map[key], fallback: 0.68);
    return parsed.clamp(0, 1).toDouble();
  }

  double _numericValue(Map<String, dynamic> map, String key) {
    final double parsed = _asDouble(map[key], fallback: 0);
    return math.max(0, parsed);
  }

  double _asDouble(dynamic value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }
}
