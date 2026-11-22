import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Chat backgrounds. Telegram-iOS ships the green doodle pattern by default;
/// the flat gradient and a plain colour are kept as lighter alternatives.
enum ChatWallpaper { doodle, gradient, plain }

/// Draws the chat background once per size. The pattern is static on purpose:
/// a repeated full-screen painter behind every bubble is what made scrolling
/// expensive in the first build.
class ChatWallpaperBackdrop extends StatelessWidget {
  const ChatWallpaperBackdrop({
    super.key,
    required this.style,
    required this.dark,
    this.energySaving = false,
  });

  final ChatWallpaper style;
  final bool dark;
  final bool energySaving;

  @override
  Widget build(BuildContext context) {
    if (style == ChatWallpaper.plain) {
      return ColoredBox(
        color: dark ? const Color(0xFF0C1622) : const Color(0xFFDCE9F7),
      );
    }
    if (style == ChatWallpaper.gradient) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const <Color>[Color(0xFF0A1622), Color(0xFF102A3C)]
                : const <Color>[Color(0xFFE4F0FB), Color(0xFFC9DFF3)],
          ),
        ),
        child: const SizedBox.expand(),
      );
    }
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DoodlePainter(dark: dark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  const _DoodlePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final List<Color> base = dark
        ? const <Color>[Color(0xFF0E2A1E), Color(0xFF123526), Color(0xFF0B2318)]
        : const <Color>[
            Color(0xFFBFE3C8),
            Color(0xFFA8D6B6),
            Color(0xFFCBE8D2),
          ];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: base,
        ).createShader(rect),
    );

    final Paint ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = (dark ? Colors.white : const Color(0xFF2F6B47)).withValues(
        alpha: dark ? 0.055 : 0.085,
      );

    const double step = 92;
    const double glyph = 26;
    int index = 0;
    for (double y = -step * 0.5; y < size.height + step; y += step) {
      for (double x = -step * 0.5; x < size.width + step; x += step) {
        final double offsetX = (index.isEven ? 0 : step * 0.5);
        final double offsetY = (index % 3 == 0 ? step * 0.22 : 0);
        canvas.save();
        canvas.translate(x + offsetX, y + offsetY);
        canvas.rotate(((index * 37) % 60 - 30) * math.pi / 180);
        _glyph(canvas, ink, index % 12, glyph);
        canvas.restore();
        index++;
      }
    }
  }

  /// Twelve small Telegram-style doodles: star, heart, planet, note, flower,
  /// lightning, paper plane, smiley, cloud, leaf, bell and paw.
  void _glyph(Canvas canvas, Paint ink, int kind, double s) {
    final double h = s / 2;
    switch (kind) {
      case 0: // star
        final Path path = Path();
        for (int i = 0; i < 10; i++) {
          final double r = i.isEven ? h : h * 0.45;
          final double a = -math.pi / 2 + i * math.pi / 5;
          final Offset p = Offset(math.cos(a) * r, math.sin(a) * r);
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, ink);
      case 1: // heart
        final Path path = Path()
          ..moveTo(0, h * 0.8)
          ..cubicTo(-h * 1.5, -h * 0.2, -h * 0.5, -h * 1.1, 0, -h * 0.35)
          ..cubicTo(h * 0.5, -h * 1.1, h * 1.5, -h * 0.2, 0, h * 0.8);
        canvas.drawPath(path, ink);
      case 2: // planet
        canvas.drawCircle(Offset.zero, h * 0.62, ink);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: s * 1.25,
            height: h * 0.5,
          ),
          ink,
        );
      case 3: // note
        canvas.drawLine(Offset(h * 0.2, -h), Offset(h * 0.2, h * 0.6), ink);
        canvas.drawLine(Offset(h * 0.2, -h), Offset(h * 0.8, -h * 0.7), ink);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(-h * 0.05, h * 0.75),
            width: h * 0.7,
            height: h * 0.55,
          ),
          ink,
        );
      case 4: // flower
        for (int i = 0; i < 5; i++) {
          final double a = i * math.pi * 2 / 5;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(math.cos(a) * h * 0.55, math.sin(a) * h * 0.55),
              width: h * 0.6,
              height: h * 0.6,
            ),
            ink,
          );
        }
        canvas.drawCircle(Offset.zero, h * 0.2, ink);
      case 5: // lightning
        final Path path = Path()
          ..moveTo(h * 0.15, -h)
          ..lineTo(-h * 0.45, h * 0.12)
          ..lineTo(h * 0.02, h * 0.12)
          ..lineTo(-h * 0.15, h)
          ..lineTo(h * 0.5, -h * 0.18)
          ..lineTo(h * 0.04, -h * 0.18)
          ..close();
        canvas.drawPath(path, ink);
      case 6: // paper plane
        final Path path = Path()
          ..moveTo(-h, h * 0.55)
          ..lineTo(h, -h * 0.6)
          ..lineTo(h * 0.2, h * 0.75)
          ..lineTo(-h * 0.15, h * 0.2)
          ..close();
        canvas.drawPath(path, ink);
        canvas.drawLine(Offset(-h, h * 0.55), Offset(h * 0.2, h * 0.75), ink);
      case 7: // smiley
        canvas.drawCircle(Offset.zero, h * 0.9, ink);
        canvas.drawCircle(Offset(-h * 0.3, -h * 0.2), 1.1, ink);
        canvas.drawCircle(Offset(h * 0.3, -h * 0.2), 1.1, ink);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: h * 0.5),
          0.35,
          math.pi - 0.7,
          false,
          ink,
        );
      case 8: // cloud
        final Path path = Path()
          ..moveTo(-h, h * 0.35)
          ..cubicTo(-h * 1.2, -h * 0.3, -h * 0.2, -h * 0.5, 0, -h * 0.1)
          ..cubicTo(h * 0.4, -h * 0.9, h * 1.3, -h * 0.2, h * 0.9, h * 0.35)
          ..close();
        canvas.drawPath(path, ink);
      case 9: // leaf
        final Path path = Path()
          ..moveTo(-h * 0.8, h * 0.8)
          ..quadraticBezierTo(-h * 0.9, -h * 0.9, h * 0.8, -h * 0.9)
          ..quadraticBezierTo(h * 0.9, h * 0.9, -h * 0.8, h * 0.8);
        canvas.drawPath(path, ink);
        canvas.drawLine(
          Offset(-h * 0.5, h * 0.5),
          Offset(h * 0.45, -h * 0.5),
          ink,
        );
      case 10: // bell
        final Path path = Path()
          ..moveTo(-h * 0.75, h * 0.4)
          ..quadraticBezierTo(-h * 0.4, h * 0.15, -h * 0.4, -h * 0.3)
          ..quadraticBezierTo(0, -h * 1.05, h * 0.4, -h * 0.3)
          ..quadraticBezierTo(h * 0.4, h * 0.15, h * 0.75, h * 0.4)
          ..close();
        canvas.drawPath(path, ink);
        canvas.drawCircle(Offset(0, h * 0.62), h * 0.16, ink);
      default: // paw
        canvas.drawCircle(Offset(0, h * 0.3), h * 0.4, ink);
        for (final Offset p in <Offset>[
          Offset(-h * 0.7, -h * 0.15),
          Offset(-h * 0.22, -h * 0.55),
          Offset(h * 0.22, -h * 0.55),
          Offset(h * 0.7, -h * 0.15),
        ]) {
          canvas.drawCircle(p, h * 0.19, ink);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) =>
      oldDelegate.dark != dark;
}
