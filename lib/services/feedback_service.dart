import 'package:flutter/services.dart';

enum FeedbackType {
  light,
  medium,
  heavy,
  success,
  warning,
  error,
  selection,
}

class FeedbackService {
  static bool _hapticsEnabled = true;
  
  /// Enable or disable haptic feedback globally
  static void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }
  
  /// Check if haptics are currently enabled
  static bool get hapticsEnabled => _hapticsEnabled;
  
  /// Provide haptic feedback based on the specified type
  static Future<void> haptic(FeedbackType type) async {
    if (!_hapticsEnabled) return;
    
    try {
      switch (type) {
        case FeedbackType.light:
          await HapticFeedback.lightImpact();
          break;
        case FeedbackType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case FeedbackType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case FeedbackType.success:
          await HapticFeedback.mediumImpact();
          break;
        case FeedbackType.warning:
          await HapticFeedback.lightImpact();
          break;
        case FeedbackType.error:
          await HapticFeedback.heavyImpact();
          break;
        case FeedbackType.selection:
          await HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      // Silently fail if haptics aren't supported on the device
      // This ensures the app continues to work on devices without haptic support
    }
  }
  
  /// Convenience method for button press feedback
  static Future<void> buttonPress() async {
    await haptic(FeedbackType.light);
  }
  
  /// Convenience method for save operation success feedback
  static Future<void> saveSuccess() async {
    await haptic(FeedbackType.success);
  }
  
  /// Convenience method for milestone achievement feedback
  static Future<void> milestone() async {
    await haptic(FeedbackType.heavy);
  }
  
  /// Enhanced milestone feedback with multiple pulses for special celebrations
  static Future<void> milestoneCelebration() async {
    if (!_hapticsEnabled) return;
    
    try {
      // Triple heavy impact for milestone celebrations
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently fail if haptics aren't supported
    }
  }
  
  /// Milestone feedback synchronized with celebration animation timing
  static Future<void> milestoneWithAnimation({
    Duration animationDuration = const Duration(milliseconds: 2000),
  }) async {
    if (!_hapticsEnabled) return;
    
    try {
      // Initial celebration burst
      await milestoneCelebration();
      
      // If animation is long enough, add a mid-point emphasis
      if (animationDuration.inMilliseconds > 1500) {
        await Future.delayed(Duration(milliseconds: animationDuration.inMilliseconds ~/ 2));
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // Silently fail if haptics aren't supported
    }
  }
  
  /// Convenience method for error feedback
  static Future<void> error() async {
    await haptic(FeedbackType.error);
  }
  
  /// Convenience method for UI selection feedback
  static Future<void> selection() async {
    await haptic(FeedbackType.selection);
  }
}