import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/app_settings.dart';
import '../../state/scopes.dart';
import '../../telegram/telegram_store.dart';
import '../components/ios_ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final AppSettings settings = SettingsScope.of(context);
    final TelegramStore store = TelegramScope.of(context);
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
                subtitle: 'Android notifications for new messages',
                icon: Icons.notifications_outlined,
                iconColor: colors.danger,
                value: settings.notifications,
                onChanged: (bool value) {
                  settings.setNotifications(value);
                  store.syncNotifications(
                    enabled: value,
                    sounds: settings.sounds,
                  );
                },
              ),
              SettingsToggle(
                label: 'Sounds',
                icon: Icons.volume_up_outlined,
                iconColor: colors.success,
                value: settings.sounds,
                onChanged: (bool value) {
                  settings.setSounds(value);
                  store.syncNotifications(
                    enabled: settings.notifications,
                    sounds: value,
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Courier posts Android notifications while its TDLib session is '
              'running. Delivery when the app is fully stopped needs FCM '
              'registration, which this build does not do yet.',
              style: AppText.caption.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
