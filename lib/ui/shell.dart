import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/scopes.dart';
import '../telegram/telegram_store.dart';
import 'calls/calls_screen.dart';
import 'chats/chat_list_screen.dart';
import 'components/glass.dart';
import 'contacts/contacts_screen.dart';
import 'settings/settings_screen.dart';
import 'tab_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _tab = 2;
  bool _showingError = false;

  void goToTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
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
    final TelegramStore store = TelegramScope.of(context);
    _showPendingError(store);

    return Scaffold(
      backgroundColor: colors.background,
      extendBody: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LiquidWallpaper(
              base: colors.chatBackdrop,
              dark: colors.dark,
              intensity: 0.75,
            ),
          ),
          Positioned.fill(
            child: IndexedStack(
              index: _tab,
              children: const <Widget>[
                ContactsScreen(),
                CallsScreen(),
                ChatListScreen(),
                SettingsScreen(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CourierTabBar(
              selected: _tab,
              unread: store.totalUnread,
              onSelect: goToTab,
            ),
          ),
        ],
      ),
    );
  }
}
