import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:liquiglass/liquiglass.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Warm the AGSL material so the first glass bar does not flash its stand-in.
  await LiquidGlass.ensureInitialized();
  runApp(const CourierApp());
}
