import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class SectionCard extends StatefulWidget {
  const SectionCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.interactive = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool interactive;

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool interactive = widget.interactive;
    final double scale =
        !interactive
            ? 1
            : _pressed
            ? 0.992
            : _hovered
            ? 1.006
            : 1;
    final Offset slideOffset =
        !interactive
            ? Offset.zero
            : _pressed
            ? const Offset(0, 0.003)
            : _hovered
            ? const Offset(0, -0.004)
            : Offset.zero;
    final Duration duration =
        _pressed ? AppDurations.micro : AppDurations.short;

    return MouseRegion(
      onEnter: (_) {
        if (!interactive) {
          return;
        }
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        if (!interactive) {
          return;
        }
        setState(() {
          _hovered = false;
        });
      },
      child: Listener(
        onPointerDown: (_) {
          if (!interactive) {
            return;
          }
          setState(() {
            _pressed = true;
          });
        },
        onPointerUp: (_) {
          if (!interactive) {
            return;
          }
          setState(() {
            _pressed = false;
          });
        },
        onPointerCancel: (_) {
          if (!interactive) {
            return;
          }
          setState(() {
            _pressed = false;
          });
        },
        child: AnimatedScale(
          duration: duration,
          curve: AppCurves.spring,
          scale: scale,
          child: AnimatedSlide(
            duration: duration,
            curve: AppCurves.standard,
            offset: slideOffset,
            child: AnimatedContainer(
              duration: duration,
              curve: AppCurves.standard,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                boxShadow:
                    (_hovered || _pressed) && interactive
                        ? <BoxShadow>[
                          BoxShadow(
                            color: scheme.shadow.withValues(
                              alpha: _pressed ? 0.12 : 0.2,
                            ),
                            blurRadius: _pressed ? 8 : 16,
                            offset: Offset(0, _pressed ? 3 : 8),
                          ),
                        ]
                        : const <BoxShadow>[],
              ),
              child: Card(
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
