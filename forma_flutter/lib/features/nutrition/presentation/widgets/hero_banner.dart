import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class HeroBanner extends StatefulWidget {
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
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Orientation orientation = MediaQuery.orientationOf(context);
    final double bannerHeight =
        widget.height ??
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
            AnimatedBuilder(
              animation: _driftController,
              builder: (BuildContext context, Widget? child) {
                final double t = _driftController.value;
                final double scale = 1.03 + (0.035 * t);
                final double dx = -8 + (16 * t);
                final double dy = -2 + (6 * t);
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Image.network(
                widget.imageUrl,
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
                    widget.title,
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.subtitle,
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
