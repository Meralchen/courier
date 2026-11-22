import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/avatar.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

/// iOS "Forward to" picker: search the chat list, tap a target, and TDLib's
/// `ForwardMessages` copies the selected messages into it.
class ForwardScreen extends StatefulWidget {
  const ForwardScreen({
    super.key,
    required this.fromChatId,
    required this.messageIds,
  });

  final int fromChatId;
  final List<int> messageIds;

  @override
  State<ForwardScreen> createState() => _ForwardScreenState();
}

class _ForwardScreenState extends State<ForwardScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _sending = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _forwardTo(int chatId) async {
    if (_sending) return;
    setState(() => _sending = true);
    final TelegramStore store = TelegramScope.read(context);
    await store.forward(widget.fromChatId, widget.messageIds, chatId);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.read(context);
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        backgroundColor: colors.groupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Forward to'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: IosSearchField(
              controller: _search,
              hint: 'Search',
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: StoreSelector<Object>(
              select: (TelegramStore store) => store.chatsVersion,
              builder: (BuildContext context, Object _) {
                final String needle = _query.trim().toLowerCase();
                final List<ChatSummary> chats = store.chats
                    .where(
                      (ChatSummary chat) =>
                          needle.isEmpty ||
                          chat.title.toLowerCase().contains(needle),
                    )
                    .toList();
                if (chats.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No chats found',
                    message: 'Try another name.',
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 30),
                  itemCount: chats.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChatSummary chat = chats[index];
                    return Pressable(
                      onTap: _sending ? null : () => _forwardTo(chat.id),
                      scale: 0.99,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                            child: Row(
                              children: <Widget>[
                                Avatar(
                                  title: chat.title,
                                  seed: chat.id,
                                  size: 46,
                                  photoFileId: chat.photoFileId,
                                  photoPath: chat.photoPath,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    chat.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.title.copyWith(
                                      fontSize: 16.5,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (chat.isGroup || !chat.isPrivate)
                                  Icon(
                                    Icons.groups_outlined,
                                    size: 18,
                                    color: colors.textTertiary,
                                  ),
                              ],
                            ),
                          ),
                          const Hairline(indent: 72),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
