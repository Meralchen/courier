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
import '../components/pressable.dart';
import '../components/sheets.dart';
import 'archive_screen.dart';
import 'chat_row.dart';
import 'new_chat_screen.dart';
import 'stories_row.dart';

/// The chat-list filter chips iOS shows under the search field.
enum ChatFilter { all, unread, groups, private }

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  ChatFilter _filter = ChatFilter.all;
  int? _folderId;
  bool _editing = false;
  final Set<int> _selected = <int>{};

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  static bool _isGroup(ChatSummary chat) => chat.isGroup || !chat.isPrivate;

  List<ChatSummary> _visible(List<ChatSummary> source) {
    final List<ChatSummary> filtered = switch (_filter) {
      ChatFilter.all => source,
      ChatFilter.unread =>
        source.where((ChatSummary chat) => chat.unread > 0).toList(),
      ChatFilter.groups => source.where(_isGroup).toList(),
      ChatFilter.private =>
        source.where((ChatSummary chat) => chat.isPrivate).toList(),
    };
    final List<ChatSummary> scoped = _folderId == null
        ? filtered
        : filtered
              .where((ChatSummary chat) => chat.folders.contains(_folderId))
              .toList();
    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return scoped;
    return scoped
        .where(
          (ChatSummary chat) =>
              chat.title.toLowerCase().contains(needle) ||
              chat.preview.toLowerCase().contains(needle),
        )
        .toList();
  }

  void _selectFolder(int? folderId) {
    setState(() => _folderId = folderId);
    if (folderId != null) {
      TelegramScope.read(context).openFolder(folderId);
    }
  }

  void _toggleEdit() {
    setState(() {
      _editing = !_editing;
      _selected.clear();
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  Future<void> _deleteSelected(TelegramStore store) async {
    if (_selected.isEmpty) return;
    final bool confirmed = await showGlassConfirm(
      context,
      title:
          'Delete ${_selected.length} chat'
          '${_selected.length == 1 ? '' : 's'}?',
      message: 'The chats and their history will be removed for you.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    final List<int> ids = _selected.toList();
    for (final int id in ids) {
      await store.deleteChat(id);
    }
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _editing = false;
    });
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

  Widget _row(ChatSummary chat) {
    return ChatRow(
      chat: chat,
      selecting: _editing,
      selected: _selected.contains(chat.id),
      onTap: _editing ? () => _toggleSelect(chat.id) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TelegramStore store = TelegramScope.read(context);
    return StoreSelector<Object>(
      select: (TelegramStore store) =>
          '${store.chatsVersion}|${store.storiesVersion}|'
          '${store.totalUnread}|${store.connection}|${store.foldersVersion}',
      builder: (BuildContext context, Object _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, TelegramStore store) {
    final AppColors colors = AppColors.of(context);
    final List<ChatSummary> chats = store.chats;
    final List<ChatSummary> all = _visible(chats);

    final int unreadCount = chats
        .where((ChatSummary chat) => chat.unread > 0)
        .length;
    final int groupCount = chats.where(_isGroup).length;
    final int privateCount = chats
        .where((ChatSummary chat) => chat.isPrivate)
        .length;

    final String emptyTitle = _query.trim().isNotEmpty
        ? 'No results'
        : _folderId != null
        ? 'This folder is empty'
        : switch (_filter) {
            ChatFilter.all => 'No chats yet',
            ChatFilter.unread => 'Nothing unread',
            ChatFilter.groups => 'No groups yet',
            ChatFilter.private => 'No private chats yet',
          };

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
                  filter: _filter,
                  onFilter: (ChatFilter value) =>
                      setState(() => _filter = value),
                  folders: store.folders,
                  folderId: _folderId,
                  onFolder: _selectFolder,
                  unreadCount: unreadCount,
                  groupCount: groupCount,
                  privateCount: privateCount,
                  editing: _editing,
                  onEdit: _toggleEdit,
                  onCompose: _newChat,
                ),
              ),
              if (store.stories.isNotEmpty && !_editing)
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
              if (store.archivedChats.isNotEmpty && !_editing)
                SliverToBoxAdapter(
                  child: _ArchiveRow(
                    unread: store.archivedUnread,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => const ArchiveScreen(),
                      ),
                    ),
                  ),
                ),
              if (all.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: EmptyState(
                      icon: chats.isEmpty
                          ? Icons.chat_bubble_outline
                          : Icons.search_off,
                      title: emptyTitle,
                      message: chats.isEmpty
                          ? (store.connection == 'Connected'
                                ? 'Start a conversation from Contacts or tap the '
                                      'compose button. Chats appear here as TDLib '
                                      'syncs them.'
                                : 'Telegram is connecting. Pull down to retry.')
                          : 'Try another filter or search term.',
                    ),
                  ),
                ),
              // iOS draws pinned and ordinary chats as one continuous list,
              // with no section headers or footer, so nothing overlaps a row.
              SliverList.builder(
                itemCount: all.length,
                itemBuilder: (BuildContext context, int index) =>
                    _row(all[index]),
              ),
              // Clears the floating tab bar so the last chat stays reachable.
              const SliverToBoxAdapter(child: SizedBox(height: 118)),
            ],
          ),
          if (_editing)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: _EditBar(
                count: _selected.length,
                onDelete: _selected.isEmpty
                    ? null
                    : () => _deleteSelected(store),
                onDone: _toggleEdit,
              ),
            ),
        ],
      ),
    );
  }
}

class _EditBar extends StatelessWidget {
  const _EditBar({
    required this.count,
    required this.onDelete,
    required this.onDone,
  });

  final int count;
  final VoidCallback? onDelete;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              count == 0 ? 'Select chats' : '$count selected',
              style: AppText.subhead.copyWith(color: colors.textPrimary),
            ),
          ),
          Pressable(
            onTap: onDelete,
            child: Text(
              'Delete',
              style: AppText.subhead.copyWith(
                color: onDelete == null ? colors.textTertiary : colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Pressable(
            onTap: onDone,
            child: Text(
              'Done',
              style: AppText.subhead.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Telegram-iOS chats bar: grey Edit pill, centred title, compose on the right,
/// the search field under it and the filter chips under that.
class _ChatsHeader extends SliverPersistentHeaderDelegate {
  _ChatsHeader({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.colors,
    required this.filter,
    required this.onFilter,
    required this.unreadCount,
    required this.groupCount,
    required this.privateCount,
    required this.editing,
    required this.onEdit,
    required this.onCompose,
    required this.folders,
    required this.folderId,
    required this.onFolder,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final AppColors colors;
  final ChatFilter filter;
  final ValueChanged<ChatFilter> onFilter;
  final int unreadCount;
  final int groupCount;
  final int privateCount;
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onCompose;
  final List<ChatFolder> folders;
  final int? folderId;
  final ValueChanged<int?> onFolder;

  static const double _height = 136;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GlassSurface(
              radius: 0,
              dark: colors.dark,
              tintAmount: 46,
              light: const Offset(0, -1),
              materialize: 0.8,
              child: const SizedBox.expand(),
            ),
          ),
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 6, 0),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: <Widget>[
                      NavPill(label: editing ? 'Done' : 'Edit', onTap: onEdit),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Chats',
                            style: AppText.title.copyWith(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
                child: SizedBox(
                  height: 40,
                  child: IosSearchField(
                    controller: controller,
                    focusNode: focusNode,
                    hint: 'Search',
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
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: <Widget>[
                    // Accounts with folders get the folder tabs iOS shows
                    // instead of the fixed filters; the Edit chip ends the row.
                    if (folders.isEmpty) ...<Widget>[
                      _FilterChip(
                        label: 'All',
                        selected: filter == ChatFilter.all,
                        onTap: () => onFilter(ChatFilter.all),
                        colors: colors,
                      ),
                      _FilterChip(
                        label: 'Unread',
                        count: unreadCount,
                        selected: filter == ChatFilter.unread,
                        onTap: () => onFilter(ChatFilter.unread),
                        colors: colors,
                      ),
                      _FilterChip(
                        label: 'Groups',
                        count: groupCount,
                        selected: filter == ChatFilter.groups,
                        onTap: () => onFilter(ChatFilter.groups),
                        colors: colors,
                      ),
                      _FilterChip(
                        label: 'Private',
                        count: privateCount,
                        selected: filter == ChatFilter.private,
                        onTap: () => onFilter(ChatFilter.private),
                        colors: colors,
                      ),
                    ] else ...<Widget>[
                      _FilterChip(
                        label: 'All',
                        selected: folderId == null,
                        onTap: () => onFolder(null),
                        colors: colors,
                      ),
                      for (final ChatFolder folder in folders)
                        _FilterChip(
                          label: folder.title,
                          selected: folderId == folder.id,
                          onTap: () => onFolder(folder.id),
                          colors: colors,
                        ),
                      _FilterChip(
                        label: 'Edit',
                        selected: false,
                        onTap: onEdit,
                        colors: colors,
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
      oldDelegate.filter != filter ||
      oldDelegate.editing != editing ||
      oldDelegate.unreadCount != unreadCount ||
      oldDelegate.groupCount != groupCount ||
      oldDelegate.privateCount != privateCount ||
      oldDelegate.colors.dark != colors.dark ||
      oldDelegate.controller != controller ||
      oldDelegate.folderId != folderId ||
      oldDelegate.folders.length != folders.length;
}

/// iOS puts the archive at the top of the list: a grey rounded square with an
/// archive box, the title, the unread total and a chevron.
class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: Icon(
                    Icons.archive_outlined,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Archived Chats',
                    style: AppText.title.copyWith(
                      color: colors.textPrimary,
                      fontSize: 16.5,
                    ),
                  ),
                ),
                if (unread > 0) ...<Widget>[
                  Container(
                    constraints: const BoxConstraints(minWidth: 21),
                    height: 21,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      unread > 999 ? '999+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
              ],
            ),
          ),
          const Hairline(indent: 79),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
    this.count = 0,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (colors.dark
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          boxShadow: selected && !colors.dark
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            if (count > 0) ...<Widget>[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
