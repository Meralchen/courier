import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'components/glass.dart';
import 'components/pressable.dart';

class CourierTabBar extends StatelessWidget {
  const CourierTabBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.unread,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final int unread;

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
      child: GlassBar(
        radius: 30,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < _tabs.length; i++)
              Expanded(
                child: _TabItem(
                  icon: i == selected ? _tabs[i].active : _tabs[i].icon,
                  label: _tabs[i].label,
                  selected: i == selected,
                  badge: i == 2 ? unread : 0,
                  colors: colors,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? colors.accent.withValues(alpha: 0.14)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(
                  icon,
                  size: 23,
                  color: selected ? colors.accent : colors.textSecondary,
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.1,
                color: selected ? colors.accent : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
