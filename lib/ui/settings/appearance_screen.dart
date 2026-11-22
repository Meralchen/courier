import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/app_settings.dart';
import '../../state/scopes.dart';
import '../components/ios_ui.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final AppSettings settings = SettingsScope.of(context);
    final bool liquid = settings.glassStyle == GlassStyle.liquid;
    const List<({ThemeMode mode, String label, IconData icon})>
    options = <({ThemeMode mode, String label, IconData icon})>[
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
        children: <Widget>[
          const SectionLabel(
            'Material',
            padding: EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 8),
          ),
          IosSegmented<GlassStyle>(
            values: const <GlassStyle>[GlassStyle.liquid, GlassStyle.classic],
            labels: const <String>['Liquid Glass', 'Classic iOS'],
            selected: settings.glassStyle,
            onChanged: settings.setGlassStyle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
            child: Text(
              liquid
                  ? 'Refractive bars, the draggable tab lens and the colour '
                        'field behind the app. This is the iOS 26 material.'
                  : 'Flat iOS 13–18 bars and cards on the system background. '
                        'No shader and no blur behind the app, so it is the '
                        'lightest option on slower phones.',
              style: AppText.footnote.copyWith(color: colors.textSecondary),
            ),
          ),
          const SectionLabel('Theme'),
          SettingsGroup(
            children: <Widget>[
              for (final ({ThemeMode mode, String label, IconData icon}) item
                  in options)
                SettingsRow(
                  label: item.label,
                  icon: item.icon,
                  iconColor: colors.accent,
                  onTap: () => settings.setThemeMode(item.mode),
                  trailing: settings.themeMode == item.mode
                      ? Icon(Icons.check, size: 19, color: colors.accent)
                      : null,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              'The theme and material are local to Courier. Telegram stores '
              'its own theme on your account; this only changes this app.',
              style: AppText.caption.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
