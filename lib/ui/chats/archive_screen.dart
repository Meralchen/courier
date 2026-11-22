import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/ios_ui.dart';
import 'chat_row.dart';

/// The archive Telegram-iOS opens from the "Archived Chats" row: the same rows
/// as the main list, drawn from TDLib's archive chat list. Long-press offers
/// Unarchive through [ChatRow].
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.read(context);
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: <Widget>[
                    NavIconButton(
                      icon: Icons.chevron_left,
                      size: 28,
                      color: colors.accent,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Archived Chats',
                        style: AppText.title.copyWith(
                          fontSize: 17,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Hairline(),
            Expanded(
              child: StoreSelector<Object>(
                select: (TelegramStore store) =>
                    '${store.chatsVersion}|${store.filesVersion}|'
                    '${store.connection}',
                builder: (BuildContext context, Object _) {
                  final List<ChatSummary> archived = store.archivedChats;
                  if (archived.isEmpty) {
                    return const EmptyState(
                      icon: Icons.archive_outlined,
                      title: 'No archived chats',
                      message:
                          'Chats you archive from the chat list or a chat '
                          'action appear here and stay out of the main list.',
                    );
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 30),
                    itemCount: archived.length,
                    itemBuilder: (BuildContext context, int index) =>
                        ChatRow(chat: archived[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
