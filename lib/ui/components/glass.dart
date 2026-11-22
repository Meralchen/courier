import 'dart:math' as math;

import 'package:liquiglass/liquiglass.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import 'pressable.dart';

/// Corner radii used by the glass language, matched to Telegram-iOS geometry.
abstract final class GlassRadius {
  static const double bar = 30;
  static const double card = 20;
  static const double field = 13;
  static const double sheet = 28;
  static const double capsule = 999;
}

/// The shared glass material.
///
/// Wraps the package shader with the things the iOS material does that a bare
/// `GlassSurface` does not: it follows the system Increase Contrast setting, it
/// *materializes* instead of appearing, it lights from straight overhead (the
/// iOS 27 measurement) and it draws the thin refractive rim iOS puts on the
/// contour of every glass piece.
class GlassPanel extends StatefulWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = GlassRadius.card,
    this.dark,
    this.tintAmount,
    this.tint,
    this.padding = EdgeInsets.zero,
    this.rim = true,
    this.sheen = true,
    this.animateIn = true,
  });

  final Widget child;
  final double radius;
  final bool? dark;
  final double? tintAmount;
  final Color? tint;
  final EdgeInsets padding;
  final bool rim;
  final bool sheen;
  final bool animateIn;

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animateIn) {
      _controller = AnimationController(
        vsync: this,
        duration: Motion.slow,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AnimationController? controller = _controller;
    if (controller == null || controller.isAnimating || controller.isCompleted) {
      return;
    }
    // Reduce Motion turns materialization into a plain appearance.
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.value = 1;
    } else {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool dark = widget.dark ?? colors.dark;
    final bool highContrast = MediaQuery.highContrastOf(context);

    // The glass wraps the content, so it takes the content's size; the rim and
    // sheen are overlays and never change that size.
    Widget surface(double materialize) {
      return GlassSurface(
        radius: widget.radius,
        dark: dark,
        tintAmount: widget.tintAmount ?? (dark ? 58 : 44),
        tint: widget.tint,
        // iOS 27 measures the light as straight overhead, not top-left.
        light: const Offset(0, -1),
        materialize: materialize,
        increasedContrast: highContrast ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: widget.sheen
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.white.withValues(alpha: dark ? 0.07 : 0.22),
                      Colors.transparent,
                      Colors.white.withValues(alpha: dark ? 0.02 : 0.06),
                    ],
                    stops: const <double>[0, 0.55, 1],
                  )
                : null,
          ),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      );
    }

    Widget panel;
    if (_controller == null) {
      panel = surface(1);
    } else {
      panel = AnimatedBuilder(
        animation: _controller!,
        builder: (BuildContext context, Widget? child) => surface(
          Motion.emphasized.transform(_controller!.value),
        ),
      );
    }

    if (!widget.rim) return panel;
    return Stack(
      children: <Widget>[
        panel,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RimPainter(radius: widget.radius, dark: dark),
            ),
          ),
        ),
      ],
    );
  }
}

/// The 0.7 pt contour: bright at the top-left, cool at the bottom, exactly the
/// edge iOS draws rather than a flat border.
class _RimPainter extends CustomPainter {
  _RimPainter({required this.radius, required this.dark});

  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect.deflate(0.4),
      Radius.circular(math.min(radius, size.shortestSide / 2)),
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const <Color>[
                Color(0x66FFFFFF),
                Color(0x14FFFFFF),
                Color(0x3DFFFFFF),
              ]
            : const <Color>[
                Color(0xE6FFFFFF),
                Color(0x40FFFFFF),
                Color(0x8CFFFFFF),
              ],
        stops: const <double>[0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.dark != dark;
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
    return GlassPanel(
      radius: radius,
      dark: dark,
      tintAmount: tintAmount,
      padding: padding,
      child: child,
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
    return GlassPanel(
      radius: radius,
      dark: colors.dark,
      tintAmount: tintAmount ?? (colors.dark ? 52 : 38),
      padding: padding,
      child: child,
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
    final Widget button = Pressable(
      onTap: onTap,
      scale: 0.9,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: GlassPanel(
          radius: size / 2,
          dark: colors.dark,
          tintAmount: active ? 68 : 46,
          sheen: true,
          child: Center(
            child: AnimatedScale(
              scale: active ? 1.06 : 1,
              duration: Motion.fast,
              curve: Motion.emphasized,
              child: Icon(
                icon,
                size: size * 0.46,
                color: color ?? (active ? colors.accent : colors.textPrimary),
              ),
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
    return GlassPanel(
      radius: GlassRadius.field,
      dark: colors.dark,
      tintAmount: colors.dark ? 46 : 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 16, color: colors.textSecondary),
              const SizedBox(width: 7),
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
    return Pressable(
      onTap: busy ? null : onTap,
      scale: 0.97,
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
///
/// The painting is driven by a [ValueNotifier] handed to [CustomPaint] as its
/// repaint listenable, so a drift step repaints the wallpaper without rebuilding
/// a single widget. Steps are coarse (the field is deliberately slow) and the
/// drift stops entirely when the system asks for reduced motion.
/// The backdrop the glass bars sample.
///
/// It used to drift a full-screen gradient at ~15 Hz. Every [GlassSurface]
/// above it re-runs its backdrop filter whenever the backdrop changes, so that
/// drift re-shaded the chat header, composer, tab bar and every card many times
/// a second — the largest single source of jank in the app. The field is now
/// static: the glass still bends it, and content scrolling underneath gives it
/// all the motion it needs.
class LiquidWallpaper extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WallpaperPainter(
          base: base,
          dark: dark,
          intensity: intensity,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter({
    required this.base,
    required this.dark,
    required this.intensity,
  });

  final Color base;
  final bool dark;
  final double intensity;

  /// Fixed composition: an asymmetric field, brighter top-left, warm
  /// bottom-right, so bars and the lens catch different colours along their
  /// length.
  static const double _phase = 0.62;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = _phase * math.pi * 2;
    final Rect rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);

    final List<({Color color, double x, double y, double r, double a})> blobs =
        <({Color color, double x, double y, double r, double a})>[
      (
        color: const Color(0xFF2F8FFF),
        x: 0.16 + 0.09 * math.sin(t),
        y: 0.10 + 0.05 * math.cos(t * 1.2),
        r: 0.66,
        a: 0.32,
      ),
      (
        color: const Color(0xFF39D2C0),
        x: 0.88 + 0.07 * math.cos(t * 0.8),
        y: 0.24 + 0.07 * math.sin(t * 1.1),
        r: 0.58,
        a: 0.28,
      ),
      (
        color: const Color(0xFF9B6BFF),
        x: 0.18 + 0.08 * math.cos(t * 1.4),
        y: 0.80 + 0.04 * math.sin(t),
        r: 0.62,
        a: 0.30,
      ),
      (
        color: const Color(0xFFFF9F6B),
        x: 0.84 + 0.06 * math.sin(t * 0.7),
        y: 0.90 + 0.04 * math.cos(t * 1.3),
        r: 0.46,
        a: 0.22,
      ),
    ];
    for (final ({Color color, double x, double y, double r, double a}) blob
        in blobs) {
      final Offset center = Offset(blob.x * size.width, blob.y * size.height);
      final double radius = blob.r * size.shortestSide;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              blob.color.withValues(alpha: blob.a * intensity),
              blob.color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // A slow diagonal sheen so the glass always has something moving to bend.
    final double sweep = 0.5 + 0.5 * math.sin(t * 0.35);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + 2 * sweep, -1),
          end: Alignment(0 + 2 * sweep, 1),
          colors: <Color>[
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: dark ? 0.05 : 0.10),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.5, 1],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const <Color>[Color(0x55000000), Color(0xAA000000)]
              : const <Color>[Color(0x2EFFFFFF), Color(0x5CF4F8FF)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WallpaperPainter oldDelegate) =>
      oldDelegate.base != base ||
      oldDelegate.dark != dark ||
      oldDelegate.intensity != intensity;
}
