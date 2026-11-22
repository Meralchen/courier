import 'package:courier/state/app_settings.dart';
import 'package:courier/state/scopes.dart';
import 'package:courier/ui/components/glass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquiglass/liquiglass.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('classic iOS swaps the shader for a flat surface', (
    WidgetTester tester,
  ) async {
    final AppSettings settings = AppSettings();
    await tester.pumpWidget(
      SettingsScope(
        settings: settings,
        child: MaterialApp(
          home: Scaffold(
            body: GlassBar(child: const SizedBox(width: 200, height: 56)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GlassSurface), findsOneWidget);

    settings.glassStyle = GlassStyle.classic;
    settings.notifyListeners();
    await tester.pumpAndSettle();

    // No backdrop filter at all: this is the whole point of the switch.
    expect(find.byType(GlassSurface), findsNothing);
  });
}
