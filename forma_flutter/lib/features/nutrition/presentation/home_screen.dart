import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/formatters.dart';
import '../application/daily_feedback_controller.dart';
import '../application/meal_entry_controller.dart';
import '../application/nutrition_providers.dart';
import '../domain/daily_feedback_entry.dart';
import '../domain/meal_log_entry.dart';
import 'widgets/hero_banner.dart';
import 'widgets/nutrition_breakdown_card.dart';
import 'widgets/section_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _mealController = TextEditingController();
  DateTime _selectedLoggedAt = DateTime.now();

  @override
  void dispose() {
    _mealController.dispose();
    super.dispose();
  }

  Future<void> _submitMeal() async {
    await ref
        .read(mealEntryControllerProvider.notifier)
        .submitMeal(_mealController.text, loggedAt: _selectedLoggedAt);
  }

  Future<void> _pickEntryDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedLoggedAt,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedLoggedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedLoggedAt.hour,
        _selectedLoggedAt.minute,
        _selectedLoggedAt.second,
        _selectedLoggedAt.millisecond,
        _selectedLoggedAt.microsecond,
      );
    });
  }

  Future<void> _editLogDate(MealLogEntry entry) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = entry.loggedAt;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) {
      return;
    }

    final DateTime updated = DateTime(
      picked.year,
      picked.month,
      picked.day,
      initialDate.hour,
      initialDate.minute,
      initialDate.second,
      initialDate.millisecond,
      initialDate.microsecond,
    );
    await ref
        .read(mealEntryControllerProvider.notifier)
        .updateMealLoggedAt(entry: entry, loggedAt: updated);
  }

  void _useSuggestion(String text) {
    _mealController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }

  bool _useWideLayout(BuildContext context, BoxConstraints constraints) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isLandscape = size.width > size.height;
    return constraints.maxWidth >= AppBreakpoints.large ||
        (isLandscape && constraints.maxWidth >= AppBreakpoints.medium);
  }

  double _horizontalPaddingForWidth(double width) {
    if (width >= AppBreakpoints.large) {
      return AppSpacing.xl;
    }
    if (width >= AppBreakpoints.medium) {
      return AppSpacing.lg;
    }
    return 0;
  }

  List<_MealLogDayGroup> _groupRecentMeals(List<MealLogEntry> entries) {
    final List<_MealLogDayGroup> groups = <_MealLogDayGroup>[];
    for (final MealLogEntry entry in entries) {
      final DateTime day = DateTime(
        entry.loggedAt.year,
        entry.loggedAt.month,
        entry.loggedAt.day,
      );
      if (groups.isEmpty || !DateUtils.isSameDay(groups.last.day, day)) {
        groups.add(_MealLogDayGroup(day: day, entries: <MealLogEntry>[entry]));
      } else {
        groups.last.entries.add(entry);
      }
    }
    return groups;
  }

  String _groupLabel(DateTime day) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(day, today)) {
      return 'Today';
    }
    if (DateUtils.isSameDay(day, yesterday)) {
      return 'Yesterday';
    }
    return formatLongDate(day);
  }

  String _dayKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MealEntryState>(mealEntryControllerProvider, (previous, next) {
      final String? error = next.errorMessage;
      if (error != null && error != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
        ref.read(mealEntryControllerProvider.notifier).clearError();
      }

      final String? status = next.statusMessage;
      if (status != null && status != previous?.statusMessage) {
        if (status.startsWith('Meal saved')) {
          _mealController.clear();
          setState(() {
            _selectedLoggedAt = DateTime.now();
          });
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(status)));
        ref.read(mealEntryControllerProvider.notifier).clearStatus();
      }
    });

    final MealEntryState mealState = ref.watch(mealEntryControllerProvider);
    final AsyncValue<List<String>> recentSuggestions = ref.watch(
      recentMealTextsProvider,
    );
    final AsyncValue<List<MealLogEntry>> recentMeals = ref.watch(
      recentMealsProvider,
    );
    final AsyncValue<List<DailyFeedbackEntry>> recentDailyFeedback = ref.watch(
      recentDailyFeedbackProvider,
    );
    final AsyncValue<int> target = ref.watch(calorieTargetControllerProvider);

    final int dailyTarget = switch (target) {
      AsyncData<int>(:final value) => value,
      _ => 1900,
    };

    final Widget composerSection = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'What did you last eat?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _mealController,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Example: grilled chicken wrap, apple, and iced latte',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          recentSuggestions.when(
            data: (List<String> suggestions) {
              if (suggestions.isEmpty) {
                return const SizedBox.shrink();
              }
              return Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: suggestions
                    .map(
                      (String suggestion) => ActionChip(
                        label: Text(
                          suggestion,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _useSuggestion(suggestion),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const LinearProgressIndicator(minHeight: 2),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              ActionChip(
                avatar: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text('Date: ${formatLongDate(_selectedLoggedAt)}'),
                onPressed: _pickEntryDate,
              ),
              if (!DateUtils.isSameDay(_selectedLoggedAt, DateTime.now()))
                ActionChip(
                  avatar: const Icon(Icons.today_rounded, size: 18),
                  label: const Text('Today'),
                  onPressed: () {
                    setState(() {
                      _selectedLoggedAt = DateTime.now();
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedContainer(
            duration: AppDurations.short,
            curve: Curves.easeOut,
            transform: Matrix4.diagonal3Values(
              mealState.isSubmitting ? 0.98 : 1.0,
              mealState.isSubmitting ? 0.98 : 1.0,
              1,
            ),
            child: ElevatedButton.icon(
              onPressed: mealState.isSubmitting ? null : _submitMeal,
              icon:
                  mealState.isSubmitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                mealState.isSubmitting
                    ? 'Estimating nutrition...'
                    : 'Analyze and Save Meal',
              ),
            ),
          ),
        ],
      ),
    );

    final Widget latestBreakdown = AnimatedSwitcher(
      duration: AppDurations.medium,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child:
          mealState.latestEntry == null
              ? const SizedBox.shrink()
              : NutritionBreakdownCard(
                key: ValueKey<int?>(mealState.latestEntry?.id),
                entry: mealState.latestEntry!,
              ),
    );

    final Widget recentLogsList;
    if (recentMeals case AsyncData<List<MealLogEntry>>(value: final entries)) {
      if (recentDailyFeedback case AsyncData<List<DailyFeedbackEntry>>(
        value: final feedback,
      )) {
        recentLogsList = _RecentLogsList(
          entries: entries.take(12).toList(growable: false),
          dailyFeedback: feedback.take(30).toList(growable: false),
          groupLabel: _groupLabel,
          groupRecentMeals: _groupRecentMeals,
          dayKey: _dayKey,
          onEditDate: _editLogDate,
        );
      } else if (recentDailyFeedback case AsyncError<List<DailyFeedbackEntry>>(
        error: final error,
      )) {
        recentLogsList = SectionCard(
          child: Text('Failed to load daily feedback: $error'),
        );
      } else {
        recentLogsList = const SectionCard(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
    } else if (recentMeals case AsyncError<List<MealLogEntry>>(
      error: final error,
    )) {
      recentLogsList = SectionCard(
        child: Text('Failed to load recent meals: $error'),
      );
    } else {
      recentLogsList = const SectionCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final Widget recentLogsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Recent logs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        recentLogsList,
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useWideLayout = _useWideLayout(context, constraints);
        final double horizontalPadding = _horizontalPaddingForWidth(
          constraints.maxWidth,
        );
        final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          120,
        );

        final List<Widget> leftColumnChildren = <Widget>[
          HeroBanner(
            imageUrl: AppImages.hero,
            title: 'Log your meals fast',
            subtitle: 'Target: $dailyTarget kcal/day',
            height: useWideLayout ? 220 : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          composerSection,
        ];
        if (mealState.latestEntry != null) {
          leftColumnChildren
            ..add(const SizedBox(height: AppSpacing.lg))
            ..add(latestBreakdown);
        }

        if (!useWideLayout) {
          return ListView(
            padding: contentPadding,
            children: <Widget>[
              ...leftColumnChildren,
              const SizedBox(height: AppSpacing.lg),
              recentLogsSection,
            ],
          );
        }

        return SingleChildScrollView(
          padding: contentPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: leftColumnChildren,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 5, child: recentLogsSection),
            ],
          ),
        );
      },
    );
  }
}

class _RecentMealRow extends StatelessWidget {
  const _RecentMealRow({required this.entry, required this.onEditDate});

  final MealLogEntry entry;
  final VoidCallback onEditDate;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              color: scheme.primaryContainer.withValues(alpha: 0.55),
            ),
            child: Icon(Icons.restaurant_menu_rounded, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  entry.rawText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    _MacroPill(
                      label: 'P',
                      value: formatGrams(entry.nutrition.proteinGrams),
                    ),
                    _MacroPill(
                      label: 'C',
                      value: formatGrams(entry.nutrition.carbGrams),
                    ),
                    _MacroPill(
                      label: 'F',
                      value: formatGrams(entry.nutrition.fatGrams),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatCalories(entry.nutrition.calories),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(formatShortDate(entry.loggedAt), style: textTheme.bodySmall),
              IconButton(
                tooltip: 'Edit log date',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                onPressed: onEditDate,
                icon: const Icon(Icons.edit_calendar_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealLogDayGroup {
  _MealLogDayGroup({required this.day, required this.entries});

  final DateTime day;
  final List<MealLogEntry> entries;
}

class _RecentLogsList extends StatelessWidget {
  const _RecentLogsList({
    required this.entries,
    required this.dailyFeedback,
    required this.groupLabel,
    required this.groupRecentMeals,
    required this.dayKey,
    required this.onEditDate,
  });

  final List<MealLogEntry> entries;
  final List<DailyFeedbackEntry> dailyFeedback;
  final String Function(DateTime day) groupLabel;
  final List<_MealLogDayGroup> Function(List<MealLogEntry> entries)
  groupRecentMeals;
  final String Function(DateTime value) dayKey;
  final Future<void> Function(MealLogEntry entry) onEditDate;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SectionCard(
        child: Text(
          'No meals logged yet. Add your first entry to start trend tracking.',
        ),
      );
    }

    final Map<String, DailyFeedbackEntry> feedbackByDay =
        <String, DailyFeedbackEntry>{};
    for (final DailyFeedbackEntry feedback in dailyFeedback) {
      feedbackByDay[dayKey(feedback.day)] = feedback;
    }

    return TweenAnimationBuilder<double>(
      duration: AppDurations.medium,
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(opacity: value, child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupRecentMeals(entries)
            .expand(
              (_MealLogDayGroup group) => <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    groupLabel(group.day),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ...group.entries.map(
                  (MealLogEntry entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _RecentMealRow(
                      entry: entry,
                      onEditDate: () {
                        onEditDate(entry);
                      },
                    ),
                  ),
                ),
                if (feedbackByDay.containsKey(dayKey(group.day)))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _DailyFeedbackRow(
                      entry: feedbackByDay[dayKey(group.day)]!,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
              ],
            )
            .toList(growable: false),
      ),
    );
  }
}

class _DailyFeedbackRow extends StatelessWidget {
  const _DailyFeedbackRow({required this.entry});

  final DailyFeedbackEntry entry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              color: scheme.tertiaryContainer.withValues(alpha: 0.62),
            ),
            child: Icon(Icons.insights_rounded, color: scheme.tertiary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Daily intake feedback',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(entry.oneLiner, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        '$label $value',
        style: textTheme.labelSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
