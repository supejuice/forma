import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_exception.dart';
import '../domain/daily_nutrition_totals.dart';
import '../domain/mistral_usage_ledger.dart';
import 'mistral_api_client.dart';

final Provider<MistralDailyFeedbackFlow> dailyFeedbackFlowProvider =
    Provider<MistralDailyFeedbackFlow>((Ref ref) {
      return MistralDailyFeedbackFlow(
        client: ref.read(mistralApiClientProvider),
      );
    });

class DailyFeedbackResult {
  const DailyFeedbackResult({required this.oneLiner, this.usage});

  final String oneLiner;
  final MistralTokenUsage? usage;
}

class MistralDailyFeedbackFlow {
  const MistralDailyFeedbackFlow({required this.client});

  final MistralApiClient client;

  Future<DailyFeedbackResult> generate({
    required String apiKey,
    required DailyNutritionTotals totals,
  }) async {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final String dateLabel = dateFormat.format(totals.day);

    final String payload = jsonEncode(<String, Object>{
      'date': dateLabel,
      'macros': totals.toMacroMap(),
      'micros': totals.toMicroMap(),
    });

    final ChatCompletionResult completion = await client.chatCompletions(
      apiKey: apiKey,
      messages: <Map<String, String>>[
        <String, String>{'role': 'system', 'content': _systemPrompt},
        <String, String>{
          'role': 'user',
          'content': 'Daily nutrition totals (JSON): $payload',
        },
      ],
    );

    final String oneLiner = _parseOneLiner(completion.content);
    if (oneLiner.isEmpty) {
      throw const AppException('Unable to generate daily feedback one-liner.');
    }

    return DailyFeedbackResult(oneLiner: oneLiner, usage: completion.usage);
  }

  String fallbackOneLiner(DailyNutritionTotals totals) {
    final List<String> tips = <String>[];

    if (totals.proteinGrams < 70) {
      tips.add('protein was light');
    }
    if (totals.fiberGrams < 20) {
      tips.add('fiber was low');
    }
    if (totals.sodiumMilligrams > 2300) {
      tips.add('sodium ran high');
    }
    if (totals.sugarGrams > 50) {
      tips.add('sugar skewed high');
    }
    if (totals.potassiumMilligrams < 2600) {
      tips.add('potassium could be higher');
    }

    if (tips.isEmpty) {
      return 'Solid day overall: macros and key micros looked balanced for steady progress.';
    }

    final String joined = tips.take(2).join(' and ');
    return 'Decent day, but $joined; add whole foods tomorrow to tighten intake quality.';
  }

  String _parseOneLiner(String rawResponse) {
    final String jsonText = _extractJsonObject(rawResponse);
    final dynamic decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      return '';
    }
    final String value = (decoded['one_liner'] as String? ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    if (value.length <= 140) {
      return value;
    }
    return '${value.substring(0, math.min(137, value.length)).trimRight()}...';
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
      throw const AppException('Mistral response did not return JSON.');
    }

    return trimmed.substring(firstBrace, lastBrace + 1);
  }

  static const String _systemPrompt =
      'You are a concise nutrition coach. Use provided daily totals to produce one sentence. '
      'Return strict JSON only: {"one_liner": string}. '
      'Rules: sentence length <= 22 words, no emojis, no markdown, no lists, no medical diagnosis.';
}
