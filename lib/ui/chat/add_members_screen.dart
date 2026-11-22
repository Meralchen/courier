import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/avatar.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

/// The member picker iOS shows from a group's info page. Only people who are
/// not already in the group are listed, so Add never fails on a duplicate.
class AddMembersScreen extends StatefulWidget {
  const AddMembersScreen({super.key, required this.chatId});

  final int chatId;

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final Set<int> _selected = <int>{};
  bool _busy = false;

  Future<void> _add() async {
    if (_selected.isEmpty || _busy) return;
    setState(() => _busy = true);
    final TelegramStore store = TelegramScope.read(context);
    try {
      await store.addMembers(widget.chatId, _selected.toList());
      await store.loadChatInfo(widget.chatId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    final Set<int> existing = <int>{
      for (final ChatMemberInfo member
          in store.infoFor(widget.chatId)?.members ?? const <ChatMemberInfo>[])
        member.userId,
    };
    final List<ChatSummary> contacts = store.contacts
        .where((ChatSummary chat) => !existing.contains(chat.userId))
        .toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 14, 8),
              child: Row(
                children: <Widget>[
                  GlassCircleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selected.isEmpty
                          ? 'Add Members'
                          : 'Add Members · ${_selected.length}',
                      style: AppText.headline.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: _selected.isEmpty || _busy ? null : _add,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _selected.isEmpty
                            ? colors.textSecondary.withValues(alpha: 0.16)
                            : colors.accent,
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
                              'Add',
                              style: AppText.subhead.copyWith(
                                color: _selected.isEmpty
                                    ? colors.textSecondary
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('Contacts'),
            Expanded(
              child: contacts.isEmpty
                  ? const EmptyState(
                      icon: Icons.group_add_outlined,
                      title: 'Everyone is already here',
                      message:
                          'All of your contacts are members of this group.',
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 30),
                      itemCount: contacts.length,
                      separatorBuilder: (BuildContext _, int __) =>
                          const Hairline(indent: 74),
                      itemBuilder: (BuildContext context, int index) {
                        final ChatSummary chat = contacts[index];
                        final bool selected = _selected.contains(chat.userId);
                        return Pressable(
                          onTap: () => setState(() {
                            if (selected) {
                              _selected.remove(chat.userId);
                            } else {
                              _selected.add(chat.userId);
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
        ),
      ),
    );
  }
}
