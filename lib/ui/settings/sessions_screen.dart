import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import '../components/sheets.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TelegramScope.read(context).loadSessions();
    });
  }

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
        title: const Text('Active sessions'),
        actions: <Widget>[
          IconButton(
            onPressed: store.loadSessions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: store.sessions.isEmpty
          ? const EmptyState(
              icon: Icons.devices_outlined,
              title: 'No sessions loaded',
              message: 'Tap refresh to ask Telegram for your signed-in devices.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
              itemCount: store.sessions.length,
              separatorBuilder: (BuildContext _, int __) =>
                  const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final SessionInfo session = store.sessions[index];
                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.smartphone,
                            size: 20,
                            color: session.current
                                ? colors.success
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              session.device,
                              style: AppText.body.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (session.current)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.success.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'This device',
                                style: AppText.caption.copyWith(
                                  color: colors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (session.application.isNotEmpty)
                        Text(
                          session.application,
                          style: AppText.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      if (session.location.isNotEmpty || session.ip.isNotEmpty)
                        Text(
                          <String>[session.location, session.ip]
                              .where((String value) => value.isNotEmpty)
                              .join(' · '),
                          style: AppText.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              session.current
                                  ? 'Active now'
                                  : 'Active ${chatTimestamp(session.lastActive)}',
                              style: AppText.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          if (!session.current)
                            TextButton(
                              onPressed: () async {
                                final bool ok = await showGlassConfirm(
                                  context,
                                  title: 'Terminate session?',
                                  message:
                                      '${session.device} will be signed out of Telegram.',
                                  confirmLabel: 'Terminate',
                                  destructive: true,
                                );
                                if (ok) {
                                  await store.terminateSession(session.id);
                                }
                              },
                              child: Text(
                                'Terminate',
                                style: TextStyle(color: colors.danger),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
