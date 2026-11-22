import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/app_settings.dart';
import '../../state/scopes.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final AppSettings settings = SettingsScope.of(context);
    const List<({ThemeMode mode, String label, IconData icon})> options =
        <({ThemeMode mode, String label, IconData icon})>[
      (mode: ThemeMode.system, label: 'System', icon: Icons.brightness_auto),
      (mode: ThemeMode.light, label: 'Light', icon: Icons.light_mode_outlined),
      (mode: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_outlined),
    ];
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        backgroundColor: colors.groupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: <Widget>[
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (final ({ThemeMode mode, String label, IconData icon}) item
                    in options)
                  Pressable(
                    onTap: () => settings.setThemeMode(item.mode),
                    scale: 0.99,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(item.icon, size: 19, color: colors.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: AppText.body.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (settings.themeMode == item.mode)
                            Icon(Icons.check, size: 19, color: colors.accent),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The theme switch is local to Courier. Telegram stores its own '
            'theme on your account; this setting only changes this app.',
            style: AppText.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
