import 'dart:math' as math;

class MistralTokenUsage {
  const MistralTokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory MistralTokenUsage.fromJson(Map<String, dynamic> json) {
    final int prompt = _asInt(json['prompt_tokens']);
    final int completion = _asInt(json['completion_tokens']);
    final int total = _asInt(json['total_tokens']);
    final int resolvedTotal = total > 0 ? total : (prompt + completion);
    return MistralTokenUsage(
      promptTokens: math.max(0, prompt),
      completionTokens: math.max(0, completion),
      totalTokens: math.max(0, resolvedTotal),
    );
  }

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }
}

class MistralUsageLedger {
  const MistralUsageLedger({
    required this.cycleYear,
    required this.cycleMonth,
    required this.cyclePromptTokens,
    required this.cycleCompletionTokens,
    required this.cycleTotalTokens,
    required this.lifetimeTotalTokens,
    required this.monthlyLimitTokens,
    required this.lastRequestUsage,
    required this.lastRequestAt,
  });

  factory MistralUsageLedger.initial({DateTime? now}) {
    final DateTime resolved = now ?? DateTime.now();
    return MistralUsageLedger(
      cycleYear: resolved.year,
      cycleMonth: resolved.month,
      cyclePromptTokens: 0,
      cycleCompletionTokens: 0,
      cycleTotalTokens: 0,
      lifetimeTotalTokens: 0,
      monthlyLimitTokens: null,
      lastRequestUsage: null,
      lastRequestAt: null,
    );
  }

  factory MistralUsageLedger.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    return MistralUsageLedger(
      cycleYear: _asInt(json['cycle_year'], fallback: now.year),
      cycleMonth: _asInt(json['cycle_month'], fallback: now.month).clamp(1, 12),
      cyclePromptTokens: math.max(0, _asInt(json['cycle_prompt_tokens'])),
      cycleCompletionTokens: math.max(
        0,
        _asInt(json['cycle_completion_tokens']),
      ),
      cycleTotalTokens: math.max(0, _asInt(json['cycle_total_tokens'])),
      lifetimeTotalTokens: math.max(0, _asInt(json['lifetime_total_tokens'])),
      monthlyLimitTokens: _nullableInt(json['monthly_limit_tokens']),
      lastRequestUsage: _mapValue(json['last_request_usage']),
      lastRequestAt: _dateTimeValue(json['last_request_at']),
    );
  }

  final int cycleYear;
  final int cycleMonth;
  final int cyclePromptTokens;
  final int cycleCompletionTokens;
  final int cycleTotalTokens;
  final int lifetimeTotalTokens;
  final int? monthlyLimitTokens;
  final MistralTokenUsage? lastRequestUsage;
  final DateTime? lastRequestAt;

  int? get remainingMonthlyTokens {
    final int? limit = monthlyLimitTokens;
    if (limit == null) {
      return null;
    }
    return math.max(0, limit - cycleTotalTokens);
  }

  int? get overLimitTokens {
    final int? limit = monthlyLimitTokens;
    if (limit == null) {
      return null;
    }
    return math.max(0, cycleTotalTokens - limit);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cycle_year': cycleYear,
      'cycle_month': cycleMonth,
      'cycle_prompt_tokens': cyclePromptTokens,
      'cycle_completion_tokens': cycleCompletionTokens,
      'cycle_total_tokens': cycleTotalTokens,
      'lifetime_total_tokens': lifetimeTotalTokens,
      'monthly_limit_tokens': monthlyLimitTokens,
      'last_request_usage': lastRequestUsage?.toJson(),
      'last_request_at': lastRequestAt?.toIso8601String(),
    };
  }

  MistralUsageLedger normalizedFor(DateTime now) {
    if (cycleYear == now.year && cycleMonth == now.month) {
      return this;
    }
    return MistralUsageLedger(
      cycleYear: now.year,
      cycleMonth: now.month,
      cyclePromptTokens: 0,
      cycleCompletionTokens: 0,
      cycleTotalTokens: 0,
      lifetimeTotalTokens: lifetimeTotalTokens,
      monthlyLimitTokens: monthlyLimitTokens,
      lastRequestUsage: lastRequestUsage,
      lastRequestAt: lastRequestAt,
    );
  }

  MistralUsageLedger withMonthlyLimit(int? limitTokens) {
    return MistralUsageLedger(
      cycleYear: cycleYear,
      cycleMonth: cycleMonth,
      cyclePromptTokens: cyclePromptTokens,
      cycleCompletionTokens: cycleCompletionTokens,
      cycleTotalTokens: cycleTotalTokens,
      lifetimeTotalTokens: lifetimeTotalTokens,
      monthlyLimitTokens: limitTokens,
      lastRequestUsage: lastRequestUsage,
      lastRequestAt: lastRequestAt,
    );
  }

  MistralUsageLedger withRecordedRequest(
    MistralTokenUsage usage, {
    DateTime? now,
  }) {
    final DateTime resolvedNow = now ?? DateTime.now();
    final MistralUsageLedger current = normalizedFor(resolvedNow);
    return MistralUsageLedger(
      cycleYear: current.cycleYear,
      cycleMonth: current.cycleMonth,
      cyclePromptTokens: current.cyclePromptTokens + usage.promptTokens,
      cycleCompletionTokens:
          current.cycleCompletionTokens + usage.completionTokens,
      cycleTotalTokens: current.cycleTotalTokens + usage.totalTokens,
      lifetimeTotalTokens: current.lifetimeTotalTokens + usage.totalTokens,
      monthlyLimitTokens: current.monthlyLimitTokens,
      lastRequestUsage: usage,
      lastRequestAt: resolvedNow,
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static MistralTokenUsage? _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return MistralTokenUsage.fromJson(value);
    }
    if (value is Map<dynamic, dynamic>) {
      return MistralTokenUsage.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    final int parsed = _asInt(value, fallback: -1);
    if (parsed < 0) {
      return null;
    }
    return parsed;
  }
}
