import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/avatar.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _query = TextEditingController();
  String _value = '';
  bool _opening = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _openUsername() async {
    final String username = _value.trim();
    if (username.isEmpty || _opening) return;
    setState(() => _opening = true);
    final int? chatId = await TelegramScope.read(context).openUsername(username);
    if (!mounted) return;
    setState(() => _opening = false);
    if (chatId != null) Navigator.of(context).pop(chatId);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final String needle = _value.trim().toLowerCase();
    final List<ChatSummary> contacts = store.contacts
        .where((ChatSummary chat) =>
            needle.isEmpty || chat.title.toLowerCase().contains(needle))
        .toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LiquidWallpaper(base: colors.chatBackdrop, dark: colors.dark),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 14, 6),
                  child: Row(
                    children: <Widget>[
                      GlassCircleButton(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'New message',
                          style: AppText.headline.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                  child: GlassField(
                    controller: _query,
                    hint: 'Name or @username',
                    icon: Icons.search,
                    autofocus: true,
                    onChanged: (String value) => setState(() => _value = value),
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _openUsername(),
                  ),
                ),
                if (_value.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Pressable(
                      onTap: _openUsername,
                      child: GlassCard(
                        padding: const EdgeInsets.all(13),
                        radius: 16,
                        child: Row(
                          children: <Widget>[
                            if (_opening)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(Icons.alternate_email, color: colors.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Open @${_value.trim().replaceAll('@', '')}',
                                    style: AppText.body.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Search Telegram for this username',
                                    style: AppText.caption.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: colors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SectionLabel(
                  needle.isEmpty ? 'People you know' : 'Results',
                  padding: const EdgeInsets.fromLTRB(22, 16, 20, 6),
                ),
                Expanded(
                  child: contacts.isEmpty
                      ? EmptyState(
                          icon: Icons.person_search_outlined,
                          title: 'No people yet',
                          message: 'Type a @username above to start a '
                              'conversation with anyone on Telegram. Your recent '
                              'chats appear here too.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 30),
                          itemCount: contacts.length,
                          separatorBuilder: (BuildContext _, int __) =>
                              const Hairline(indent: 74),
                          itemBuilder: (BuildContext context, int index) {
                            final ChatSummary chat = contacts[index];
                            return Pressable(
                              onTap: () => Navigator.of(context).pop(chat.id),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                                      child: Text(
                                        chat.title,
                                        style: AppText.body.copyWith(
                                          color: colors.textPrimary,
                                        ),
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
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
