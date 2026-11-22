import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquiglass/liquiglass.dart';

import '../../core/theme.dart';
import '../../core/motion.dart';

/// Corner radii used by the glass language.
abstract final class GlassRadius {
  static const double bar = 30;
  static const double card = 20;
  static const double field = 13;
  static const double sheet = 28;
}

class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.radius = GlassRadius.bar,
    this.dark,
    this.tintAmount,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final bool? dark;
  final double? tintAmount;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool isDark = dark ?? colors.dark;
    return GlassSurface(
      radius: radius,
      dark: isDark,
      tintAmount: tintAmount ?? (isDark ? 58 : 46),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.white)
                .withValues(alpha: isDark ? 0.14 : 0.55),
            width: 0.8,
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = GlassRadius.card,
    this.padding = const EdgeInsets.all(16),
    this.tintAmount,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double? tintAmount;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return GlassSurface(
      radius: radius,
      dark: colors.dark,
      tintAmount: tintAmount ?? (colors.dark ? 52 : 38),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withValues(alpha: colors.dark ? 0.10 : 0.45),
            width: 0.7,
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.color,
    this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              Haptics.light();
              onTap!();
            },
      child: SizedBox(
        width: size,
        height: size,
        child: GlassSurface(
          radius: size / 2,
          dark: colors.dark,
          tintAmount: active ? 62 : 44,
          child: Center(
            child: Icon(
              icon,
              size: size * 0.47,
              color: color ?? (active ? colors.accent : colors.textPrimary),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.controller,
    this.hint,
    this.icon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.autofocus = false,
    this.obscure = false,
    this.suffix,
    this.textInputAction,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool autofocus;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return GlassSurface(
      radius: GlassRadius.field,
      dark: colors.dark,
      tintAmount: colors.dark ? 46 : 32,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 17, color: colors.textSecondary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                keyboardType: keyboardType,
                autofocus: autofocus,
                obscureText: obscure,
                maxLines: maxLines,
                readOnly: readOnly,
                onTap: onTap,
                textInputAction: textInputAction,
                cursorColor: colors.accent,
                style: AppText.body.copyWith(
                  color: colors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppText.body.copyWith(
                    color: colors.textSecondary,
                    fontSize: 16,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (suffix != null) suffix!,
          ],
        ),
      ),
    );
  }
}

class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: onTap == null || busy ? 0.55 : 1,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: <Color>[colors.accent, colors.accentDeep],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: AppText.title.copyWith(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Slow-drifting translucent colour field. Glass refracts this live, which is
/// what makes the shader visible on otherwise flat Telegram screens.
class LiquidWallpaper extends StatefulWidget {
  const LiquidWallpaper({
    super.key,
    required this.base,
    required this.dark,
    this.intensity = 1,
  });

  final Color base;
  final bool dark;
  final double intensity;

  @override
  State<LiquidWallpaper> createState() => _LiquidWallpaperState();
}

class _LiquidWallpaperState extends State<LiquidWallpaper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 48),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) => CustomPaint(
          painter: _WallpaperPainter(
            phase: _controller.value,
            base: widget.base,
            dark: widget.dark,
            intensity: widget.intensity,
          ),
          child: child,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter({
    required this.phase,
    required this.base,
    required this.dark,
    required this.intensity,
  });

  final double phase;
  final Color base;
  final bool dark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);

    final double t = phase * math.pi * 2;
    final List<({Color color, double x, double y, double r})> blobs =
        <({Color color, double x, double y, double r})>[
      (
        color: const Color(0xFF2F8FFF),
        x: 0.18 + 0.10 * math.sin(t),
        y: 0.12 + 0.06 * math.cos(t * 1.2),
        r: 0.62,
      ),
      (
        color: const Color(0xFF39D2C0),
        x: 0.86 + 0.08 * math.cos(t * 0.8),
        y: 0.26 + 0.08 * math.sin(t * 1.1),
        r: 0.55,
      ),
      (
        color: const Color(0xFF9B6BFF),
        x: 0.20 + 0.09 * math.cos(t * 1.4),
        y: 0.78 + 0.05 * math.sin(t),
        r: 0.60,
      ),
      (
        color: const Color(0xFFFF9F6B),
        x: 0.82 + 0.07 * math.sin(t * 0.7),
        y: 0.88 + 0.05 * math.cos(t * 1.3),
        r: 0.44,
      ),
    ];
    for (final ({Color color, double x, double y, double r}) blob in blobs) {
      final Offset center = Offset(blob.x * size.width, blob.y * size.height);
      final double radius = blob.r * size.shortestSide;
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            blob.color.withValues(alpha: (dark ? 0.30 : 0.34) * intensity),
            blob.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    if (dark) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0x55000000), Color(0xAA000000)],
          ).createShader(rect),
      );
    } else {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0x33FFFFFF), Color(0x66F4F8FF)],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_WallpaperPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.base != base ||
      oldDelegate.dark != dark;
}
