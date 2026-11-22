import 'package:courier/ui/tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<List<int>> pumpBar(WidgetTester tester) async {
    final List<int> selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: CourierTabBar(
                selected: 2,
                unread: 3,
                onSelect: selections.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return selections;
  }

  testWidgets('tapping a tab selects it', (WidgetTester tester) async {
    final List<int> selections = await pumpBar(tester);
    final Rect rect = tester.getRect(find.byType(CourierTabBar));

    // Slots are 100 pt wide: x = 50 is Contacts, x = 350 is Settings.
    await tester.tapAt(Offset(rect.left + 50, rect.center.dy));
    await tester.pumpAndSettle();
    expect(selections, <int>[0]);

    await tester.tapAt(Offset(rect.left + 350, rect.center.dy));
    await tester.pumpAndSettle();
    expect(selections, <int>[0, 3]);
  });

  testWidgets('a slow drag commits the tab under the finger', (
    WidgetTester tester,
  ) async {
    final List<int> selections = await pumpBar(tester);
    final Rect rect = tester.getRect(find.byType(CourierTabBar));
    final double y = rect.center.dy;

    // Start on Chats (slot 2, centre 250), drag left into Calls (slot 1).
    final TestGesture gesture =
        await tester.startGesture(Offset(rect.left + 250, y));
    await tester.pump(const Duration(milliseconds: 80));
    for (int i = 0; i < 3; i++) {
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Let the velocity decay so this is a settle, not a throw.
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selections.last, 1);
  });

  testWidgets('a flick throws the lens to the next tab', (
    WidgetTester tester,
  ) async {
    final List<int> selections = await pumpBar(tester);

    await tester.fling(
      find.byType(CourierTabBar),
      const Offset(-120, 0),
      1200,
    );
    await tester.pumpAndSettle();

    // The throw carries past the finger's own slot rather than snapping back.
    expect(selections, isNotEmpty);
    expect(selections.last, lessThan(2));
  });
}
