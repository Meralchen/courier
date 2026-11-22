import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
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
import 'add_members_screen.dart';
import 'chat_screen.dart';

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

  Future<void> _openMember(int userId) async {
    final int? chatId = await TelegramScope.read(context).openUser(userId);
    if (!mounted || chatId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => ChatScreen(chatId: chatId),
      ),
    );
  }

  Future<String?> _prompt({
    required String title,
    required String initial,
    int maxLines = 1,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initial,
    );
    final String? value = await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            minLines: 1,
            maxLines: maxLines,
            padding: const EdgeInsets.all(10),
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _addMembers() async {
    final bool? added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext _) => AddMembersScreen(chatId: widget.chatId),
      ),
    );
    if (added == true && mounted) {
      await TelegramScope.read(context).loadChatInfo(widget.chatId);
    }
  }

  Future<void> _leaveChat(ChatSummary chat) async {
    final TelegramStore store = TelegramScope.read(context);
    final bool confirmed = await showGlassConfirm(
      context,
      title: chat.isGroup ? 'Leave group?' : 'Leave channel?',
      message: 'You will stop receiving messages from this chat.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (!confirmed) return;
    await store.leaveChat(widget.chatId);
    if (mounted) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
  }

  Future<void> _copy(String value, String label) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied')));
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
    final String title = info?.title.isNotEmpty == true
        ? info!.title
        : chat.title;
    final String about = info?.about ?? '';
    final List<ChatMemberInfo> members =
        info?.members ?? const <ChatMemberInfo>[];
    final int memberCount = info?.memberCount ?? chat.memberCount;
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
                              : memberCount > 0
                              ? '$memberCount ${chat.isGroup ? 'members' : 'subscribers'}'
                              : (chat.isGroup ? 'group chat' : 'channel'),
                          textAlign: TextAlign.center,
                          style: AppText.subhead.copyWith(
                            color: chat.online
                                ? colors.success
                                : colors.textSecondary,
                          ),
                        ),
                        if (phone.isNotEmpty ||
                            username.isNotEmpty) ...<Widget>[
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
                          onTap: () =>
                              store.setMuted(widget.chatId, !chat.muted),
                        ),
                        _Action(
                          icon: chat.pinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
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
                if (members.isNotEmpty) ...<Widget>[
                  const SliverToBoxAdapter(child: SectionLabel('Members')),
                  SliverToBoxAdapter(
                    child: SettingsGroup(
                      children: <Widget>[
                        for (final ChatMemberInfo member in members)
                          Pressable(
                            onTap: () => _openMember(member.userId),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Avatar(
                                    title: member.title,
                                    seed: member.userId,
                                    size: 32,
                                    photoFileId: member.photoFileId,
                                    photoPath: member.photoPath,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          member.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.body.copyWith(
                                            fontSize: 16,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        if (member.username.isNotEmpty)
                                          Text(
                                            '@${member.username}',
                                            style: AppText.caption.copyWith(
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: colors.textTertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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
                                        errorBuilder:
                                            (
                                              BuildContext _,
                                              Object __,
                                              StackTrace? ___,
                                            ) => Container(
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
                      if (!chat.isPrivate) ...<Widget>[
                        if (chat.isGroup)
                          SettingsRow(
                            label: 'Add members',
                            icon: Icons.person_add_alt_1_outlined,
                            iconColor: colors.accent,
                            chevron: true,
                            onTap: _addMembers,
                          ),
                        SettingsRow(
                          label: 'Edit name',
                          icon: Icons.edit_outlined,
                          iconColor: colors.accent,
                          chevron: true,
                          onTap: () async {
                            final TelegramStore store = TelegramScope.read(
                              context,
                            );
                            final String? name = await _prompt(
                              title: 'Group name',
                              initial: title,
                            );
                            if (name == null || name.trim().isEmpty) return;
                            await store.setChatTitle(widget.chatId, name);
                            await store.loadChatInfo(widget.chatId);
                          },
                        ),
                        SettingsRow(
                          label: 'Edit description',
                          icon: Icons.notes_outlined,
                          iconColor: colors.textSecondary,
                          chevron: true,
                          onTap: () async {
                            final TelegramStore store = TelegramScope.read(
                              context,
                            );
                            final String? description = await _prompt(
                              title: 'Description',
                              initial: about,
                              maxLines: 3,
                            );
                            if (description == null) return;
                            await store.setChatDescription(
                              widget.chatId,
                              description,
                            );
                            await store.loadChatInfo(widget.chatId);
                          },
                        ),
                      ],
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
                      if (!chat.isPrivate)
                        SettingsRow(
                          label: chat.isGroup ? 'Leave group' : 'Leave channel',
                          icon: Icons.logout,
                          iconColor: colors.danger,
                          danger: true,
                          onTap: () => _leaveChat(chat),
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
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.onTap,
  });

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
        GlassCircleButton(
          icon: icon,
          size: 46,
          color: colors.accent,
          onTap: onTap,
        ),
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
