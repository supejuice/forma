import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/calorie_target_calculator.dart';

class BodyShapeDiagram extends StatelessWidget {
  const BodyShapeDiagram({
    required this.shape,
    required this.label,
    super.key,
    this.bodyFatPercent,
  });

  final BodyShapeModel shape;
  final String label;
  final double? bodyFatPercent;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        SizedBox(
          width: 210,
          height: 240,
          child: CustomPaint(
            painter: _BodyShapePainter(shape: shape, color: scheme.primary),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (bodyFatPercent != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${bodyFatPercent!.toStringAsFixed(1)}% est. body fat',
            style: textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

class _BodyShapePainter extends CustomPainter {
  _BodyShapePainter({required this.shape, required this.color});

  final BodyShapeModel shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill =
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill;
    final Paint stroke =
        Paint()
          ..color = color.withValues(alpha: 0.78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;

    final double centerX = size.width / 2;
    final double shoulderHalf =
        ((shape.shoulderWidthFactor.clamp(0.4, 0.86) * size.width) / 2);
    final double waistHalf =
        ((shape.waistWidthFactor.clamp(0.25, 0.76) * size.width) / 2);
    final double hipHalf =
        ((shape.hipWidthFactor.clamp(0.35, 0.82) * size.width) / 2);

    const double topY = 22;
    const double shoulderY = 52;
    const double waistY = 128;
    const double hipY = 182;
    final double bottomY = size.height - 16;

    final Path path =
        Path()
          ..moveTo(centerX, topY)
          ..lineTo(centerX - shoulderHalf * 0.45, shoulderY - 14)
          ..cubicTo(
            centerX - shoulderHalf,
            shoulderY + 4,
            centerX - waistHalf,
            waistY - 30,
            centerX - waistHalf,
            waistY,
          )
          ..cubicTo(
            centerX - waistHalf,
            waistY + 24,
            centerX - hipHalf,
            hipY - 10,
            centerX - hipHalf * 0.9,
            hipY,
          )
          ..cubicTo(
            centerX - hipHalf * 0.55,
            bottomY - 14,
            centerX - 20,
            bottomY - 4,
            centerX,
            bottomY,
          )
          ..cubicTo(
            centerX + 20,
            bottomY - 4,
            centerX + hipHalf * 0.55,
            bottomY - 14,
            centerX + hipHalf * 0.9,
            hipY,
          )
          ..cubicTo(
            centerX + hipHalf,
            hipY - 10,
            centerX + waistHalf,
            waistY + 24,
            centerX + waistHalf,
            waistY,
          )
          ..cubicTo(
            centerX + waistHalf,
            waistY - 30,
            centerX + shoulderHalf,
            shoulderY + 4,
            centerX + shoulderHalf * 0.45,
            shoulderY - 14,
          )
          ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BodyShapePainter oldDelegate) {
    return oldDelegate.shape.shoulderWidthFactor != shape.shoulderWidthFactor ||
        oldDelegate.shape.waistWidthFactor != shape.waistWidthFactor ||
        oldDelegate.shape.hipWidthFactor != shape.hipWidthFactor ||
        oldDelegate.color != color;
  }
}
