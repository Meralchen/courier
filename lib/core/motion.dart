import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

/// Durations and curves borrowed from the iOS spring vocabulary.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve emphasized = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1.0);
}

/// Small wrapper so every interaction has the same tactile language.
abstract final class Haptics {
  static Future<void> tap() => HapticFeedback.selectionClick();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> success() => HapticFeedback.mediumImpact();
}
