import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/avatar.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import '../components/photo_viewer.dart';
import '../components/pressable.dart';
import '../components/sheets.dart';

class ChatInfoScreen extends StatefulWidget {
  const ChatInfoScreen({super.key, required this.chatId});

  final int chatId;

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        TelegramScope.read(context).loadChatInfo(widget.chatId);
      }
    });
  }

  Future<void> _copy(String value, String label) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final ChatSummary? chat = store.chat(widget.chatId);
    final ChatInfo? info = store.infoFor(widget.chatId);
    if (chat == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final String title = info?.title.isNotEmpty == true ? info!.title : chat.title;
    final String about = info?.about ?? '';
    final String phone = info?.phone ?? '';
    final String username = info?.username ?? '';
    final int photoFileId = info?.photoFileId ?? chat.photoFileId;
    final String photoPath = (info?.photoPath.isNotEmpty ?? false)
        ? info!.photoPath
        : chat.photoPath;
    final List<Message> media = store
        .messagesFor(widget.chatId)
        .where((Message message) => message.hasMedia && message.kind == 'photo')
        .toList()
        .reversed
        .toList();

    return Scaffold(
      backgroundColor: colors.groupedBackground,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LiquidWallpaper(
              base: colors.chatBackdrop,
              dark: colors.dark,
              intensity: 0.55,
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 2, 14, 6),
                    child: Row(
                      children: <Widget>[
                        GlassCircleButton(
                          icon: Icons.chevron_left,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            'Info',
                            textAlign: TextAlign.center,
                            style: AppText.title.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Column(
                      children: <Widget>[
                        Avatar(
                          title: title,
                          seed: widget.chatId,
                          size: 96,
                          photoFileId: photoFileId,
                          photoPath: photoPath,
                          online: chat.online,
                          showOnline: chat.isPrivate && chat.online,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppText.headline.copyWith(
                            color: colors.textPrimary,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          chat.isPrivate
                              ? (chat.online
                                  ? 'online'
                                  : lastSeenLabel(chat.lastSeen))
                              : (chat.isGroup ? 'group chat' : 'channel'),
                          textAlign: TextAlign.center,
                          style: AppText.subhead.copyWith(
                            color: chat.online
                                ? colors.success
                                : colors.textSecondary,
                          ),
                        ),
                        if (phone.isNotEmpty || username.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: <Widget>[
                              if (phone.isNotEmpty)
                                _InfoPill(
                                  icon: Icons.phone_outlined,
                                  text: phone,
                                  onTap: () => _copy(phone, 'Phone number'),
                                ),
                              if (username.isNotEmpty)
                                _InfoPill(
                                  icon: Icons.alternate_email,
                                  text: '@$username',
                                  onTap: () => _copy('@$username', 'Username'),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _Action(
                          icon: Icons.chat_bubble_outline,
                          label: 'Message',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        _Action(
                          icon: chat.muted
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          label: chat.muted ? 'Unmute' : 'Mute',
                          onTap: () => store.setMuted(
                            widget.chatId,
                            !chat.muted,
                          ),
                        ),
                        _Action(
                          icon: chat.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                          label: chat.pinned ? 'Unpin' : 'Pin',
                          onTap: () =>
                              store.setPinned(widget.chatId, !chat.pinned),
                        ),
                      ],
                    ),
                  ),
                ),
                if (about.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'About',
                              style: AppText.caption.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              about,
                              style: AppText.body.copyWith(
                                color: colors.textPrimary,
                                fontSize: 15.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SectionLabel('Notifications')),
                SliverToBoxAdapter(
                  child: SettingsGroup(
                    children: <Widget>[
                      SettingsToggle(
                        label: 'Mute notifications',
                        subtitle: 'Pins stay quiet until you unmute them',
                        value: chat.muted,
                        icon: Icons.notifications_outlined,
                        iconColor: colors.danger,
                        onChanged: (bool value) =>
                            store.setMuted(widget.chatId, value),
                      ),
                      SettingsRow(
                        label: 'Pin chat',
                        icon: Icons.push_pin_outlined,
                        iconColor: colors.accent,
                        value: chat.pinned ? 'On' : 'Off',
                        onTap: () =>
                            store.setPinned(widget.chatId, !chat.pinned),
                      ),
                    ],
                  ),
                ),
                if (media.isNotEmpty) ...<Widget>[
                  const SliverToBoxAdapter(child: SectionLabel('Shared media')),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: GlassCard(
                        padding: const EdgeInsets.all(6),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemCount: media.length > 9 ? 9 : media.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Message message = media[index];
                            final String path = store.pathFor(
                              message.photoFileId,
                              message.photoPath,
                            );
                            return GestureDetector(
                              onTap: path.isEmpty
                                  ? () => store.ensureFile(message.photoFileId)
                                  : () => openPhoto(context, path: path),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: path.isEmpty
                                    ? Container(
                                        color: colors.cardElevated,
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: colors.textTertiary,
                                        ),
                                      )
                                    : Image.file(
                                        File(path),
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          BuildContext _,
                                          Object __,
                                          StackTrace? ___,
                                        ) =>
                                            Container(
                                          color: colors.cardElevated,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SectionLabel('Chat')),
                SliverToBoxAdapter(
                  child: SettingsGroup(
                    children: <Widget>[
                      SettingsRow(
                        label: 'Clear history',
                        icon: Icons.cleaning_services_outlined,
                        iconColor: colors.textSecondary,
                        onTap: () async {
                          final bool ok = await showGlassConfirm(
                            context,
                            title: 'Clear history?',
                            message:
                                'Messages in this chat will be removed from your account.',
                            confirmLabel: 'Clear',
                            destructive: true,
                          );
                          if (ok) {
                            await store.clearHistory(widget.chatId);
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        },
                      ),
                      SettingsRow(
                        label: 'Delete chat',
                        icon: Icons.delete_outline,
                        iconColor: colors.danger,
                        danger: true,
                        onTap: () async {
                          final bool ok = await showGlassConfirm(
                            context,
                            title: 'Delete chat?',
                            message:
                                'This removes the chat and its history for you.',
                            confirmLabel: 'Delete',
                            destructive: true,
                          );
                          if (ok) {
                            await store.deleteChat(widget.chatId);
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: colors.textSecondary),
            const SizedBox(width: 5),
            Text(
              text,
              style: AppText.caption.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Column(
      children: <Widget>[
        GlassCircleButton(icon: icon, size: 46, color: colors.accent, onTap: onTap),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
