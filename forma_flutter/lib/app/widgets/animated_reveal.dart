import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = AppDurations.medium,
    this.curve = AppCurves.spring,
    this.beginOffset = const Offset(0, 0.04),
    this.beginScale = 0.98,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;
  final double beginScale;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _startReveal();
  }

  @override
  void didUpdateWidget(covariant AnimatedReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay) {
      _timer?.cancel();
      _visible = false;
      _startReveal();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: widget.duration,
      curve: widget.curve,
      offset: _visible ? Offset.zero : widget.beginOffset,
      child: AnimatedOpacity(
        duration: widget.duration,
        curve: widget.curve,
        opacity: _visible ? 1 : 0,
        child: AnimatedScale(
          duration: widget.duration,
          curve: widget.curve,
          scale: _visible ? 1 : widget.beginScale,
          child: widget.child,
        ),
      ),
    );
  }

  void _startReveal() {
    _timer = Timer(widget.delay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _visible = true;
      });
    });
  }
}
