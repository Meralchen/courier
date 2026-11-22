import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:liquiglass/liquiglass.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../chat/chat_screen.dart';
import '../components/ios_ui.dart';
import 'chat_row.dart';
import 'stories_row.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<ChatSummary> _filtered(List<ChatSummary> source) {
    if (_query.trim().isEmpty) return source;
    final String needle = _query.toLowerCase();
    return source
        .where(
          (ChatSummary chat) =>
              chat.title.toLowerCase().contains(needle) ||
              chat.preview.toLowerCase().contains(needle),
        )
        .toList();
  }

  Future<void> _newChat() async {
    final int? chatId = await Navigator.of(context).push<int>(
      CupertinoPageRoute<int>(
        builder: (BuildContext _) => const NewChatScreen(),
      ),
    );
    if (chatId != null && mounted) {
      await Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (BuildContext context) => ChatScreen(chatId: chatId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TelegramStore store = TelegramScope.read(context);
    return StoreSelector<Object>(
      select: (TelegramStore store) =>
          '${store.chatsVersion}|${store.storiesVersion}|'
          '${store.totalUnread}|${store.connection}',
      builder: (BuildContext context, Object _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, TelegramStore store) {
    final AppColors colors = AppColors.of(context);
    final List<ChatSummary> all = _filtered(store.chats);
    final List<ChatSummary> pinned = all
        .where((ChatSummary chat) => chat.pinned)
        .toList();
    final List<ChatSummary> rest = all
        .where((ChatSummary chat) => !chat.pinned)
        .toList();

    return SafeArea(
      bottom: false,
      child: Stack(
        children: <Widget>[
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await store.refreshChats();
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                },
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ChatsHeader(
                  controller: _search,
                  focusNode: _searchFocus,
                  query: _query,
                  onChanged: (String value) => setState(() => _query = value),
                  colors: colors,
                  connection: store.connection,
                  onCompose: _newChat,
                ),
              ),
              if (store.stories.isNotEmpty)
                SliverToBoxAdapter(
                  child: StoriesRow(
                    stories: store.stories,
                    onOpen: (StoryCircle story) => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (BuildContext _) =>
                            ChatScreen(chatId: story.chatId),
                      ),
                    ),
                  ),
                ),
              if (all.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 90),
                    child: EmptyState(
                      icon: store.chats.isEmpty
                          ? Icons.chat_bubble_outline
                          : Icons.search_off,
                      title: store.chats.isEmpty
                          ? 'No chats yet'
                          : 'No results',
                      message: store.chats.isEmpty
                          ? (store.connection == 'Connected'
                                ? 'Start a conversation from Contacts or tap the '
                                      'compose button. Chats appear here as TDLib '
                                      'syncs them.'
                                : 'Telegram is connecting. Pull down to retry.')
                          : 'Try a different name or message.',
                    ),
                  ),
                ),
              if (pinned.isNotEmpty) ...<Widget>[
                SliverToBoxAdapter(child: SectionLabel('Pinned')),
                SliverList.builder(
                  itemCount: pinned.length,
                  itemBuilder: (BuildContext context, int index) =>
                      ChatRow(chat: pinned[index]),
                ),
              ],
              if (rest.isNotEmpty) ...<Widget>[
                SliverToBoxAdapter(
                  child: SectionLabel(_query.isEmpty ? 'All chats' : 'Results'),
                ),
                SliverList.builder(
                  itemCount: rest.length,
                  itemBuilder: (BuildContext context, int index) =>
                      ChatRow(chat: rest[index]),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
                  child: Text(
                    store.chats.isEmpty
                        ? ''
                        : '${store.chats.length} chats · '
                              '${store.totalUnread} unread',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 96,
            child: FloatingComposeButton(onTap: _newChat),
          ),
        ],
      ),
    );
  }
}

/// Telegram-iOS chats header: the 34 pt title collapses into a centred nav-bar
/// title over real glass while the search field stays put.
class _ChatsHeader extends SliverPersistentHeaderDelegate {
  _ChatsHeader({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.colors,
    required this.connection,
    required this.onCompose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final AppColors colors;
  final String connection;
  final VoidCallback onCompose;

  static const double _collapsed = 104;
  static const double _expanded = 152;

  @override
  double get minExtent => _collapsed;

  @override
  double get maxExtent => _expanded;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double t = (shrinkOffset / (_expanded - _collapsed)).clamp(0.0, 1.0);
    final bool online = connection == 'Connected' || connection == 'Updating';
    return ClipRect(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GlassSurface(
              radius: 0,
              dark: colors.dark,
              // Fixed, not interpolated with the scroll offset: changing the
              // tint or materialisation every frame re-runs the shader and
              // re-rasterises the whole pinned header while you scroll. Only
              // the title cross-fade animates now.
              tintAmount: 46,
              light: const Offset(0, -1),
              materialize: 0.8,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 18,
            right: 12,
            top: 6,
            height: 46,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      Opacity(
                        opacity: (1 - t * 1.3).clamp(0.0, 1.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Chats',
                              style: AppText.largeTitle.copyWith(
                                color: colors.textPrimary,
                                fontSize: 34 - 3 * t,
                              ),
                            ),
                            if (!online) ...<Widget>[
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: connection.contains('network')
                                      ? colors.danger
                                      : colors.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: t,
                          child: Text(
                            'Chats',
                            style: AppText.title.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                NavIconButton(
                  icon: Icons.search,
                  size: 21,
                  tooltip: 'Search',
                  onTap: () => focusNode.requestFocus(),
                ),
                NavIconButton(
                  icon: Icons.edit_outlined,
                  size: 21,
                  tooltip: 'New message',
                  onTap: onCompose,
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 11,
            height: 40,
            child: IosSearchField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Search for messages or users',
              onChanged: onChanged,
              trailing: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: Icon(
                        Icons.close,
                        size: 17,
                        color: colors.textSecondary,
                      ),
                    ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 0.6, color: colors.separator),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ChatsHeader oldDelegate) =>
      oldDelegate.query != query ||
      oldDelegate.colors.dark != colors.dark ||
      oldDelegate.connection != connection ||
      oldDelegate.controller != controller;
}

class FloatingComposeButton extends StatelessWidget {
  const FloatingComposeButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        Haptics.medium();
        onTap();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: <Color>[colors.accent, colors.accentDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.edit, color: Colors.white, size: 22),
      ),
    );
  }
}
