import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:liquiglass/liquiglass.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_settings.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/avatar.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';
import '../components/sheets.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'data_storage_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_screen.dart';
import 'sessions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeLabel(AppSettings settings) => switch (settings.themeMode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final AppSettings settings = SettingsScope.of(context);
    final Profile? me = store.me;

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 140),
        children: <Widget>[
          const LargeTitle('Settings'),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
            child: Pressable(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => const EditProfileScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: <Widget>[
                    Avatar(
                      title: me?.name ?? 'Courier user',
                      seed: me?.id ?? 1,
                      size: 60,
                      photoFileId: me?.photoFileId ?? 0,
                      photoPath: me?.photoPath ?? '',
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            me?.name ?? 'Courier user',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.headline.copyWith(
                              color: colors.textPrimary,
                              fontSize: 21,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            me?.username.isNotEmpty == true
                                ? '@${me!.username}'
                                : (me?.phone.isNotEmpty == true
                                    ? me!.phone
                                    : 'Telegram account'),
                            style: AppText.subhead.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colors.textTertiary,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SectionLabel('Account'),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Edit profile',
                subtitle: 'Name, bio and username',
                icon: Icons.person_outline,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const EditProfileScreen(),
                  ),
                ),
                chevron: true,
              ),
              SettingsRow(
                label: 'Phone number',
                value: me?.phone ?? '—',
                icon: Icons.phone_outlined,
                onTap: () async {
                  final String phone = me?.phone ?? '';
                  if (phone.isEmpty) return;
                  await Clipboard.setData(ClipboardData(text: phone));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number copied')),
                  );
                },
              ),
              SettingsRow(
                label: 'Active sessions',
                subtitle: 'Devices signed in to this account',
                icon: Icons.devices_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const SessionsScreen(),
                  ),
                ),
                chevron: true,
              ),
              SettingsRow(
                label: 'Privacy and security',
                icon: Icons.lock_outline,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const PrivacyScreen(),
                  ),
                ),
                chevron: true,
              ),
            ],
          ),
          const SectionLabel('General'),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Theme',
                value: _themeLabel(settings),
                icon: Icons.brightness_6_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const AppearanceScreen(),
                  ),
                ),
                chevron: true,
              ),
              SettingsRow(
                label: 'Liquid Glass',
                subtitle: 'iOS 26 material over the live backdrop',
                icon: Icons.blur_on,
                value: LiquidGlass.isSupported ? 'Shader' : 'Frosted',
              ),
            ],
          ),
          const SectionLabel('Notifications'),
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
          const SectionLabel('Data and storage'),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Storage and cache',
                value: store.storageSize > 0
                    ? fileSizeLabel(store.storageSize)
                    : 'Open',
                icon: Icons.storage_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const DataStorageScreen(),
                  ),
                ),
                chevron: true,
              ),
              SettingsRow(
                label: 'Refresh chats',
                subtitle: 'Ask TDLib to reload the main chat list',
                icon: Icons.refresh,
                onTap: store.refreshChats,
              ),
            ],
          ),
          const SectionLabel('Connection'),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'TDLib',
                value: store.tdlibVersion.isEmpty
                    ? 'loading…'
                    : store.tdlibVersion,
                icon: Icons.memory,
              ),
              SettingsRow(
                label: 'Status',
                value: store.connection,
                icon: Icons.wifi,
                iconColor: store.connection == 'Connected'
                    ? colors.success
                    : colors.textSecondary,
              ),
              SettingsRow(
                label: 'Chats synced',
                value: '${store.chats.length}',
                icon: Icons.chat_bubble_outline,
              ),
            ],
          ),
          const SectionLabel('About'),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Courier',
                subtitle: 'Version $kAppVersion ($kAppBuild)',
                icon: Icons.info_outline,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const AboutScreen(),
                  ),
                ),
                chevron: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Log out',
                icon: Icons.logout,
                iconColor: colors.danger,
                danger: true,
                onTap: () async {
                  final bool confirmed = await showGlassConfirm(
                    context,
                    title: 'Log out of Courier?',
                    message:
                        'TDLib will remove this session\'s local data. You can '
                        'sign in again at any time.',
                    confirmLabel: 'Log out',
                    destructive: true,
                  );
                  if (confirmed) await store.logout();
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 18, 30, 0),
            child: Text(
              'Courier $kAppVersion ($kAppBuild) · Flutter + TDLib\n'
              'Telegram is a trademark of Telegram Messenger LLP. '
              'This is an independent client and is not affiliated with Telegram.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
