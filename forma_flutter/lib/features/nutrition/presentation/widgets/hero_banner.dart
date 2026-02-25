import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    super.key,
    this.height,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Orientation orientation = MediaQuery.orientationOf(context);
    final double bannerHeight =
        height ??
        (orientation == Orientation.landscape &&
                MediaQuery.sizeOf(context).width > 820
            ? 220
            : 188);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: SizedBox(
        height: bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              frameBuilder: (
                BuildContext context,
                Widget child,
                int? frame,
                bool wasSynchronouslyLoaded,
              ) {
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: AppDurations.short,
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return Container(color: scheme.primaryContainer);
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x22000000), Color(0xAA000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    title,
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
