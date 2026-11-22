import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../chat/chat_screen.dart';
import '../chats/new_chat_screen.dart';
import '../components/avatar.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

/// Telegram-iOS contacts: a Sort pill on the left, centred title, add on the
/// right, search under the bar, then either an A–Z list or the recent-activity
/// order the screenshot shows.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _byName = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    final int? chatId = await Navigator.of(context).push<int>(
      CupertinoPageRoute<int>(
        builder: (BuildContext _) => const NewChatScreen(),
      ),
    );
    if (chatId != null && mounted) {
      await Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (BuildContext _) => ChatScreen(chatId: chatId),
        ),
      );
    }
  }

  void _open(ChatSummary chat) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext _) => ChatScreen(chatId: chat.id),
      ),
    );
  }

  Widget _personRow(ChatSummary chat, AppColors colors) {
    return Pressable(
      onTap: () => _open(chat),
      scale: 0.99,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
            child: Row(
              children: <Widget>[
                Avatar(
                  title: chat.title,
                  seed: chat.id,
                  size: 46,
                  photoFileId: chat.photoFileId,
                  photoPath: chat.photoPath,
                  online: chat.online,
                  showOnline: chat.online,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        chat.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(color: colors.textPrimary),
                      ),
                      Text(
                        chat.online
                            ? 'online'
                            : chat.lastSeen > 0
                            ? 'last seen ${lastSeenLabel(chat.lastSeen)}'
                            : 'on Telegram',
                        style: AppText.caption.copyWith(
                          color: chat.online
                              ? colors.success
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
              ],
            ),
          ),
          const Hairline(indent: 74),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TelegramStore store = TelegramScope.read(context);
    return StoreSelector<int>(
      select: (TelegramStore store) => store.chatsVersion,
      builder: (BuildContext context, int _) => _build(context, store),
    );
  }

  Widget _build(BuildContext context, TelegramStore store) {
    final AppColors colors = AppColors.of(context);
    final String needle = _query.trim().toLowerCase();
    final List<ChatSummary> people = store.contacts
        .where(
          (ChatSummary chat) =>
              needle.isEmpty || chat.title.toLowerCase().contains(needle),
        )
        .toList();

    if (!_byName) {
      people.sort(
        (ChatSummary a, ChatSummary b) => b.lastSeen.compareTo(a.lastSeen),
      );
    }

    final Map<String, List<ChatSummary>> sections =
        <String, List<ChatSummary>>{};
    for (final ChatSummary person in people) {
      final String first = person.title.trim().isEmpty
          ? '#'
          : person.title.trim()[0].toUpperCase();
      final String letter = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
      sections.putIfAbsent(letter, () => <ChatSummary>[]).add(person);
    }
    final List<String> letters = sections.keys.toList()
      ..sort((String a, String b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 6, 0),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: <Widget>[
                    NavPill(
                      label: 'Sort',
                      onTap: () => setState(() => _byName = !_byName),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Contacts',
                          style: AppText.title.copyWith(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    NavIconButton(
                      icon: Icons.person_add_alt_1_outlined,
                      tooltip: 'New message',
                      onTap: _compose,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
              child: IosSearchField(
                controller: _search,
                hint: 'Search',
                onChanged: (String value) => setState(() => _query = value),
              ),
            ),
          ),
          if (people.isNotEmpty)
            SliverToBoxAdapter(
              child: SectionLabel(
                _byName ? 'Sorted by name' : 'Sorted by last seen',
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 5),
              ),
            ),
          if (people.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: needle.isEmpty ? 'No contacts yet' : 'No results',
                  message: needle.isEmpty
                      ? 'People you chat with appear here. Start a new '
                            'conversation with anyone on Telegram by username.'
                      : 'Try another name.',
                  actionLabel: needle.isEmpty ? 'New message' : null,
                  onAction: _compose,
                ),
              ),
            )
          else if (_byName)
            for (final String letter in letters) ...<Widget>[
              SliverToBoxAdapter(child: SectionLabel(letter)),
              SliverList.builder(
                itemCount: sections[letter]!.length,
                itemBuilder: (BuildContext context, int index) =>
                    _personRow(sections[letter]![index], colors),
              ),
            ]
          else
            SliverList.builder(
              itemCount: people.length,
              itemBuilder: (BuildContext context, int index) =>
                  _personRow(people[index], colors),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 130)),
        ],
      ),
    );
  }
}
