import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/avatar.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

/// iOS "New Group" / "New Channel": a name field, and for groups a member
/// picker built from the people already in the account. The chat is created
/// on TDLib and returned to the caller so the conversation opens immediately.
class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key, required this.channel});

  final bool channel;

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final TextEditingController _title = TextEditingController();
  final Set<int> _selected = <int>{};
  bool _busy = false;

  bool get _canCreate => _title.text.trim().isNotEmpty && !_busy;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final String title = _title.text.trim();
    if (title.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final int id = await TelegramScope.read(context).createChat(
        title: title,
        isChannel: widget.channel,
        userIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final List<ChatSummary> contacts = store.contacts;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LiquidWallpaper(
              base: colors.chatBackdrop,
              dark: colors.dark,
            ),
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
                          widget.channel ? 'New Channel' : 'New Group',
                          style: AppText.headline.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: _canCreate ? _create : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _canCreate
                                ? colors.accent
                                : colors.textSecondary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Create',
                                  style: AppText.subhead.copyWith(
                                    color: _canCreate
                                        ? Colors.white
                                        : colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                  child: GlassField(
                    controller: _title,
                    hint: widget.channel ? 'Channel name' : 'Group name',
                    icon: widget.channel
                        ? Icons.campaign_outlined
                        : Icons.groups_2_outlined,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (String _) => setState(() {}),
                    onSubmitted: (String _) => _create(),
                  ),
                ),
                if (widget.channel)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 12, 26, 0),
                    child: Text(
                      'Channels are for broadcasting to an unlimited audience. '
                      'You can add a description and invite people once the '
                      'channel exists.',
                      style: AppText.subhead.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                else ...<Widget>[
                  SectionLabel(
                    _selected.isEmpty
                        ? 'Add Members'
                        : 'Add Members · ${_selected.length} selected',
                  ),
                  Expanded(
                    child: contacts.isEmpty
                        ? const EmptyState(
                            icon: Icons.person_add_alt_1_outlined,
                            title: 'No contacts yet',
                            message:
                                'Start a chat with someone first, then '
                                'they appear here to add to a group.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 30),
                            physics: const BouncingScrollPhysics(),
                            itemCount: contacts.length,
                            separatorBuilder: (BuildContext _, int __) =>
                                const Hairline(indent: 74),
                            itemBuilder: (BuildContext context, int index) {
                              final ChatSummary chat = contacts[index];
                              final bool selected = _selected.contains(
                                chat.userId,
                              );
                              return Pressable(
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selected.remove(chat.userId);
                                  } else {
                                    _selected.add(chat.userId);
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    8,
                                  ),
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.body.copyWith(
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? colors.accent
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: selected
                                                ? colors.accent
                                                : colors.textTertiary,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: selected
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
