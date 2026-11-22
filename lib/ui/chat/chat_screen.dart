import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/wallpaper.dart';
import '../../state/app_settings.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../../telegram/voice_recorder.dart';
import '../components/glass.dart';
import '../components/photo_viewer.dart';
import '../components/sheets.dart';
import 'chat_header.dart';
import 'chat_info_screen.dart';
import 'composer.dart';
import 'forward_screen.dart';
import 'message_actions.dart';
import 'sticker_panel.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final int chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _draft = TextEditingController();

  TelegramStore? _store;
  Message? _reply;
  bool _nearBottom = true;
  bool _loadingMore = false;
  bool _sendingPhoto = false;
  bool _unreadCaptured = false;
  int? _unreadMarker;
  int _lastCount = 0;
  bool _didInitialJump = false;

  // Bubbles are expensive to build (layout, media, copy). TDLib notifies for
  // typing and files too; rebuilding every bubble for those is what made a
  // long chat stutter. Rows are reused until the message list object, the
  // media version, typing state or theme actually change.
  List<Widget>? _cachedRows;
  List<Message>? _cachedMessages;
  int _cachedFiles = -1;
  bool _cachedTyping = false;
  bool _cachedDark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TelegramScope.read(context).openChat(widget.chatId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = TelegramScope.of(context);
    if (_unreadCaptured) return;
    final ChatSummary? chat = _store!.chat(widget.chatId);
    if (chat != null) {
      _unreadCaptured = true;
      _unreadMarker = chat.unread > 0 ? chat.readInboxMaxId + 1 : null;
    }
  }

  @override
  void didChangeMetrics() {
    if (_nearBottom) _scheduleJump(animate: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _draft.dispose();
    _store?.closeChat();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final bool near =
        _scroll.position.maxScrollExtent - _scroll.position.pixels < 160;
    if (near != _nearBottom) setState(() => _nearBottom = near);
    if (_scroll.position.pixels < 280) _loadMore();
  }

  void _scheduleJump({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final double target = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          target,
          duration: Motion.normal,
          curve: Motion.emphasized,
        );
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  Future<void> _loadMore() async {
    final TelegramStore store = TelegramScope.read(context);
    if (_loadingMore || !store.hasMore(widget.chatId)) return;
    _loadingMore = true;
    final ScrollPosition? position = _scroll.hasClients
        ? _scroll.position
        : null;
    final double beforeMax = position?.maxScrollExtent ?? 0;
    final double beforePixels = position?.pixels ?? 0;
    await store.loadMore(widget.chatId);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final double delta = _scroll.position.maxScrollExtent - beforeMax;
      _scroll.jumpTo(
        (beforePixels + delta).clamp(
          _scroll.position.minScrollExtent,
          _scroll.position.maxScrollExtent,
        ),
      );
    });
    _loadingMore = false;
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;
      setState(() => _sendingPhoto = true);
      await TelegramScope.read(
        context,
      ).sendPhoto(widget.chatId, picked.path, replyToId: _reply?.id);
      if (!mounted) return;
      setState(() {
        _sendingPhoto = false;
        _reply = null;
      });
      _scheduleJump(animate: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _sendingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the photo: $error')),
      );
    }
  }

  Future<bool> _startVoice() async {
    try {
      await VoiceRecorder.start();
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
      return false;
    }
  }

  Future<void> _finishVoice(bool send) async {
    VoiceClip? clip;
    try {
      clip = await VoiceRecorder.stop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Recording failed: $error')));
      }
      return;
    }
    if (clip == null) return;
    if (!send) {
      // A cancelled gesture still produced a file; TDLib never sees it.
      return;
    }
    if (!mounted) return;
    final int? replyId = _reply?.id;
    setState(() => _reply = null);
    await TelegramScope.read(
      context,
    ).sendVoice(widget.chatId, clip.path, clip.duration, replyToId: replyId);
    if (mounted) _scheduleJump(animate: true);
  }

  Future<void> _send(String text) async {
    final int? replyId = _reply?.id;
    _draft.clear();
    setState(() => _reply = null);
    await TelegramScope.read(
      context,
    ).sendText(widget.chatId, text, replyToId: replyId);
    _scheduleJump(animate: true);
  }

  Future<void> _openStickers() async {
    final TelegramStore store = TelegramScope.read(context);
    await showStickerPanel(
      context,
      store: store,
      onSticker: (StickerItem sticker) async {
        await store.sendSticker(widget.chatId, sticker);
        if (mounted) _scheduleJump(animate: true);
      },
      onGif: (GifItem gif) async {
        await store.sendGif(widget.chatId, gif);
        if (mounted) _scheduleJump(animate: true);
      },
      onEmoji: (String emoji) {
        final TextEditingValue value = _draft.value;
        final int offset = value.selection.baseOffset < 0
            ? value.text.length
            : value.selection.baseOffset;
        _draft.value = TextEditingValue(
          text: value.text.replaceRange(offset, offset, emoji),
          selection: TextSelection.collapsed(offset: offset + emoji.length),
        );
      },
    );
  }

  Future<void> _react(Message message, TelegramStore store) async {
    List<String> emojis = await store.availableReactions(
      widget.chatId,
      message.id,
    );
    if (emojis.isEmpty) {
      emojis = const <String>['👍', '❤️', '🔥', '🎉', '😂', '😮', '😢', '🙏'];
    }
    if (!mounted) return;
    final String? emoji = await showReactionPicker(context, emojis);
    if (emoji == null) return;
    await store.toggleReaction(widget.chatId, message.id, emoji);
  }

  Future<void> _actions(Message message) async {
    final TelegramStore store = TelegramScope.read(context);
    final List<SheetAction<String>> actions = <SheetAction<String>>[
      const SheetAction<String>(
        label: 'React',
        icon: Icons.add_reaction_outlined,
        value: 'react',
      ),
      if (message.text.isNotEmpty)
        const SheetAction<String>(
          label: 'Copy',
          icon: Icons.copy,
          value: 'copy',
        ),
      const SheetAction<String>(
        label: 'Reply',
        icon: Icons.reply,
        value: 'reply',
      ),
      const SheetAction<String>(
        label: 'Forward',
        icon: Icons.forward,
        value: 'forward',
      ),
      if (message.outgoing &&
          message.kind == 'text' &&
          !message.pending &&
          !message.failed)
        const SheetAction<String>(
          label: 'Edit',
          icon: Icons.edit_outlined,
          value: 'edit',
        ),
      const SheetAction<String>(
        label: 'Delete',
        icon: Icons.delete_outline,
        value: 'delete',
        destructive: true,
      ),
    ];
    final String? action = await showActionSheet<String>(
      context,
      title: message.text.isEmpty ? 'Message' : message.text,
      actions: actions,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'react':
        await _react(message, store);
      case 'copy':
        await copyMessageText(context, message.text);
      case 'reply':
        setState(() => _reply = message);
      case 'forward':
        final bool? forwarded = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (BuildContext _) => ForwardScreen(
              fromChatId: widget.chatId,
              messageIds: <int>[message.id],
            ),
          ),
        );
        if (forwarded == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message forwarded'),
              duration: Duration(milliseconds: 1400),
            ),
          );
        }
      case 'edit':
        final String? edited = await showEditMessageDialog(context, message);
        if (edited != null) {
          await store.editMessage(widget.chatId, message.id, edited);
        }
      case 'delete':
        final bool confirmed = await showGlassConfirm(
          context,
          title: 'Delete message?',
          message: 'It will be deleted for everyone in this chat.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (confirmed) {
          await store.deleteMessages(widget.chatId, <int>[message.id]);
        }
    }
  }

  List<Widget> _rows(
    List<Message> messages,
    ChatSummary? chat,
    TelegramStore store,
  ) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < messages.length; i++) {
      final Message message = messages[i];
      final Message? previous = i > 0 ? messages[i - 1] : null;
      final Message? next = i < messages.length - 1 ? messages[i + 1] : null;

      if (previous == null || !sameDay(previous.date, message.date)) {
        rows.add(_DateDivider(epoch: message.date));
      }
      if (_unreadMarker != null &&
          message.id >= _unreadMarker! &&
          (previous == null || previous.id < _unreadMarker!)) {
        rows.add(const _UnreadDivider());
      }
      if (message.isService) {
        rows.add(_ServiceRow(text: message.text));
        continue;
      }

      final bool samePrevious =
          previous != null &&
          previous.outgoing == message.outgoing &&
          !previous.isService &&
          sameDay(previous.date, message.date);
      final bool sameNext =
          next != null &&
          next.outgoing == message.outgoing &&
          !next.isService &&
          sameDay(next.date, message.date);
      final String imagePath = store.pathFor(
        message.photoFileId,
        message.photoPath,
      );

      rows.add(
        MessageBubble(
          message: message,
          isFirst: !samePrevious,
          isLast: !sameNext,
          showSender:
              !message.outgoing &&
              (!samePrevious || previous.sender != message.sender),
          onLongPress: () => _actions(message),
          onPhotoTap: () =>
              openPhoto(context, path: imagePath, caption: message.text),
          onReactionTap: (String emoji) =>
              store.toggleReaction(widget.chatId, message.id, emoji),
        ),
      );
    }
    if (chat?.typing ?? false) {
      rows.add(const _TypingBubble());
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final AppSettings? settings = SettingsScope.maybeOf(context);
    final TelegramStore store = TelegramScope.of(context);
    final ChatSummary? chat = store.chat(widget.chatId);
    final List<Message> messages = store.messagesFor(widget.chatId);
    final bool rowsFresh =
        _cachedRows != null &&
        identical(messages, _cachedMessages) &&
        store.filesVersion == _cachedFiles &&
        (chat?.typing ?? false) == _cachedTyping &&
        colors.dark == _cachedDark;
    final List<Widget> rows;
    if (rowsFresh) {
      rows = _cachedRows!;
    } else {
      rows = _rows(messages, chat, store);
      _cachedRows = rows;
      _cachedMessages = messages;
      _cachedFiles = store.filesVersion;
      _cachedTyping = chat?.typing ?? false;
      _cachedDark = colors.dark;
    }

    if (!_didInitialJump && messages.isNotEmpty) {
      _didInitialJump = true;
      _lastCount = messages.length;
      _scheduleJump(animate: false);
    } else if (messages.length > _lastCount) {
      _lastCount = messages.length;
      if (_nearBottom) _scheduleJump(animate: true);
    }

    return Scaffold(
      backgroundColor: colors.chatBackdrop,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ChatWallpaperBackdrop(
              style: settings?.wallpaper ?? ChatWallpaper.doodle,
              dark: colors.dark,
              energySaving: settings?.energySaving ?? false,
            ),
          ),
          Column(
            children: <Widget>[
              Expanded(
                // The jump-to-latest button lives in the transcript, not the
                // page: anchoring it to the scaffold put it over the composer
                // as soon as a reply preview made the composer taller.
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: messages.isEmpty
                          ? const _EmptyConversation()
                          : ListView.builder(
                              controller: _scroll,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                2,
                                MediaQuery.paddingOf(context).top + 66,
                                2,
                                10,
                              ),
                              itemCount: rows.length,
                              itemBuilder: (BuildContext context, int index) =>
                                  rows[index],
                            ),
                    ),
                    if (!_nearBottom)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: GlassCircleButton(
                          icon: Icons.keyboard_arrow_down,
                          size: 38,
                          tooltip: 'Scroll to latest',
                          onTap: () => _scheduleJump(animate: true),
                        ),
                      ),
                  ],
                ),
              ),
              Composer(
                controller: _draft,
                replyTo: _reply,
                sendingPhoto: _sendingPhoto,
                onCancelReply: () => setState(() => _reply = null),
                onSend: _send,
                onPickPhoto: _pickPhoto,
                onTyping: (bool typing) =>
                    store.sendTyping(widget.chatId, typing),
                onOpenStickers: _openStickers,
                onVoiceStart: _startVoice,
                onVoiceFinish: _finishVoice,
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatHeader(
              chat: chat,
              chatId: widget.chatId,
              onBack: () => Navigator.of(context).pop(),
              onInfo: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (BuildContext _) =>
                      ChatInfoScreen(chatId: widget.chatId),
                ),
              ),
            ),
          ),
          if (_loadingMore)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 66,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colors.card.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.epoch});

  final int epoch;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 9),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: colors.dark ? 0.45 : 0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          dayLabel(epoch),
          style: AppText.caption.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        children: <Widget>[
          Expanded(child: Container(height: 0.6, color: colors.danger)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Unread messages',
              style: AppText.caption.copyWith(
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Container(height: 0.6, color: colors.danger)),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 26),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: colors.dark ? 0.5 : 0.65),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: colors.bubbleIn,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: colors.separator, width: 0.6),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity:
                        0.35 +
                        0.65 *
                            ((1 - ((_controller.value * 3 - i).abs() % 1)) * 1)
                                .clamp(0.0, 1.0),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GlassCircleButton(
            icon: Icons.chat_bubble_outline,
            size: 66,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            'No messages yet',
            style: AppText.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 5),
          Text(
            'Send the first message below.',
            style: AppText.subhead.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
