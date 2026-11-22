import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../components/ios_ui.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Profile? me = TelegramScope.of(context).me;
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        backgroundColor: colors.groupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Privacy and security'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: <Widget>[
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Phone number',
                value: me?.phone.isNotEmpty == true ? me!.phone : '—',
                icon: Icons.phone_outlined,
              ),
              SettingsRow(
                label: 'Username',
                value: me?.username.isNotEmpty == true ? '@${me!.username}' : 'None',
                icon: Icons.alternate_email,
              ),
              SettingsRow(
                label: 'Two-step verification',
                subtitle: 'Set and changed in Telegram',
                icon: Icons.password,
              ),
            ],
          ),
          const SectionLabel('Managed by Telegram'),
          SettingsGroup(
            children: const <Widget>[
              SettingsRow(
                label: 'Last seen and online',
                subtitle: 'Privacy rules live on your Telegram account',
                icon: Icons.visibility_outlined,
              ),
              SettingsRow(
                label: 'Read receipts',
                subtitle: 'Shared with TDLib like any Telegram client',
                icon: Icons.done_all,
              ),
              SettingsRow(
                label: 'Blocked users',
                subtitle: 'Editing blocks is not in this build yet',
                icon: Icons.block,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Courier uses TDLib, Telegram\'s official client library. Your '
            'cloud chats are stored by Telegram; secret chats are not enabled '
            'in this build. Nothing is routed through a Courier server.',
            style: AppText.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
