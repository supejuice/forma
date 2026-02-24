class DateRangeFilter {
  const DateRangeFilter({
    required this.start,
    required this.end,
    required this.label,
  });

  factory DateRangeFilter.lastDays({
    required int days,
    required String label,
    DateTime? now,
  }) {
    final DateTime reference = _dateOnly((now ?? DateTime.now()).toLocal());
    final DateTime start = reference.subtract(Duration(days: days - 1));
    return DateRangeFilter(start: start, end: reference, label: label);
  }

  final DateTime start;
  final DateTime end;
  final String label;

  DateRangeFilter custom({
    required DateTime customStart,
    required DateTime customEnd,
    required String customLabel,
  }) {
    return DateRangeFilter(
      start: _dateOnly(customStart),
      end: _dateOnly(customEnd),
      label: customLabel,
    );
  }

  int get dayCount => end.difference(start).inDays + 1;

  DateRangeFilter normalized() {
    final DateTime normalizedStart = _dateOnly(start);
    final DateTime normalizedEnd = _dateOnly(end);
    if (normalizedEnd.isBefore(normalizedStart)) {
      return DateRangeFilter(
        start: normalizedEnd,
        end: normalizedStart,
        label: label,
      );
    }
    return DateRangeFilter(
      start: normalizedStart,
      end: normalizedEnd,
      label: label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DateRangeFilter &&
        other.start == start &&
        other.end == end &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(start, end, label);

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
