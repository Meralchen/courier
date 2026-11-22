import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../telegram/models.dart';
import '../components/avatar.dart';
import '../components/glass.dart';
import '../components/pressable.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.chat,
    required this.chatId,
    required this.onBack,
    required this.onInfo,
  });

  final ChatSummary? chat;
  final int chatId;
  final VoidCallback onBack;
  final VoidCallback onInfo;

  String _subtitle() {
    final ChatSummary? value = chat;
    if (value == null) return 'Connecting…';
    if (value.typing) return 'typing…';
    if (value.isPrivate) {
      if (value.online) return 'online';
      return lastSeenLabel(value.lastSeen);
    }
    if (value.memberCount > 0) return '${value.memberCount} members';
    return value.isGroup ? 'group chat' : 'channel';
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String title = chat?.title ?? 'Chat';
    return GlassBar(
      radius: 0,
      tintAmount: colors.dark ? 62 : 50,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: SizedBox(
        height: 56,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 2),
            Pressable(
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.chevron_left, color: colors.accent, size: 28),
                    Text(
                      'Chats',
                      style: AppText.body.copyWith(
                        color: colors.accent,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 2),
            Hero(
              tag: 'avatar-$chatId',
              child: Avatar(
                title: title,
                seed: chatId,
                size: 32,
                photoFileId: chat?.photoFileId ?? 0,
                photoPath: chat?.photoPath ?? '',
                online: chat?.online ?? false,
                showOnline: (chat?.isPrivate ?? false) && (chat?.online ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Pressable(
                onTap: onInfo,
                behavior: HitTestBehavior.translucent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(
                        color: colors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: (chat?.typing ?? false)
                            ? colors.accent
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GlassCircleButton(
              icon: Icons.info_outline,
              size: 34,
              onTap: onInfo,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
