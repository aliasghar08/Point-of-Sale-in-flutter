import 'package:flutter/services.dart';

/// In-house feedback service for haptics and audio effects on POS actions.
class FeedbackService {
  FeedbackService._();

  /// Light haptic tap for button presses and counter increments
  static Future<void> lightTap({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium haptic feedback for cart additions and scan confirmations
  static Future<void> selection({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Success chime / feedback on checkout or sale completion
  static Future<void> success({bool sound = true, bool haptic = true}) async {
    try {
      if (haptic) await HapticFeedback.mediumImpact();
      if (sound) await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Error feedback on scan failure or validation error
  static Future<void> error({bool sound = true, bool haptic = true}) async {
    try {
      if (haptic) await HapticFeedback.heavyImpact();
      if (sound) await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
