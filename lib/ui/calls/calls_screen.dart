import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/telegram_store.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const LargeTitle('Calls'),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 140),
              children: <Widget>[
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      GlassCircleButton(
                        icon: Icons.call_outlined,
                        size: 68,
                        color: colors.accent,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No calls yet',
                        style: AppText.headline.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Telegram calls use a separate VoIP stack with '
                        'end-to-end encryption. Courier does not ship that '
                        'engine yet, so this tab shows no history and cannot '
                        'place calls.',
                        textAlign: TextAlign.center,
                        style: AppText.subhead.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Diagnostics', padding: EdgeInsets.fromLTRB(12, 20, 12, 6)),
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.network_check,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'TDLib connection',
                              style: AppText.subhead.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            store.connection,
                            style: AppText.caption.copyWith(
                              color: store.connection == 'Connected'
                                  ? colors.success
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.memory,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'TDLib version',
                              style: AppText.subhead.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            store.tdlibVersion.isEmpty
                                ? 'loading'
                                : store.tdlibVersion,
                            style: AppText.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
