import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../chats/chat_row.dart';
import '../components/ios_ui.dart';

/// Settings → Chat Folders. The folder definitions come from TDLib's
/// `UpdateChatFolders`; creating or editing them is a Telegram-side operation,
/// so this screen lists and opens the folders the account already has.
class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final List<ChatFolder> folders = store.folders;
    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        backgroundColor: colors.groupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chat Folders'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
        children: <Widget>[
          if (folders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 120),
              child: EmptyState(
                icon: Icons.folder_outlined,
                title: 'No folders yet',
                message:
                    'Folders you create in Telegram appear here and as tabs '
                    'above the chat list.',
              ),
            )
          else
            SettingsGroup(
              children: <Widget>[
                for (final ChatFolder folder in folders)
                  SettingsRow(
                    label: folder.title,
                    subtitle:
                        '${store.chats.where((ChatSummary chat) => chat.folders.contains(folder.id)).length} '
                        'chats',
                    icon: Icons.folder_outlined,
                    iconColor: colors.accent,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) =>
                            FolderChatsScreen(folder: folder),
                      ),
                    ),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: Text(
              'Folders are stored on your Telegram account with TDLib\'s '
              'folder lists. Courier shows every folder your account has and '
              'keeps the chat list tabs in sync as TDLib reports changes.',
              style: AppText.caption.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// The chats one folder contains, loaded through TDLib's `ChatListFolder`.
class FolderChatsScreen extends StatefulWidget {
  const FolderChatsScreen({super.key, required this.folder});

  final ChatFolder folder;

  @override
  State<FolderChatsScreen> createState() => _FolderChatsScreenState();
}

class _FolderChatsScreenState extends State<FolderChatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TelegramScope.read(context).openFolder(widget.folder.id);
    });
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
        title: Text(widget.folder.title),
      ),
      body: StoreSelector<Object>(
        select: (TelegramStore store) =>
            '${store.chatsVersion}|${store.filesVersion}',
        builder: (BuildContext context, Object _) {
          final List<ChatSummary> chats = store.chats
              .where(
                (ChatSummary chat) => chat.folders.contains(widget.folder.id),
              )
              .toList();
          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'This folder is empty',
              message:
                  'Chats TDLib includes in this folder appear here once they '
                  'are synced.',
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 30),
            itemCount: chats.length,
            itemBuilder: (BuildContext context, int index) =>
                ChatRow(chat: chats[index]),
          );
        },
      ),
    );
  }
}
