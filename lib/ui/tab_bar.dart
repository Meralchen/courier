import 'package:material_ui/material_ui.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import 'components/glass.dart';

/// Telegram-iOS / liquidglass tab bar.
///
/// At rest the selection is a pill inset in the bar. Touching the bar swells it
/// into a lens that stands proud of the bar, magnifies the tab under it, follows
/// the finger when dragged, ticks a selection haptic per tab it crosses, and can
/// be thrown to the next tab on a flick. Releasing settles it on the nearest tab.
///
/// The geometry follows the liquidglass tab-bar spec: the lens is 4 pt taller
/// than the bar on each side, 16 pt wider than a slot, the bar lifts to 1.05 and
/// the tab under the lens grows to 1.18. Reduce Motion drops the lens, the
/// stretch and the throw; taps and drags still select.
class CourierTabBar extends StatefulWidget {
  const CourierTabBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.unread,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final int unread;

  @override
  State<CourierTabBar> createState() => _CourierTabBarState();
}

class _CourierTabBarState extends State<CourierTabBar>
    with TickerProviderStateMixin {
  static const List<({IconData icon, IconData active, String label})> _tabs =
      <({IconData icon, IconData active, String label})>[
    (
      icon: Icons.person_outline,
      active: Icons.person,
      label: 'Contacts',
    ),
    (
      icon: Icons.call_outlined,
      active: Icons.call,
      label: 'Calls',
    ),
    (
      icon: Icons.chat_bubble_outline,
      active: Icons.chat_bubble,
      label: 'Chats',
    ),
    (
      icon: Icons.settings_outlined,
      active: Icons.settings,
      label: 'Settings',
    ),
  ];

  static const double _barHeight = 56;
  static const double _lensOverflow = 4;
  static const double _lensExtraWidth = 16;
  static const double _flingVelocity = 550;

  /// Fractional tab the lens sits on, so it can rest between slots mid-drag.
  late final AnimationController _slide = AnimationController.unbounded(
    vsync: this,
    value: widget.selected.toDouble(),
  );

  /// 0 = resting pill, 1 = fully formed lens.
  late final AnimationController _form = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
    reverseDuration: const Duration(milliseconds: 320),
  );

  late final Animation<double> _formed = CurvedAnimation(
    parent: _form,
    curve: Motion.emphasized,
  );

  double _slot = 0;
  double _grab = 0;
  int _marked = 0;
  bool _held = false;
  bool _dragging = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(covariant CourierTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && !_held) {
      _moveToTab(widget.selected);
    }
  }

  @override
  void dispose() {
    _form.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _moveToTab(int index) {
    if (_reduceMotion) {
      _slide.value = index.toDouble();
    } else {
      _slide.animateTo(
        index.toDouble(),
        duration: Motion.normal,
        curve: Motion.emphasized,
      );
    }
  }

  /// Index under a horizontal position, clamped to the bar.
  int _indexAt(double x) {
    if (_slot <= 0) return 0;
    return (x / _slot).floor().clamp(0, _tabs.length - 1);
  }

  double _centerOf(double index) => (index + 0.5) * _slot;

  /// Touch-down: the lens arrives at the tab under the finger and keeps the
  /// finger's offset up to half its own width, so grabbing beside it brings it.
  void _arrive(double x) {
    if (_reduceMotion) return;
    _held = true;
    final int index = _indexAt(x);
    final double halfLens = (_slot + _lensExtraWidth) / 2;
    _grab = (x - _centerOf(index.toDouble())).clamp(-halfLens, halfLens);
    _slide.value = index.toDouble();
    _marked = index;
    _form.forward();
  }

  void _follow(double x) {
    if (_reduceMotion || _slot <= 0) return;
    final double index =
        ((x - _grab) / _slot - 0.5).clamp(0.0, (_tabs.length - 1).toDouble());
    _slide.value = index;
    final int marked = index.round();
    if (marked != _marked) {
      _marked = marked;
      Haptics.tap();
    }
  }

  void _settle(double velocity) {
    _dragging = false;
    int target = _slide.value.round();
    if (velocity.abs() > _flingVelocity) {
      target = (_slide.value + (velocity > 0 ? 0.5 : -0.5)).round();
    }
    target = target.clamp(0, _tabs.length - 1);
    _held = false;
    if (!_reduceMotion) _form.reverse();
    _moveToTab(target);
    if (target != widget.selected) {
      Haptics.tap();
      widget.onSelect(target);
    }
  }

  void _cancelVisual() {
    _held = false;
    if (!_reduceMotion) _form.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _slot = constraints.maxWidth / _tabs.length;
          return SizedBox(
            height: _barHeight + 2 * _lensOverflow + 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails details) => _arrive(details.localPosition.dx),
              onTapUp: (TapUpDetails details) => _settle(0),
              // Losing the tap to the drag recogniser is not a cancel: the drag
              // handlers own the lens from that point.
              onTapCancel: () {
                if (!_dragging) _cancelVisual();
              },
              onHorizontalDragStart: (DragStartDetails details) {
                _dragging = true;
                if (!_held) _arrive(details.localPosition.dx);
              },
              onHorizontalDragUpdate: (DragUpdateDetails details) =>
                  _follow(details.localPosition.dx),
              onHorizontalDragEnd: (DragEndDetails details) =>
                  _settle(details.primaryVelocity ?? 0),
              onHorizontalDragCancel: () {
                _dragging = false;
                _cancelVisual();
              },
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[_slide, _formed]),
                builder: (BuildContext context, Widget? child) {
                  final double lift = _formed.value;
                  final double index = _slide.value;
                  final double center = _centerOf(index);
                  final double lensWidth = _slot + _lensExtraWidth;
                  final double barTop = _lensOverflow + 2;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      // The bar itself, lifting 5% while a finger owns it.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: barTop,
                        height: _barHeight,
                        child: Transform.scale(
                          scale: 1 + 0.05 * lift,
                          child: GlassPanel(
                            radius: _barHeight / 2,
                            dark: colors.dark,
                            tintAmount: colors.dark ? 76 : 62,
                            animateIn: false,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      // At rest: the inset selection pill.
                      Positioned(
                        left: index * _slot + 5,
                        top: barTop + 5,
                        width: _slot - 10,
                        height: _barHeight - 10,
                        child: Opacity(
                          opacity: (1 - lift).clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: colors.dark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                      // The held lens: proud of the bar, wider than a slot.
                      if (!_reduceMotion)
                        Positioned(
                          left: center - lensWidth / 2,
                          top: 0,
                          width: lensWidth,
                          height: _barHeight + 2 * _lensOverflow,
                          child: Opacity(
                            opacity: lift.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.94 + 0.06 * lift,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.30 * lift),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: GlassPanel(
                                  radius: 24,
                                  dark: colors.dark,
                                  tintAmount: colors.dark ? 52 : 40,
                                  animateIn: false,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Tabs, above the lens, the one under it magnified.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: barTop,
                        height: _barHeight,
                        child: Row(
                          children: <Widget>[
                            for (int i = 0; i < _tabs.length; i++)
                              Expanded(
                                child: _TabItem(
                                  icon: _tabs[i].icon,
                                  activeIcon: _tabs[i].active,
                                  label: _tabs[i].label,
                                  selected: i == widget.selected,
                                  proximity:
                                      (1 - (index - i).abs()).clamp(0.0, 1.0),
                                  lift: lift,
                                  badge: i == 2 ? widget.unread : 0,
                                  colors: colors,
                                  onTap: () {
                                    if (i != widget.selected) {
                                      widget.onSelect(i);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.proximity,
    required this.lift,
    required this.badge,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;

  /// 1 when the lens is exactly over this tab, 0 elsewhere.
  final double proximity;
  final double lift;
  final int badge;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The tab the lens is over grows to 1.18 and turns accent, as iOS does.
    final double hold = proximity * lift;
    final Color tint = Color.lerp(
      selected ? colors.accent : colors.textSecondary,
      colors.accent,
      hold,
    )!;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge unread' : label,
      onTap: onTap,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1 + 0.18 * hold,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Icon(
                    selected || hold > 0.5 ? activeIcon : icon,
                    size: 23,
                    color: tint,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: colors.danger,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected || hold > 0.5
                      ? FontWeight.w600
                      : FontWeight.w500,
                  letterSpacing: 0.1,
                  color: tint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
