import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/telegram_store.dart';
import '../components/ios_ui.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 140),
        children: <Widget>[
          const LargeTitle('Calls'),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            // Opaque, like every other iOS group card: only bars and sheets are
            // material, so this screen needs no backdrop filter at all.
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
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
                    child: Icon(
                      Icons.call_outlined,
                      size: 30,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No calls yet',
                    style: AppText.headline.copyWith(color: colors.textPrimary),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Your call history will appear here. Telegram calls need '
                    'the separate tgcalls VoIP engine — it is not part of this '
                    'build, so calls cannot be placed yet.',
                    textAlign: TextAlign.center,
                    style: AppText.subhead.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionLabel('Connection'),
          SettingsGroup(
            children: <Widget>[
              SettingsRow(
                label: 'TDLib',
                value: store.connection,
                icon: Icons.network_check,
                iconColor: store.connection == 'Connected'
                    ? colors.success
                    : colors.textSecondary,
              ),
              SettingsRow(
                label: 'Engine',
                value: store.tdlibVersion.isEmpty
                    ? 'loading'
                    : store.tdlibVersion,
                icon: Icons.memory,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
