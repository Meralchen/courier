import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../chat/chat_screen.dart';
import '../components/avatar.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';
import '../components/sheets.dart';

class ChatRow extends StatelessWidget {
  const ChatRow({
    super.key,
    required this.chat,
    this.onTap,
    this.selecting = false,
    this.selected = false,
  });

  final ChatSummary chat;

  /// Overrides the tap action, used by multi-select mode.
  final VoidCallback? onTap;

  /// Edit mode shows a selection circle and suppresses the action sheet.
  final bool selecting;
  final bool selected;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext _) => ChatScreen(chatId: chat.id),
      ),
    );
  }

  Future<void> _actions(BuildContext context) async {
    final TelegramStore store = TelegramScope.read(context);
    final String? action = await showActionSheet<String>(
      context,
      title: chat.title,
      actions: <SheetAction<String>>[
        SheetAction<String>(
          label: chat.pinned ? 'Unpin' : 'Pin',
          icon: Icons.push_pin_outlined,
          value: 'pin',
        ),
        SheetAction<String>(
          label: chat.muted ? 'Unmute' : 'Mute',
          icon: chat.muted
              ? Icons.volume_up_outlined
              : Icons.volume_off_outlined,
          value: 'mute',
        ),
        const SheetAction<String>(
          label: 'Mark as read',
          icon: Icons.done_all,
          value: 'read',
        ),
        const SheetAction<String>(
          label: 'Clear history',
          icon: Icons.cleaning_services_outlined,
          value: 'clear',
        ),
        const SheetAction<String>(
          label: 'Delete chat',
          icon: Icons.delete_outline,
          value: 'delete',
          destructive: true,
        ),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'pin':
        await store.setPinned(chat.id, !chat.pinned);
      case 'mute':
        await store.setMuted(chat.id, !chat.muted);
      case 'read':
        await store.markRead(chat.id);
      case 'clear':
        final bool ok = await showGlassConfirm(
          context,
          title: 'Clear history?',
          message: 'Messages in this chat will be removed from your account.',
          confirmLabel: 'Clear',
          destructive: true,
        );
        if (ok) await store.clearHistory(chat.id);
      case 'delete':
        final bool ok = await showGlassConfirm(
          context,
          title: 'Delete chat?',
          message: 'The chat and its history will be removed for you.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (ok) await store.deleteChat(chat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String preview = chat.typing ? 'typing…' : chat.preview;
    final bool unread = chat.unread > 0;

    return Pressable(
      onTap: onTap ?? () => _open(context),
      onLongPress: selecting ? null : () => _actions(context),
      scale: 0.985,
      child: ColoredBox(
        color: selected
            ? colors.accent.withValues(alpha: 0.10)
            : Colors.transparent,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (selecting) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        size: 22,
                        color: selected ? colors.accent : colors.textTertiary,
                      ),
                    ),
                  ],
                  Hero(
                    tag: 'avatar-${chat.id}',
                    child: Avatar(
                      title: chat.title,
                      seed: chat.id,
                      size: 54,
                      photoFileId: chat.photoFileId,
                      photoPath: chat.photoPath,
                      online: chat.online,
                      showOnline: chat.isPrivate && chat.online,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                chat.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.title.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 16.5,
                                ),
                              ),
                            ),
                            if (chat.pinned) ...<Widget>[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.push_pin,
                                size: 12,
                                color: colors.textTertiary,
                              ),
                            ],
                            if (chat.muted) ...<Widget>[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.volume_off,
                                size: 13,
                                color: colors.textTertiary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            if (chat.lastOutgoing) ...<Widget>[
                              Icon(
                                Icons.done_all,
                                size: 14,
                                color: colors.accent,
                              ),
                              const SizedBox(width: 2),
                            ],
                            Expanded(
                              child: Text(
                                preview.isEmpty ? 'No messages yet' : preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.subhead.copyWith(
                                  color: chat.typing
                                      ? colors.accent
                                      : colors.textSecondary,
                                  fontStyle: chat.typing
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        formatChatTime(chat.date),
                        style: AppText.caption.copyWith(
                          color: unread ? colors.accent : colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (unread)
                        Container(
                          constraints: const BoxConstraints(minWidth: 21),
                          height: 21,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: chat.muted
                                ? colors.textTertiary
                                : colors.accent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            chat.unread > 999 ? '999+' : '${chat.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (chat.muted)
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 15,
                          color: colors.textTertiary,
                        )
                      else
                        const SizedBox(height: 21),
                    ],
                  ),
                ],
              ),
            ),
            const Hairline(indent: 79),
          ],
        ),
      ),
    );
  }
}

String formatChatTime(int epochSeconds) => chatTimestamp(epochSeconds);
