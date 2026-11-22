import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../chat/chat_screen.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import 'chat_row.dart';
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
        .where((ChatSummary chat) =>
            chat.title.toLowerCase().contains(needle) ||
            chat.preview.toLowerCase().contains(needle))
        .toList();
  }

  Future<void> _newChat() async {
    final int? chatId = await Navigator.of(context).push<int>(
      CupertinoPageRoute<int>(builder: (BuildContext _) => const NewChatScreen()),
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
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final List<ChatSummary> all = _filtered(store.chats);
    final List<ChatSummary> pinned =
        all.where((ChatSummary chat) => chat.pinned).toList();
    final List<ChatSummary> rest =
        all.where((ChatSummary chat) => !chat.pinned).toList();

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
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LargeTitle(
                      'Chats',
                      trailing: Row(
                        children: <Widget>[
                          GlassCircleButton(
                            icon: Icons.search,
                            tooltip: 'Search',
                            onTap: () => _searchFocus.requestFocus(),
                          ),
                          const SizedBox(width: 8),
                          GlassCircleButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'New message',
                            color: colors.accent,
                            onTap: _newChat,
                          ),
                        ],
                      ),
                    ),
                    if (store.connection != 'Connected')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: store.connection.contains('network')
                                    ? colors.danger
                                    : colors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              store.connection,
                              style: AppText.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchHeader(
                  controller: _search,
                  focusNode: _searchFocus,
                  query: _query,
                  onChanged: (String value) => setState(() => _query = value),
                  colors: colors,
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
                      title: store.chats.isEmpty ? 'No chats yet' : 'No results',
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
                  child: SectionLabel(
                    _query.isEmpty ? 'All chats' : 'Results',
                  ),
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

class _SearchHeader extends SliverPersistentHeaderDelegate {
  _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.colors,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final AppColors colors;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: GlassField(
        controller: controller,
        focusNode: focusNode,
        hint: 'Search for messages or users',
        icon: Icons.search,
        onChanged: onChanged,
        suffix: query.isEmpty
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
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeader oldDelegate) =>
      oldDelegate.query != query ||
      oldDelegate.colors.dark != colors.dark ||
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
