import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFFF7F3EA),
            Color(0xFFF0F6EB),
            Color(0xFFFFF8F2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            top: -110,
            left: -70,
            child: _BlurOrb(color: Color(0x66B5E1C5), size: 280),
          ),
          const Positioned(
            top: 210,
            right: -80,
            child: _BlurOrb(color: Color(0x66F6C5A9), size: 250),
          ),
          const Positioned(
            bottom: -120,
            left: 30,
            child: _BlurOrb(color: Color(0x66CCE8D6), size: 260),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
