import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/formatters.dart';
import '../../domain/meal_log_entry.dart';
import 'section_card.dart';

class NutritionBreakdownCard extends StatelessWidget {
  const NutritionBreakdownCard({required this.entry, super.key});

  final MealLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool compact = MediaQuery.sizeOf(context).width < 460;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(entry.summary, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                _Pill(
                  label:
                      '${(entry.confidence * 100).clamp(0, 100).toStringAsFixed(0)}% confidence',
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(entry.summary, style: textTheme.titleLarge),
                ),
                _Pill(
                  label:
                      '${(entry.confidence * 100).clamp(0, 100).toStringAsFixed(0)}% confidence',
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(formatLongDate(entry.loggedAt), style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _MetricCell(
                label: 'Calories',
                value: formatCalories(entry.nutrition.calories),
              ),
              _MetricCell(
                label: 'Protein',
                value: formatGrams(entry.nutrition.proteinGrams),
              ),
              _MetricCell(
                label: 'Carbs',
                value: formatGrams(entry.nutrition.carbGrams),
              ),
              _MetricCell(
                label: 'Fat',
                value: formatGrams(entry.nutrition.fatGrams),
              ),
              _MetricCell(
                label: 'Fiber',
                value: formatGrams(entry.nutrition.fiberGrams),
              ),
              _MetricCell(
                label: 'Sugar',
                value: formatGrams(entry.nutrition.sugarGrams),
              ),
              _MetricCell(
                label: 'Sodium',
                value: formatMilligrams(entry.nutrition.sodiumMilligrams),
              ),
            ],
          ),
          if (entry.notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(entry.notes, style: textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        color: scheme.primaryContainer.withValues(alpha: 0.72),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
