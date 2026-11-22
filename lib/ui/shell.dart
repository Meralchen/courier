import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../state/app_settings.dart';
import '../state/scopes.dart';
import '../telegram/telegram_store.dart';
import 'calls/calls_screen.dart';
import 'chats/chat_list_screen.dart';
import 'components/glass.dart';
import 'contacts/contacts_screen.dart';
import 'search/search_screen.dart';
import 'settings/settings_screen.dart';
import 'shell_scope.dart';
import 'tab_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _tab = 2;
  bool _showingError = false;
  TelegramStore? _store;

  void goToTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TelegramStore store = TelegramScope.read(context);
    if (identical(store, _store)) return;
    _store?.removeListener(_onStoreChanged);
    _store = store..addListener(_onStoreChanged);
    _onStoreChanged();
  }

  void _onStoreChanged() {
    final TelegramStore? store = _store;
    if (store == null || !mounted) return;
    _showPendingError(store);
  }

  @override
  void dispose() {
    _store?.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _openSearch() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext _) => const SearchScreen(),
      ),
    );
  }

  void _showPendingError(TelegramStore store) {
    final String? error = store.lastError;
    if (error == null || _showingError) return;
    _showingError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      store.takeError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error),
          duration: const Duration(seconds: 4),
        ),
      );
      _showingError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool classic =
        SettingsScope.of(context).glassStyle == GlassStyle.classic;

    return Scaffold(
      backgroundColor: colors.background,
      extendBody: true,
      body: ShellScope(
        goToTab: goToTab,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              // Classic iOS has no colour field behind the app; the grouping
              // background is the whole story.
              child: classic
                  ? ColoredBox(color: colors.background)
                  : LiquidWallpaper(
                      base: colors.chatBackdrop,
                      dark: colors.dark,
                      intensity: 0.75,
                    ),
            ),
            Positioned.fill(
              child: IndexedStack(
                index: _tab,
                children: <Widget>[
                  const ContactsScreen(),
                  const CallsScreen(),
                  const ChatListScreen(),
                  // Settings is a grouped list, not a glass stage: iOS paints it
                  // on a solid grouped background with opaque cards.
                  ColoredBox(
                    color: colors.groupedBackground,
                    child: const SettingsScreen(),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: StoreSelector<int>(
                select: (TelegramStore store) => store.totalUnread,
                builder: (BuildContext context, int unread) => CourierTabBar(
                  selected: _tab,
                  unread: unread,
                  onSelect: goToTab,
                  onSearch: _openSearch,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
