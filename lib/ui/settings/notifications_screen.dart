import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/app_settings.dart';
import '../../state/scopes.dart';
import '../components/ios_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final AppSettings settings = SettingsScope.of(context);
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        backgroundColor: colors.groupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications and Sounds'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: <Widget>[
          SettingsGroup(
            children: <Widget>[
              SettingsToggle(
                label: 'Message notifications',
                subtitle: 'In-app banners while Courier is open',
                icon: Icons.notifications_outlined,
                iconColor: colors.danger,
                value: settings.notifications,
                onChanged: settings.setNotifications,
              ),
              SettingsToggle(
                label: 'Sounds',
                icon: Icons.volume_up_outlined,
                iconColor: colors.success,
                value: settings.sounds,
                onChanged: settings.setSounds,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'These switches are local to Courier. Push notifications need '
              'FCM registration, which this build does not do yet.',
              style: AppText.caption.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
