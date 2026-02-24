import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/formatters.dart';
import '../application/meal_entry_controller.dart';
import '../application/nutrition_providers.dart';
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

  @override
  void dispose() {
    _mealController.dispose();
    super.dispose();
  }

  Future<void> _submitMeal() async {
    await ref
        .read(mealEntryControllerProvider.notifier)
        .submitMeal(_mealController.text);
  }

  void _useSuggestion(String text) {
    _mealController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
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
        _mealController.clear();
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
    final AsyncValue<int> target = ref.watch(calorieTargetControllerProvider);

    final int dailyTarget = switch (target) {
      AsyncData<int>(:final value) => value,
      _ => 1900,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: <Widget>[
        HeroBanner(
          imageUrl: AppImages.hero,
          title: 'Log your meals fast',
          subtitle: 'Target: $dailyTarget kcal/day',
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
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
                  hintText:
                      'Example: grilled chicken wrap, apple, and iced latte',
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
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
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
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Recent logs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        recentMeals.when(
          data: (List<MealLogEntry> entries) {
            if (entries.isEmpty) {
              return const SectionCard(
                child: Text(
                  'No meals logged yet. Add your first entry to start trend tracking.',
                ),
              );
            }

            return TweenAnimationBuilder<double>(
              duration: AppDurations.medium,
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOut,
              builder: (BuildContext context, double value, Widget? child) {
                return Opacity(opacity: value, child: child);
              },
              child: Column(
                children: entries
                    .take(8)
                    .map(
                      (MealLogEntry entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RecentMealRow(entry: entry),
                      ),
                    )
                    .toList(growable: false),
              ),
            );
          },
          error: (Object error, StackTrace stackTrace) {
            return SectionCard(
              child: Text('Failed to load recent meals: $error'),
            );
          },
          loading:
              () => const SectionCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
        ),
      ],
    );
  }
}

class _RecentMealRow extends StatelessWidget {
  const _RecentMealRow({required this.entry});

  final MealLogEntry entry;

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFFE9F5EE),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.leafDark,
            ),
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
                    color: AppColors.ink,
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
                  color: AppColors.leafDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(formatShortDate(entry.loggedAt), style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
