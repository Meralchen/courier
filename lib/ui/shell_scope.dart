import 'package:material_ui/material_ui.dart';

/// Lets a tab switch the shell's selected tab without importing the shell.
///
/// Settings uses it for "Recent Calls", which is the Calls tab rather than a
/// second screen with its own navigation stack.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goToTab, required super.child});

  final ValueChanged<int> goToTab;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => goToTab != oldWidget.goToTab;
}
