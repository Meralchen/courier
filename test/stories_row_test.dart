import 'package:courier/state/scopes.dart';
import 'package:courier/telegram/models.dart';
import 'package:courier/telegram/telegram_store.dart';
import 'package:courier/ui/chats/stories_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('story circles carry unread state and open their chat', (
    WidgetTester tester,
  ) async {
    StoryCircle? opened;
    await tester.pumpWidget(
      // Avatar reads cached photo paths from the store, so the scope is needed
      // even though these circles have no photo.
      TelegramScope(
        store: TelegramStore(),
        child: MaterialApp(
          home: Scaffold(
            body: StoriesRow(
              stories: const <StoryCircle>[
                StoryCircle(
                  chatId: 1,
                  title: 'Emma Stone',
                  count: 2,
                  unread: true,
                ),
                StoryCircle(chatId: 2, title: 'Liam', count: 1),
              ],
              onOpen: (StoryCircle story) => opened = story,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(StoryRing), findsNWidgets(2));
    expect(
      tester.widget<StoryRing>(find.byType(StoryRing).first).unread,
      isTrue,
    );
    expect(
      tester.widget<StoryRing>(find.byType(StoryRing).last).unread,
      isFalse,
    );

    // iOS labels the circle with the first name only.
    expect(find.text('Emma'), findsOneWidget);
    expect(find.text('Liam'), findsOneWidget);

    await tester.tap(find.text('Emma'));
    expect(opened?.chatId, 1);
  });
}
