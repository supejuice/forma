import 'package:flutter_test/flutter_test.dart';
import 'package:forma_flutter/features/nutrition/domain/mistral_usage_ledger.dart';

void main() {
  test(
    'records request usage and computes remaining against monthly limit',
    () {
      final MistralUsageLedger base = MistralUsageLedger.initial(
        now: DateTime(2026, 3, 3),
      ).withMonthlyLimit(1000);

      final MistralUsageLedger updated = base.withRecordedRequest(
        const MistralTokenUsage(
          promptTokens: 120,
          completionTokens: 80,
          totalTokens: 200,
        ),
        now: DateTime(2026, 3, 3, 10, 30),
      );

      expect(updated.cyclePromptTokens, 120);
      expect(updated.cycleCompletionTokens, 80);
      expect(updated.cycleTotalTokens, 200);
      expect(updated.lifetimeTotalTokens, 200);
      expect(updated.remainingMonthlyTokens, 800);
      expect(updated.overLimitTokens, 0);
      expect(updated.lastRequestUsage?.totalTokens, 200);
    },
  );

  test('rolls cycle at month boundary while keeping lifetime and limit', () {
    const MistralUsageLedger ledger = MistralUsageLedger(
      cycleYear: 2026,
      cycleMonth: 2,
      cyclePromptTokens: 600,
      cycleCompletionTokens: 400,
      cycleTotalTokens: 1000,
      lifetimeTotalTokens: 2500,
      monthlyLimitTokens: 5000,
      lastRequestUsage: MistralTokenUsage(
        promptTokens: 50,
        completionTokens: 30,
        totalTokens: 80,
      ),
      lastRequestAt: null,
    );

    final MistralUsageLedger normalized = ledger.normalizedFor(
      DateTime(2026, 3, 1),
    );

    expect(normalized.cycleYear, 2026);
    expect(normalized.cycleMonth, 3);
    expect(normalized.cycleTotalTokens, 0);
    expect(normalized.lifetimeTotalTokens, 2500);
    expect(normalized.monthlyLimitTokens, 5000);
  });
}
