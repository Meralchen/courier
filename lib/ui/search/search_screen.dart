import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../chats/chat_row.dart';
import '../components/ios_ui.dart';

/// Global search behind the tab bar's magnifier. It searches the synced chat
/// list locally (title and last-message preview), so it works offline and on
/// accounts where server-side message search is unavailable.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TelegramStore store = TelegramScope.of(context);
    final String needle = _query.trim().toLowerCase();
    final List<ChatSummary> results = needle.isEmpty
        ? const <ChatSummary>[]
        : store.chats
              .where(
                (ChatSummary chat) =>
                    chat.title.toLowerCase().contains(needle) ||
                    chat.preview.toLowerCase().contains(needle),
              )
              .toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: IosSearchField(
                      controller: _controller,
                      focusNode: _focus,
                      hint: 'Search',
                      onChanged: (String value) =>
                          setState(() => _query = value),
                      trailing: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                              icon: Icon(
                                Icons.close,
                                size: 17,
                                color: colors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  NavIconButton(
                    icon: Icons.close,
                    tooltip: 'Close search',
                    color: colors.textSecondary,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: needle.isEmpty
                  ? const EmptyState(
                      icon: Icons.search,
                      title: 'Search',
                      message: 'Find a chat by name or by its last message.',
                    )
                  : results.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: 'No results',
                      message: 'Nothing matches “${_query.trim()}”.',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: results.length,
                      itemBuilder: (BuildContext context, int index) =>
                          ChatRow(chat: results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
