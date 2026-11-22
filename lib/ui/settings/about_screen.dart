import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/telegram_store.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        backgroundColor: colors.groupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: <Widget>[
          const Center(child: BrandMark(size: 78)),
          const SizedBox(height: 14),
          Text(
            'Courier',
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(
              color: colors.textPrimary,
              fontSize: 26,
            ),
          ),
          Text(
            'Version $kAppVersion ($kAppBuild)',
            textAlign: TextAlign.center,
            style: AppText.subhead.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          const SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'Telegram engine',
                subtitle: 'TDLib, the official Telegram client library',
                icon: Icons.memory,
              ),
              SettingsRow(
                label: 'Interface',
                subtitle: 'Flutter with the Liquid Glass material',
                icon: Icons.flutter_dash,
              ),
              SettingsRow(
                label: 'Liquid Glass',
                subtitle: 'liquiglass by shayann07 (Apache-2.0)',
                icon: Icons.blur_on,
                iconColor: Color(0xFF8E5BD6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'TDLib ${store.tdlibVersion.isEmpty ? '(loading)' : store.tdlibVersion}',
              style: AppText.caption.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Pressable(
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Courier',
              applicationVersion: kAppVersion,
            ),
            child: Text(
              'Open source licenses',
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(color: colors.accent),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            kRepoUrl,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 26),
          Text(
            'Courier is an independent Telegram client. It is not affiliated '
            'with, endorsed by, or connected to Telegram Messenger LLP. '
            'Telegram and the Telegram logo are trademarks of Telegram '
            'Messenger LLP.',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
