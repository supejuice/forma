import 'dart:math' as math;
import 'dart:io';

import 'package:image/image.dart' as img;

const int _size = 1024;

void main() {
  final Directory outputDir = Directory('assets/icons');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final img.Image background = _createGradientBackground();
  final img.Image icon = img.Image.from(background);
  final img.Image foreground = img.Image(
    width: _size,
    height: _size,
    numChannels: 4,
  );

  _drawDecorativeCircles(background);
  _drawDecorativeCircles(icon);

  final _SymbolGeometry symbol = _SymbolGeometry();

  _drawFormaSymbol(
    image: icon,
    geometry: symbol,
    color: const _Rgba(251, 253, 255, 255),
  );

  _drawFormaSymbol(
    image: foreground,
    geometry: symbol,
    color: const _Rgba(255, 255, 255, 255),
  );

  img.encodePngFile('assets/icons/forma_icon_bg.png', background);
  img.encodePngFile('assets/icons/forma_icon_fg.png', foreground);
  img.encodePngFile('assets/icons/forma_icon.png', icon);

  stdout.writeln('Generated icon assets in assets/icons/.');
}

img.Image _createGradientBackground() {
  final img.Image canvas = img.Image(
    width: _size,
    height: _size,
    numChannels: 4,
  );

  const _Rgba from = _Rgba(36, 126, 83, 255);
  const _Rgba to = _Rgba(226, 122, 84, 255);

  for (int y = 0; y < _size; y++) {
    for (int x = 0; x < _size; x++) {
      final double t = (x + y) / ((_size - 1) * 2);
      final int r = _lerp(from.r, to.r, t);
      final int g = _lerp(from.g, to.g, t);
      final int b = _lerp(from.b, to.b, t);
      canvas.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return canvas;
}

void _drawDecorativeCircles(img.Image image) {
  _drawCircle(
    image: image,
    cx: 790,
    cy: 230,
    radius: 200,
    color: const _Rgba(255, 255, 255, 34),
  );
  _drawCircle(
    image: image,
    cx: 190,
    cy: 820,
    radius: 220,
    color: const _Rgba(12, 43, 31, 40),
  );
}

void _drawFormaSymbol({
  required img.Image image,
  required _SymbolGeometry geometry,
  required _Rgba color,
}) {
  _drawRoundedRect(
    image: image,
    left: geometry.verticalLeft,
    top: geometry.verticalTop,
    right: geometry.verticalRight,
    bottom: geometry.verticalBottom,
    radius: 52,
    color: color,
  );

  _drawRoundedRect(
    image: image,
    left: geometry.topArmLeft,
    top: geometry.topArmTop,
    right: geometry.topArmRight,
    bottom: geometry.topArmBottom,
    radius: 52,
    color: color,
  );

  _drawRoundedRect(
    image: image,
    left: geometry.midArmLeft,
    top: geometry.midArmTop,
    right: geometry.midArmRight,
    bottom: geometry.midArmBottom,
    radius: 44,
    color: color,
  );

  _drawRotatedEllipse(
    image: image,
    cx: 680,
    cy: 200,
    rx: 132,
    ry: 86,
    angleDeg: -24,
    color: color,
  );
}

void _drawRoundedRect({
  required img.Image image,
  required int left,
  required int top,
  required int right,
  required int bottom,
  required int radius,
  required _Rgba color,
}) {
  for (int y = top; y <= bottom; y++) {
    for (int x = left; x <= right; x++) {
      if (_isInsideRoundedRect(
        x: x,
        y: y,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        radius: radius,
      )) {
        _blendPixel(image, x, y, color);
      }
    }
  }
}

bool _isInsideRoundedRect({
  required int x,
  required int y,
  required int left,
  required int top,
  required int right,
  required int bottom,
  required int radius,
}) {
  if (x >= left + radius && x <= right - radius) {
    return true;
  }
  if (y >= top + radius && y <= bottom - radius) {
    return true;
  }

  final int cornerX = x < left + radius ? left + radius : right - radius;
  final int cornerY = y < top + radius ? top + radius : bottom - radius;
  final int dx = x - cornerX;
  final int dy = y - cornerY;
  return (dx * dx) + (dy * dy) <= radius * radius;
}

void _drawRotatedEllipse({
  required img.Image image,
  required int cx,
  required int cy,
  required int rx,
  required int ry,
  required double angleDeg,
  required _Rgba color,
}) {
  final double angleRad = angleDeg * math.pi / 180;
  final double cosA = math.cos(angleRad);
  final double sinA = math.sin(angleRad);

  final int minX = cx - rx - 4;
  final int maxX = cx + rx + 4;
  final int minY = cy - ry - 4;
  final int maxY = cy + ry + 4;

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      final double dx = (x - cx).toDouble();
      final double dy = (y - cy).toDouble();

      final double localX = dx * cosA + dy * sinA;
      final double localY = -dx * sinA + dy * cosA;

      final double equation =
          ((localX * localX) / (rx * rx)) + ((localY * localY) / (ry * ry));
      if (equation <= 1) {
        _blendPixel(image, x, y, color);
      }
    }
  }
}

void _drawCircle({
  required img.Image image,
  required int cx,
  required int cy,
  required int radius,
  required _Rgba color,
}) {
  final int minX = cx - radius;
  final int maxX = cx + radius;
  final int minY = cy - radius;
  final int maxY = cy + radius;
  final int radiusSq = radius * radius;

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      final int dx = x - cx;
      final int dy = y - cy;
      if ((dx * dx) + (dy * dy) <= radiusSq) {
        _blendPixel(image, x, y, color);
      }
    }
  }
}

void _blendPixel(img.Image image, int x, int y, _Rgba overlay) {
  if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
    return;
  }

  final img.Pixel pixel = image.getPixel(x, y);
  final int baseR = pixel.r.toInt();
  final int baseG = pixel.g.toInt();
  final int baseB = pixel.b.toInt();

  final double alpha = overlay.a / 255;
  final int outR = (overlay.r * alpha + baseR * (1 - alpha)).round();
  final int outG = (overlay.g * alpha + baseG * (1 - alpha)).round();
  final int outB = (overlay.b * alpha + baseB * (1 - alpha)).round();

  image.setPixelRgba(x, y, outR, outG, outB, 255);
}

int _lerp(int from, int to, double t) {
  return (from + (to - from) * t).round();
}

final class _SymbolGeometry {
  final int verticalLeft = 274;
  final int verticalTop = 220;
  final int verticalRight = 420;
  final int verticalBottom = 804;

  final int topArmLeft = 274;
  final int topArmTop = 220;
  final int topArmRight = 768;
  final int topArmBottom = 350;

  final int midArmLeft = 274;
  final int midArmTop = 432;
  final int midArmRight = 646;
  final int midArmBottom = 548;
}

final class _Rgba {
  const _Rgba(this.r, this.g, this.b, this.a);

  final int r;
  final int g;
  final int b;
  final int a;
}
