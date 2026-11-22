import 'package:courier/ui/components/glass.dart';
import 'package:courier/ui/tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<List<int>> pumpBar(
    WidgetTester tester, {
    VoidCallback? onSearch,
  }) async {
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
                onSearch: onSearch,
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

  testWidgets('a tap glides the selection instead of snapping it', (
    WidgetTester tester,
  ) async {
    final List<int> selections = await pumpBar(tester);
    final Rect rect = tester.getRect(find.byType(CourierTabBar));
    // The bar insets itself by 12 pt on each side before splitting slots.
    final double left = rect.left + 12;
    final double slot = (rect.width - 24) / 4;

    // The selection is a single shape (the second GlassPanel; the first is the
    // bar). It starts on Chats, slot 2.
    expect(find.byType(GlassPanel), findsNWidgets(2));
    final double restX = tester.getCenter(find.byType(GlassPanel).last).dx;
    expect(restX, closeTo(left + 2.5 * slot, 2));

    final TestGesture gesture = await tester.startGesture(
      Offset(left + 3.5 * slot, rect.center.dy),
    );
    // The tap recogniser claims the gesture after kPressTimeout (100 ms); the
    // glide starts there.
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 70));
    final double midX = tester.getCenter(find.byType(GlassPanel).last).dx;

    // It has left the old tab and has not jumped to the new one: one tile
    // travelling, not two stacked in the same slot.
    expect(midX, greaterThan(restX + 4));
    expect(midX, lessThan(left + 3.5 * slot - 4));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, <int>[3]);
  });

  testWidgets('the trailing search accessory does not disturb the tabs', (
    WidgetTester tester,
  ) async {
    bool searched = false;
    final List<int> selections = await pumpBar(
      tester,
      onSearch: () => searched = true,
    );
    final Rect rect = tester.getRect(find.byType(CourierTabBar));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(searched, isTrue);
    expect(selections, isEmpty);

    // The four tabs still own their slots next to the accessory.
    await tester.tapAt(Offset(rect.left + 12 + 40, rect.center.dy));
    await tester.pumpAndSettle();
    expect(selections, <int>[0]);
  });

  testWidgets('a slow drag commits the tab under the finger', (
    WidgetTester tester,
  ) async {
    final List<int> selections = await pumpBar(tester);
    final Rect rect = tester.getRect(find.byType(CourierTabBar));
    final double y = rect.center.dy;

    // Start on Chats (slot 2, centre 250), drag left into Calls (slot 1).
    final TestGesture gesture = await tester.startGesture(
      Offset(rect.left + 250, y),
    );
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

    await tester.fling(find.byType(CourierTabBar), const Offset(-120, 0), 1200);
    await tester.pumpAndSettle();

    // The throw carries past the finger's own slot rather than snapping back.
    expect(selections, isNotEmpty);
    expect(selections.last, lessThan(2));
  });
}
