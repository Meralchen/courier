import 'package:courier/state/scopes.dart';
import 'package:courier/telegram/telegram_store.dart';
import 'package:courier/ui/chat/sticker_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('the sticker panel offers emoji when no sets are installed', (
    WidgetTester tester,
  ) async {
    final TelegramStore store = TelegramStore();
    String typed = '';
    await tester.pumpWidget(
      TelegramScope(
        store: store,
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showStickerPanel(
                    context,
                    store: store,
                    onSticker: (_) {},
                    onEmoji: (String emoji) => typed += emoji,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // No sets come back from the (absent) platform channel, so the panel must
    // explain itself rather than render an empty grid.
    expect(find.textContaining('No stickers yet'), findsOneWidget);

    await tester.tap(find.text('Emoji'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😀'));
    expect(typed, '😀');
  });
}
