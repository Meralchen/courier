import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../chats/chat_row.dart';
import '../chat/chat_screen.dart';
import '../components/avatar.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

/// Telegram-iOS global search. Chats already on the device are matched while
/// typing; TDLib then answers with the server-side chat, public-chat and
/// message results, which are grouped into sections like the iOS client.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  String? _error;
  SearchResults? _results;

  /// Guards against an older answer overwriting a newer query's results.
  int _token = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final String clean = value.trim();
    setState(() {
      _query = value;
      _error = null;
      if (clean.length < 2) {
        _results = null;
        _loading = false;
      }
    });
    _debounce?.cancel();
    if (clean.length < 2) {
      _token++;
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 280), () => _run(clean));
  }

  Future<void> _run(String clean) async {
    final int token = ++_token;
    try {
      final SearchResults results = await TelegramScope.read(
        context,
      ).search(clean);
      if (!mounted || token != _token) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || token != _token) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _openChat(int chatId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => ChatScreen(chatId: chatId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final String needle = _query.trim().toLowerCase();
    final String clean = _query.trim();

    // Local matches render instantly, before TDLib's answer arrives.
    final List<ChatSummary> local = clean.isEmpty
        ? const <ChatSummary>[]
        : store.chats
              .where(
                (ChatSummary chat) =>
                    chat.title.toLowerCase().contains(needle) ||
                    chat.preview.toLowerCase().contains(needle),
              )
              .toList();

    final Map<int, ChatSummary> merged = <int, ChatSummary>{};
    for (final ChatSummary chat in local) {
      merged[chat.id] = chat;
    }
    for (final ChatSummary chat in _results?.chats ?? const <ChatSummary>[]) {
      merged.putIfAbsent(chat.id, () => chat);
    }
    final List<ChatSummary> chats = merged.values.toList();
    final List<ChatSummary> global = (_results?.global ?? const <ChatSummary>[])
        .where((ChatSummary chat) => !merged.containsKey(chat.id))
        .toList();
    final List<SearchMessageHit> messages = clean.isEmpty
        ? const <SearchMessageHit>[]
        : _results?.messages ?? const <SearchMessageHit>[];
    final bool hasResults =
        chats.isNotEmpty || global.isNotEmpty || messages.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
              child: Row(
                children: <Widget>[
                  NavIconButton(
                    icon: Icons.chevron_left,
                    size: 26,
                    color: colors.accent,
                    tooltip: 'Close search',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        IosSearchField(
                          controller: _controller,
                          focusNode: _focus,
                          hint: 'Search',
                          onChanged: _onChanged,
                          trailing: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _controller.clear();
                                    _onChanged('');
                                  },
                                  icon: Icon(
                                    Icons.cancel,
                                    size: 17,
                                    color: colors.textTertiary,
                                  ),
                                ),
                        ),
                        if (_loading)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: colors.accent,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search is unavailable right now.',
                        style: AppText.footnote.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Pressable(
                      onTap: () => _run(clean),
                      child: Text(
                        'Retry',
                        style: AppText.subhead.copyWith(color: colors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: clean.isEmpty
                  ? _recent(store, colors)
                  : !hasResults && _loading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasResults
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: 'No results',
                      message:
                          'Nothing in your chats or on Telegram matches '
                          '“$clean”.',
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 40),
                      children: <Widget>[
                        if (chats.isNotEmpty) ...<Widget>[
                          const SectionLabel('Chats'),
                          for (final ChatSummary chat in chats)
                            ChatRow(chat: chat),
                        ],
                        if (messages.isNotEmpty) ...<Widget>[
                          const SectionLabel('Messages'),
                          for (final SearchMessageHit hit in messages)
                            _MessageHitRow(
                              hit: hit,
                              onTap: () => _openChat(hit.chatId),
                            ),
                        ],
                        if (global.isNotEmpty) ...<Widget>[
                          const SectionLabel('Global'),
                          for (final ChatSummary chat in global)
                            ChatRow(chat: chat),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recent(TelegramStore store, AppColors colors) {
    final List<ChatSummary> recent = store.chats.take(12).toList();
    if (recent.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search',
        message:
            'Find people, groups, channels and messages from all of '
            'Telegram.',
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 30),
      children: <Widget>[
        const SectionLabel('Chats'),
        for (final ChatSummary chat in recent) ChatRow(chat: chat),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
          child: Text(
            'Search also looks through public chats and every message on '
            'your account.',
            style: AppText.caption.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// One message result: who sent it, the chat it lives in and a preview. iOS
/// puts the chat title above the highlighted snippet.
class _MessageHitRow extends StatelessWidget {
  const _MessageHitRow({required this.hit, required this.onTap});

  final SearchMessageHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Message message = hit.message;
    final String sender = message.outgoing ? 'You' : message.sender;
    final String snippet = message.text.isEmpty
        ? _kindLabel(message.kind)
        : message.text;
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Avatar(
              title: hit.title.isEmpty ? 'Chat' : hit.title,
              seed: hit.chatId,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          hit.title.isEmpty ? 'Chat' : hit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chatTimestamp(message.date),
                        style: AppText.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sender.isEmpty ? snippet : '$sender: $snippet',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subhead.copyWith(
                      fontSize: 14.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _kindLabel(String kind) => switch (kind) {
    'photo' => 'Photo',
    'video' => 'Video',
    'animation' => 'GIF',
    'document' => 'File',
    'audio' => 'Audio',
    'voice' => 'Voice message',
    'videoNote' => 'Video message',
    'sticker' => 'Sticker',
    'location' => 'Location',
    'contact' => 'Contact',
    'poll' => 'Poll',
    _ => 'Message',
  };
}
