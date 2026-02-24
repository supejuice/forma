import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/nutrition/presentation/shell_screen.dart';
import '../features/settings/application/api_key_controller.dart';
import '../features/settings/presentation/api_key_screen.dart';
import 'theme/app_theme.dart';
import 'theme/design_tokens.dart';
import 'widgets/gradient_backdrop.dart';

class FormaApp extends ConsumerWidget {
  const FormaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> apiKeyState = ref.watch(apiKeyControllerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AnimatedSwitcher(
        duration: AppDurations.medium,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _screenFor(apiKeyState, ref),
      ),
    );
  }

  Widget _screenFor(AsyncValue<String?> state, WidgetRef ref) {
    if (state is AsyncLoading<String?>) {
      return const _BootScreen();
    }

    if (state is AsyncError<String?>) {
      return _Frame(
        key: const ValueKey<String>('api-key-recover'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Unable to load key from secure storage. Re-enter your key to continue.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Expanded(child: ApiKeyScreen()),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed:
                  () => ref.read(apiKeyControllerProvider.notifier).reload(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry secure storage read'),
            ),
          ],
        ),
      );
    }

    if (state is AsyncData<String?>) {
      final String? value = state.value;
      if (value == null || value.trim().isEmpty) {
        return const _Frame(
          key: ValueKey<String>('api-key-screen'),
          child: ApiKeyScreen(),
        );
      }
      return const NutritionShellScreen();
    }

    return const _BootScreen();
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const _Frame(
      key: ValueKey<String>('boot-screen'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: AppSpacing.md),
            Text('Preparing your nutrition workspace...'),
          ],
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GradientBackdrop(
      child: Scaffold(backgroundColor: Colors.transparent, body: child),
    );
  }
}
