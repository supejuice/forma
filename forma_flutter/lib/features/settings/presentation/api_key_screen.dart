import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/app_exception.dart';
import '../../nutrition/infrastructure/mistral_api_client.dart';
import '../../nutrition/presentation/widgets/hero_banner.dart';
import '../../nutrition/presentation/widgets/section_card.dart';
import '../application/api_key_controller.dart';

class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  static const String _mistralKeyUrl = 'https://console.mistral.ai/api-keys';

  final TextEditingController _apiKeyController = TextEditingController();
  bool _isSaving = false;
  bool _isObscured = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey({required bool validateFirst}) async {
    final String key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      _showSnackBar('Enter your Mistral API key to continue.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (validateFirst) {
        await ref
            .read(mistralApiClientProvider)
            .validateKey(key)
            .timeout(
              const Duration(seconds: 12),
              onTimeout:
                  () =>
                      throw const AppException(
                        'Validation timed out. Try Save Without Check.',
                      ),
            );
      }
      await ref
          .read(apiKeyControllerProvider.notifier)
          .save(key)
          .timeout(
            const Duration(seconds: 8),
            onTimeout:
                () =>
                    throw const AppException(
                      'Saving key took too long. Please retry.',
                    ),
          );
      if (mounted) {
        _showSnackBar('Mistral key saved.');
      }
    } on AppException catch (error) {
      _showSnackBar(error.message);
    } catch (_) {
      _showSnackBar('Could not save key right now. Please retry.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyMistralKeyUrl() async {
    await Clipboard.setData(const ClipboardData(text: _mistralKeyUrl));
    _showSnackBar('Mistral API key URL copied.');
  }

  Future<void> _openMistralKeyUrl() async {
    final Uri url = Uri.parse(_mistralKeyUrl);
    final bool launched = await launchUrl(url);
    if (!launched) {
      _showSnackBar('Could not open link. Use Copy key URL instead.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Widget formSection = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Connect Mistral', style: textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your API key once. Meal text will be sent to Mistral to estimate calories and macros.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _apiKeyController,
            obscureText: _isObscured,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Mistral API Key',
              hintText: 'Paste key here',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedContainer(
            duration: AppDurations.short,
            curve: Curves.easeOut,
            transform: Matrix4.diagonal3Values(
              _isSaving ? 0.98 : 1.0,
              _isSaving ? 0.98 : 1.0,
              1,
            ),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveKey(validateFirst: true),
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.key_rounded),
              label: Text(
                _isSaving ? 'Validating key...' : 'Validate and Save',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: _isSaving ? null : () => _saveKey(validateFirst: false),
            child: const Text('Save Without Check'),
          ),
        ],
      ),
    );

    final Widget keyGuideSection = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('How to get your Mistral API key', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('1. Sign in to Mistral Console.', style: textTheme.bodyMedium),
          Text(
            '2. Open API Keys and create a new key.',
            style: textTheme.bodyMedium,
          ),
          Text(
            '3. Copy the key immediately and paste it above.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: _openMistralKeyUrl,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Text(
                _mistralKeyUrl,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _copyMistralKeyUrl,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy key URL'),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'If validation cannot connect, use Save Without Check and try logging a meal after network/proxy settings are confirmed.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );

    final Widget helperText = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        'Tip: start by logging one meal and verify calories look right for your usual portion sizes.',
        style: textTheme.bodySmall,
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = MediaQuery.sizeOf(context);
        final bool isLandscape = size.width > size.height;
        final bool useWideLayout =
            constraints.maxWidth >= AppBreakpoints.large ||
            (isLandscape && constraints.maxWidth >= AppBreakpoints.medium);
        final double horizontalPadding =
            constraints.maxWidth >= AppBreakpoints.large
                ? AppSpacing.xl
                : constraints.maxWidth >= AppBreakpoints.medium
                ? AppSpacing.lg
                : 0;

        if (!useWideLayout) {
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              const HeroBanner(
                imageUrl: AppImages.onboarding,
                title: 'Welcome to Forma',
                subtitle: 'Your private food log and calorie trend coach.',
              ),
              const SizedBox(height: AppSpacing.lg),
              formSection,
              const SizedBox(height: AppSpacing.md),
              keyGuideSection,
              const SizedBox(height: AppSpacing.sm),
              helperText,
            ],
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const HeroBanner(
                      imageUrl: AppImages.onboarding,
                      title: 'Welcome to Forma',
                      subtitle:
                          'Your private food log and calorie trend coach.',
                      height: 240,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    helperText,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    formSection,
                    const SizedBox(height: AppSpacing.md),
                    keyGuideSection,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
