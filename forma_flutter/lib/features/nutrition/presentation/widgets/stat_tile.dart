import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class StatTile extends StatefulWidget {
  const StatTile({
    required this.label,
    required this.value,
    super.key,
    this.tint = AppColors.leaf,
    this.width = 150,
  });

  final String label;
  final String value;
  final Color tint;
  final double width;

  @override
  State<StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<StatTile> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double scale =
        _pressed
            ? 0.99
            : _hovered
            ? 1.01
            : 1;
    final Offset slideOffset =
        _pressed
            ? const Offset(0, 0.003)
            : _hovered
            ? const Offset(0, -0.004)
            : Offset.zero;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: Listener(
        onPointerDown: (_) {
          setState(() {
            _pressed = true;
          });
        },
        onPointerUp: (_) {
          setState(() {
            _pressed = false;
          });
        },
        onPointerCancel: (_) {
          setState(() {
            _pressed = false;
          });
        },
        child: AnimatedScale(
          duration: _pressed ? AppDurations.micro : AppDurations.short,
          curve: AppCurves.spring,
          scale: scale,
          child: AnimatedSlide(
            duration: AppDurations.short,
            curve: AppCurves.standard,
            offset: slideOffset,
            child: AnimatedContainer(
              duration: AppDurations.short,
              curve: AppCurves.standard,
              width: widget.width,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                color: scheme.surfaceContainerLowest,
                border: Border.all(color: scheme.outlineVariant),
                boxShadow:
                    _hovered || _pressed
                        ? <BoxShadow>[
                          BoxShadow(
                            color: scheme.shadow.withValues(
                              alpha: _pressed ? 0.1 : 0.18,
                            ),
                            blurRadius: _pressed ? 8 : 14,
                            offset: Offset(0, _pressed ? 2 : 7),
                          ),
                        ]
                        : const <BoxShadow>[],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedSwitcher(
                    duration: AppDurations.short,
                    switchInCurve: AppCurves.entrance,
                    switchOutCurve: AppCurves.exit,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) =>
                            FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.16),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                    child: Text(
                      widget.value,
                      key: ValueKey<String>(widget.value),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: widget.tint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
