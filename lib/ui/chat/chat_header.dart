import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../telegram/models.dart';
import '../components/avatar.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

/// Telegram-iOS conversation bar: back chevron on the left, avatar + name +
/// presence centred, info on the right, all over a glass surface with a
/// hairline at the bottom edge.
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
    final bool typing = chat?.typing ?? false;

    return GlassBar(
      radius: 0,
      tintAmount: colors.dark ? 70 : 58,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 52,
            child: Row(
              children: <Widget>[
                Pressable(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.chevron_left, color: colors.accent, size: 30),
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
                Expanded(
                  child: Pressable(
                    onTap: onInfo,
                    behavior: HitTestBehavior.translucent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Hero(
                          tag: 'avatar-$chatId',
                          child: Avatar(
                            title: title,
                            seed: chatId,
                            size: 30,
                            photoFileId: chat?.photoFileId ?? 0,
                            photoPath: chat?.photoPath ?? '',
                            online: chat?.online ?? false,
                            showOnline:
                                (chat?.isPrivate ?? false) && (chat?.online ?? false),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
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
                                  color: typing ? colors.accent : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: NavIconButton(
                    icon: Icons.info_outline,
                    size: 22,
                    tooltip: 'Chat info',
                    onTap: onInfo,
                  ),
                ),
              ],
            ),
          ),
          Hairline(color: Colors.white.withValues(alpha: colors.dark ? 0.08 : 0.4)),
        ],
      ),
    );
  }
}
