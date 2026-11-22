import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import 'pressable.dart';

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0, this.color});

  final double indent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.6,
      margin: EdgeInsets.only(left: indent),
      color: color ?? AppColors.of(context).separator,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.only(left: 26, right: 20, top: 18, bottom: 7),
      child: Text(
        text.toUpperCase(),
        style: AppText.sectionHeader.copyWith(
          color: colors.textSecondary,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    // iOS group cards are opaque. Only bars, the composer and sheets are
    // material — a backdrop filter per card group was both wrong and the most
    // expensive thing on the Settings screen.
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ColoredBox(
          color: colors.card,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) const Hairline(indent: 54),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The iOS navigation-bar capsule ("Edit", "Sortierung"): a small grey pill
/// rather than a text button, matching Telegram's current bars.
class NavPill extends StatelessWidget {
  const NavPill({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: colors.dark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: AppText.subhead.copyWith(
            fontSize: 15,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// A navigation-bar glyph as iOS draws it: no material of its own on a 44 pt
/// target. Telegram puts glass on the bar, never on each button; nesting a
/// filter per icon in the chat header was pure cost.
class NavIconButton extends StatelessWidget {
  const NavIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.tooltip,
    this.size = 22,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget button = Pressable(
      onTap: onTap,
      scale: 0.9,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: size,
          color: color ?? AppColors.of(context).accent,
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// The iOS search field: a flat rounded fill sitting on the bar's blur. A glass
/// field inside a glass bar doubles the backdrop work for no visual gain, and
/// iOS does not do it either.
class IosSearchField extends StatelessWidget {
  const IosSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hint = 'Search',
    this.onChanged,
    this.trailing,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: colors.dark
            ? Colors.white.withValues(alpha: 0.11)
            : Colors.black.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search, size: 18, color: colors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppText.body.copyWith(
                fontSize: 16,
                color: colors.textPrimary,
              ),
              cursorColor: colors.accent,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppText.body.copyWith(
                  fontSize: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.subtitle,
    this.value,
    this.icon,
    this.iconColor,
    this.chevron = false,
    this.danger = false,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String? subtitle;
  final String? value;
  final IconData? icon;
  final Color? iconColor;
  final bool chevron;
  final bool danger;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Pressable(
      scale: 0.99,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: iconColor ?? colors.accent,
                  borderRadius: BorderRadius.circular(7.5),
                ),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 11),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: AppText.body.copyWith(
                      fontSize: 16.5,
                      color: danger ? colors.danger : colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppText.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppText.subhead.copyWith(color: colors.textSecondary),
              ),
            if (trailing != null) trailing!,
            if (chevron) ...<Widget>[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 19, color: colors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.iconColor,
    this.subtitle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: iconColor ?? colors.accent,
                borderRadius: BorderRadius.circular(7.5),
              ),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: AppText.body.copyWith(fontSize: 16.5)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppText.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: colors.success,
            onChanged: (bool next) {
              Haptics.tap();
              onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class IosSegmented<T> extends StatelessWidget {
  const IosSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final int index = values.indexOf(selected).clamp(0, values.length - 1);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(11),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double slot = constraints.maxWidth / values.length;
          return SizedBox(
            height: 32,
            child: Stack(
              children: <Widget>[
                // iOS slides one pill between segments; the old per-segment
                // background cross-faded two highlights in the same frame.
                AnimatedAlign(
                  duration: Motion.normal,
                  curve: Motion.emphasized,
                  alignment: Alignment(
                    values.length == 1
                        ? 0
                        : -1 + 2 * index / (values.length - 1),
                    0,
                  ),
                  child: Container(
                    width: slot,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 5,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    for (int i = 0; i < values.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (values[i] == selected) return;
                            Haptics.tap();
                            onChanged(values[i]);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.normal,
                              curve: Motion.emphasized,
                              style: AppText.subhead.copyWith(
                                fontSize: 13.5,
                                color: colors.textPrimary,
                                fontWeight: i == index
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LargeTitle extends StatelessWidget {
  const LargeTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 14, 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: AppText.largeTitle.copyWith(color: colors.textPrimary),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.dark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.045),
              ),
              child: Icon(icon, size: 30, color: colors.textSecondary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: AppText.headline.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              style: AppText.subhead.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: 18),
              Pressable(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: AppText.title.copyWith(color: colors.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[colors.accent, colors.accentDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(Icons.send_rounded, color: Colors.white, size: size * 0.44),
    );
  }
}

class ErrorLine extends StatelessWidget {
  const ErrorLine(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, size: 15, color: colors.danger),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message!,
              style: AppText.footnote.copyWith(color: colors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
