import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        await ref.read(mistralApiClientProvider).validateKey(key);
      }
      await ref.read(apiKeyControllerProvider.notifier).save(key);
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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const HeroBanner(
            imageUrl: AppImages.onboarding,
            title: 'Welcome to Forma',
            subtitle: 'Your private food log and calorie trend coach.',
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
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
                    onPressed:
                        _isSaving ? null : () => _saveKey(validateFirst: true),
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
                  onPressed:
                      _isSaving ? null : () => _saveKey(validateFirst: false),
                  child: const Text('Save Without Check'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'Tip: start by logging one meal and verify calories look right for your usual portion sizes.',
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
