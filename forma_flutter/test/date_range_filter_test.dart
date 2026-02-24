import 'package:flutter_test/flutter_test.dart';
import 'package:forma_flutter/features/nutrition/domain/date_range_filter.dart';

void main() {
  test('lastDays builds an inclusive date range', () {
    final range = DateRangeFilter.lastDays(
      days: 7,
      label: '7 days',
      now: DateTime(2026, 2, 23, 14, 00),
    );

    expect(range.start, DateTime(2026, 2, 17));
    expect(range.end, DateTime(2026, 2, 23));
    expect(range.dayCount, 7);
  });

  test('normalized swaps inverted dates', () {
    final range = DateRangeFilter(
      start: DateTime(2026, 2, 23),
      end: DateTime(2026, 2, 20),
      label: 'custom',
    );

    final normalized = range.normalized();

    expect(normalized.start, DateTime(2026, 2, 20));
    expect(normalized.end, DateTime(2026, 2, 23));
    expect(normalized.dayCount, 4);
  });
}
