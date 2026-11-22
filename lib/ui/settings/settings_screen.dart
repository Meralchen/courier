import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_settings.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../chat/chat_screen.dart';
import '../components/avatar.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';
import '../components/sheets.dart';
import '../shell_scope.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'data_storage_screen.dart';
import 'edit_profile_screen.dart';
import 'folders_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'profile_qr.dart';
import 'sessions_screen.dart';

/// Telegram-iOS settings: a centred identity block with Edit in the nav-bar
/// position, then opaque group cards. There is no large title, because the
/// profile block is the title.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _uploadingPhoto = false;

  void _push(Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (BuildContext _) => screen));
  }

  String _identity(Profile? me) {
    if (me == null) return 'Telegram account';
    final List<String> parts = <String>[
      if (me.phone.isNotEmpty) me.phone,
      if (me.username.isNotEmpty) '@${me.username}',
    ];
    return parts.isEmpty ? 'Telegram account' : parts.join(' · ');
  }

  Future<void> _changePhoto() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      setState(() => _uploadingPhoto = true);
      await TelegramScope.read(context).setProfilePhoto(picked.path);
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update the photo: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final AppSettings settings = SettingsScope.of(context);
    final Profile? me = store.me;
    final ShellScope? shell = ShellScope.maybeOf(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 150),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 10, 0),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => showProfileQr(context, me),
                  tooltip: 'Show QR code',
                  icon: Icon(
                    Icons.qr_code_2,
                    size: 22,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Pressable(
                  onTap: () => _push(const EditProfileScreen()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      'Edit',
                      style: AppText.body.copyWith(
                        fontSize: 17,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              Avatar(
                title: me?.name ?? 'Courier user',
                seed: me?.id ?? 1,
                size: 96,
                photoFileId: me?.photoFileId ?? 0,
                photoPath: me?.photoPath ?? '',
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  me?.name ?? 'Courier user',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _identity(me),
                style: AppText.subhead.copyWith(color: colors.textSecondary),
              ),
              if (me?.premium ?? false) ...<Widget>[
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.star, size: 12, color: colors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Telegram Premium',
                        style: AppText.caption.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: _uploadingPhoto
                    ? 'Uploading photo…'
                    : 'Change Profile Photo',
                icon: Icons.photo_camera_outlined,
                onTap: _uploadingPhoto ? null : _changePhoto,
                chevron: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Saved Messages',
                icon: Icons.bookmark_outline,
                iconColor: colors.accent,
                chevron: true,
                onTap: () async {
                  final int? id = await store.openSavedMessages();
                  if (id == null || !context.mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext _) => ChatScreen(chatId: id),
                    ),
                  );
                },
              ),
              SettingsRow(
                label: 'Recent Calls',
                icon: Icons.call_outlined,
                iconColor: colors.success,
                chevron: true,
                onTap: () => shell?.goToTab(1),
              ),
              SettingsRow(
                label: 'Devices',
                subtitle: 'Devices signed in to this account',
                icon: Icons.devices_outlined,
                iconColor: colors.accent,
                chevron: true,
                onTap: () => _push(const SessionsScreen()),
              ),
              SettingsRow(
                label: 'Chat Folders',
                subtitle: store.folders.isEmpty
                    ? 'No folders on this account'
                    : '${store.folders.length} folder'
                          '${store.folders.length == 1 ? '' : 's'}',
                icon: Icons.folder_outlined,
                iconColor: colors.accent,
                chevron: true,
                onTap: () => _push(const FoldersScreen()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Notifications and Sounds',
                icon: Icons.notifications,
                iconColor: colors.danger,
                chevron: true,
                onTap: () => _push(const NotificationsScreen()),
              ),
              SettingsRow(
                label: 'Privacy and Security',
                icon: Icons.lock_outline,
                iconColor: colors.textSecondary,
                chevron: true,
                onTap: () => _push(const PrivacyScreen()),
              ),
              SettingsRow(
                label: 'Data and Storage',
                value: store.storageSize > 0
                    ? fileSizeLabel(store.storageSize)
                    : null,
                icon: Icons.storage_outlined,
                iconColor: colors.success,
                chevron: true,
                onTap: () => _push(const DataStorageScreen()),
              ),
              SettingsRow(
                label: 'Appearance',
                value: settings.energySaving
                    ? 'Energy Saving'
                    : (settings.glassStyle == GlassStyle.liquid
                          ? 'Liquid Glass'
                          : 'Classic iOS'),
                icon: Icons.brightness_6_outlined,
                iconColor: colors.accent,
                chevron: true,
                onTap: () => _push(const AppearanceScreen()),
              ),
              SettingsToggle(
                label: 'Energy Saving',
                subtitle: settings.energySaving
                    ? 'Reduced effects are on'
                    : 'Reduce effects and animations',
                icon: Icons.battery_saver_outlined,
                iconColor: colors.success,
                value: settings.energySaving,
                onChanged: settings.setEnergySaving,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Edit profile',
                subtitle: 'Name, bio and username',
                icon: Icons.person_outline,
                iconColor: colors.accent,
                chevron: true,
                onTap: () => _push(const EditProfileScreen()),
              ),
              SettingsRow(
                label: 'Phone number',
                value: me?.phone ?? '—',
                icon: Icons.phone_outlined,
                iconColor: colors.success,
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
            ],
          ),
          const SizedBox(height: 18),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Courier',
                subtitle: 'Version $kAppVersion ($kAppBuild)',
                icon: Icons.info_outline,
                iconColor: colors.accent,
                chevron: true,
                onTap: () => _push(const AboutScreen()),
              ),
              SettingsRow(
                label: 'Connection',
                value: store.connection,
                icon: Icons.wifi,
                iconColor: store.connection == 'Connected'
                    ? colors.success
                    : colors.textSecondary,
              ),
              SettingsRow(
                label: 'TDLib',
                value: store.tdlibVersion.isEmpty
                    ? 'loading…'
                    : store.tdlibVersion,
                icon: Icons.memory,
                iconColor: colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 18),
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
