import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../app/widgets/gradient_backdrop.dart';
import '../../nutrition/application/nutrition_providers.dart';
import '../../nutrition/domain/mistral_usage_ledger.dart';
import '../../nutrition/presentation/widgets/section_card.dart';
import '../../nutrition/presentation/widgets/stat_tile.dart';
import '../application/api_key_controller.dart';

class MistralSettingsScreen extends ConsumerWidget {
  const MistralSettingsScreen({super.key});

  static const String _consoleUrl = 'https://console.mistral.ai/api-keys';

  Future<void> _openConsole(BuildContext context) async {
    final bool launched = await launchUrl(Uri.parse(_consoleUrl));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open Mistral Console.')),
        );
    }
  }

  Future<void> _copyConsoleUrl(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _consoleUrl));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Mistral URL copied.')));
  }

  Future<void> _confirmResetKey(BuildContext context, WidgetRef ref) async {
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset API Key?'),
          content: const Text(
            'This signs out from Mistral until you enter a key again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }
    await ref.read(apiKeyControllerProvider.notifier).clear();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Mistral key reset.')));
    Navigator.of(context).pop();
  }

  Future<void> _promptTokenLimit(
    BuildContext context,
    WidgetRef ref,
    int? currentLimit,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentLimit?.toString() ?? '',
    );
    String? validationError;

    final int? parsedLimit = await showDialog<int?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void save() {
              final String text = controller.text.trim();
              if (text.isEmpty) {
                Navigator.of(context).pop(null);
                return;
              }
              final int? value = int.tryParse(text);
              if (value == null || value <= 0) {
                setState(() {
                  validationError =
                      'Enter a positive integer token limit, or leave blank to clear.';
                });
                return;
              }
              Navigator.of(context).pop(value);
            }

            return AlertDialog(
              title: const Text('Set Monthly Token Limit'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Enter your monthly token limit from Mistral AI Studio tier settings.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly limit (tokens)',
                        hintText: 'Example: 5000000',
                      ),
                    ),
                    if (validationError != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        validationError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(currentLimit),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(onPressed: save, child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (parsedLimit == currentLimit) {
      return;
    }
    await ref
        .read(mistralUsageLedgerControllerProvider)
        .setMonthlyLimit(parsedLimit);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            parsedLimit == null
                ? 'Monthly token limit cleared.'
                : 'Monthly token limit set to ${_formatTokens(parsedLimit)}.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<String?> apiKeyState = ref.watch(apiKeyControllerProvider);
    final AsyncValue<MistralUsageLedger> usageLedgerAsync = ref.watch(
      mistralUsageLedgerProvider,
    );
    final String? currentKey = switch (apiKeyState) {
      AsyncData<String?>(:final value) => value,
      _ => null,
    };
    final bool canReset = currentKey != null && currentKey.trim().isNotEmpty;

    final Widget connectionSection = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Connection', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          apiKeyState.when(
            data: (String? key) {
              final bool connected = key != null && key.trim().isNotEmpty;
              return Text(
                connected
                    ? 'Connected (${_maskKey(key)})'
                    : 'No key connected. Add a Mistral key to log meals.',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            },
            loading:
                () => Text(
                  'Checking key status...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            error:
                (Object error, StackTrace stackTrace) => Text(
                  'Could not read key state: $error',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => _openConsole(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Mistral Console'),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyConsoleUrl(context),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy Console URL'),
              ),
              ElevatedButton.icon(
                onPressed:
                    canReset ? () => _confirmResetKey(context, ref) : null,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Reset API Key'),
              ),
            ],
          ),
        ],
      ),
    );

    final Widget tokenUsageSection = usageLedgerAsync.when(
      data: (MistralUsageLedger ledger) {
        final MistralUsageLedger normalized = ledger.normalizedFor(
          DateTime.now(),
        );
        final String cycleLabel = DateFormat(
          'MMM yyyy',
        ).format(DateTime(normalized.cycleYear, normalized.cycleMonth, 1));
        final int? remaining = normalized.remainingMonthlyTokens;
        final int? overLimit = normalized.overLimitTokens;
        final bool hasLimit = normalized.monthlyLimitTokens != null;
        final Color balanceColor =
            hasLimit && (overLimit ?? 0) > 0 ? scheme.error : scheme.primary;

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Mistral Token Usage',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Set monthly token limit',
                    onPressed:
                        () => _promptTokenLimit(
                          context,
                          ref,
                          normalized.monthlyLimitTokens,
                        ),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Billing cycle: $cycleLabel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  StatTile(
                    label: 'Cycle Used',
                    value: '${_formatTokens(normalized.cycleTotalTokens)} tok',
                    tint: scheme.primary,
                    width: 180,
                  ),
                  StatTile(
                    label: 'Prompt',
                    value: '${_formatTokens(normalized.cyclePromptTokens)} tok',
                    tint: scheme.onSurface,
                    width: 170,
                  ),
                  StatTile(
                    label: 'Completion',
                    value:
                        '${_formatTokens(normalized.cycleCompletionTokens)} tok',
                    tint: AppColors.coral,
                    width: 170,
                  ),
                  StatTile(
                    label: 'Remaining',
                    value:
                        hasLimit
                            ? ((overLimit ?? 0) > 0
                                ? '-${_formatTokens(overLimit!)} tok'
                                : '${_formatTokens(remaining ?? 0)} tok')
                            : 'Set limit',
                    tint: balanceColor,
                    width: 170,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                hasLimit
                    ? 'Plan/tier limit: ${_formatTokens(normalized.monthlyLimitTokens!)} tokens per month.'
                    : 'Set your plan monthly token limit to compute remaining tokens.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Note: token counts come from each Mistral API response usage block and are tracked locally.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (normalized.lastRequestUsage != null &&
                  normalized.lastRequestAt != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Last request: ${_formatTokens(normalized.lastRequestUsage!.totalTokens)} tokens '
                  '(${DateFormat('MMM d, HH:mm').format(normalized.lastRequestAt!.toLocal())}).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
      loading:
          () => const SectionCard(
            child: SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error: (Object error, StackTrace stackTrace) {
        return SectionCard(child: Text('Failed to load token usage: $error'));
      },
    );

    return GradientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Mistral Settings')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: <Widget>[
            connectionSection,
            const SizedBox(height: AppSpacing.md),
            tokenUsageSection,
          ],
        ),
      ),
    );
  }
}

String _formatTokens(int value) {
  return NumberFormat.decimalPattern().format(value);
}

String _maskKey(String value) {
  final String trimmed = value.trim();
  if (trimmed.length <= 8) {
    return '••••';
  }
  return '${trimmed.substring(0, 4)}••••${trimmed.substring(trimmed.length - 4)}';
}
