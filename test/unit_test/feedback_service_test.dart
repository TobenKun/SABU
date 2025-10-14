import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/services/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('FeedbackService', () {
    setUp(() {
      // Reset haptics to enabled for each test
      FeedbackService.setHapticsEnabled(true);
    });

    group('Haptics Settings', () {
      test('should enable and disable haptics', () {
        expect(FeedbackService.hapticsEnabled, isTrue);
        
        FeedbackService.setHapticsEnabled(false);
        expect(FeedbackService.hapticsEnabled, isFalse);
        
        FeedbackService.setHapticsEnabled(true);
        expect(FeedbackService.hapticsEnabled, isTrue);
      });
    });

    group('Haptic Feedback Types', () {
      late List<MethodCall> methodCalls;

      setUp(() {
        methodCalls = [];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          methodCalls.add(call);
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      test('should trigger light impact for light feedback', () async {
        await FeedbackService.haptic(FeedbackType.light);
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'HapticFeedback.vibrate');
        expect(methodCalls.first.arguments, 'HapticFeedbackType.lightImpact');
      });

      test('should trigger medium impact for medium feedback', () async {
        await FeedbackService.haptic(FeedbackType.medium);
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'HapticFeedback.vibrate');
        expect(methodCalls.first.arguments, 'HapticFeedbackType.mediumImpact');
      });

      test('should trigger heavy impact for heavy feedback', () async {
        await FeedbackService.haptic(FeedbackType.heavy);
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'HapticFeedback.vibrate');
        expect(methodCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
      });

      test('should trigger medium impact for success feedback', () async {
        await FeedbackService.haptic(FeedbackType.success);
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'HapticFeedback.vibrate');
        expect(methodCalls.first.arguments, 'HapticFeedbackType.mediumImpact');
      });

      test('should trigger light impact for warning feedback', () async {
        await FeedbackService.haptic(FeedbackType.warning);
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'HapticFeedback.vibrate');
        expect(methodCalls.first.arguments, 'HapticFeedbackType.lightImpact');
      });

      test('should trigger heavy impact for error feedback', () async {
        await FeedbackService.haptic(FeedbackType.error);
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'HapticFeedback.vibrate');
        expect(methodCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
      });

      test('should trigger selection click for selection feedback', () async {
        await FeedbackService.haptic(FeedbackType.selection);
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'HapticFeedback.vibrate');
        expect(methodCalls.first.arguments, 'HapticFeedbackType.selectionClick');
      });

      test('should not trigger feedback when haptics are disabled', () async {
        FeedbackService.setHapticsEnabled(false);
        await FeedbackService.haptic(FeedbackType.light);
        
        expect(methodCalls, isEmpty);
      });

      test('should handle exceptions gracefully', () async {
        // Setup mock to throw exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          throw PlatformException(code: 'test_error', message: 'Test error');
        });

        // Should not throw
        await expectLater(
          FeedbackService.haptic(FeedbackType.light),
          completes,
        );
      });
    });

    group('Convenience Methods', () {
      late List<MethodCall> methodCalls;

      setUp(() {
        methodCalls = [];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          methodCalls.add(call);
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      test('buttonPress should trigger light impact', () async {
        await FeedbackService.buttonPress();
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.arguments, 'HapticFeedbackType.lightImpact');
      });

      test('saveSuccess should trigger medium impact', () async {
        await FeedbackService.saveSuccess();
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.arguments, 'HapticFeedbackType.mediumImpact');
      });

      test('milestone should trigger heavy impact', () async {
        await FeedbackService.milestone();
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
      });

      test('error should trigger heavy impact', () async {
        await FeedbackService.error();
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
      });

      test('selection should trigger selection click', () async {
        await FeedbackService.selection();
        
        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.arguments, 'HapticFeedbackType.selectionClick');
      });
    });

    group('Milestone Celebration', () {
      late List<MethodCall> methodCalls;

      setUp(() {
        methodCalls = [];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          methodCalls.add(call);
          return null;
        });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      test('milestoneCelebration should trigger three heavy impacts', () async {
        await FeedbackService.milestoneCelebration();
        
        expect(methodCalls, hasLength(3));
        for (final call in methodCalls) {
          expect(call.method, 'HapticFeedback.vibrate');
          expect(call.arguments, 'HapticFeedbackType.heavyImpact');
        }
      });

      test('milestoneCelebration should not trigger when haptics disabled', () async {
        FeedbackService.setHapticsEnabled(false);
        await FeedbackService.milestoneCelebration();
        
        expect(methodCalls, isEmpty);
      });

      test('milestoneCelebration should handle exceptions gracefully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          throw PlatformException(code: 'test_error', message: 'Test error');
        });

        await expectLater(
          FeedbackService.milestoneCelebration(),
          completes,
        );
      });

      test('milestoneWithAnimation should trigger celebration and mid-point for long animations', () async {
        const longDuration = Duration(milliseconds: 2000);
        
        // Start the async operation
        final future = FeedbackService.milestoneWithAnimation(
          animationDuration: longDuration,
        );
        
        // Wait for initial celebration (3 heavy impacts)
        await Future.delayed(const Duration(milliseconds: 350));
        expect(methodCalls.length, greaterThanOrEqualTo(3));
        
        // Wait for mid-point impact
        await future;
        expect(methodCalls.length, greaterThanOrEqualTo(4));
        
        // Check that last call is medium impact (mid-point)
        final lastCall = methodCalls.last;
        expect(lastCall.arguments, 'HapticFeedbackType.mediumImpact');
      });

      test('milestoneWithAnimation should only trigger celebration for short animations', () async {
        const shortDuration = Duration(milliseconds: 1000);
        
        await FeedbackService.milestoneWithAnimation(
          animationDuration: shortDuration,
        );
        
        // Should only have the celebration (3 heavy impacts), no mid-point
        expect(methodCalls, hasLength(3));
        for (final call in methodCalls) {
          expect(call.arguments, 'HapticFeedbackType.heavyImpact');
        }
      });

      test('milestoneWithAnimation should not trigger when haptics disabled', () async {
        FeedbackService.setHapticsEnabled(false);
        await FeedbackService.milestoneWithAnimation();
        
        expect(methodCalls, isEmpty);
      });

      test('milestoneWithAnimation should handle exceptions gracefully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          throw PlatformException(code: 'test_error', message: 'Test error');
        });

        await expectLater(
          FeedbackService.milestoneWithAnimation(),
          completes,
        );
      });
    });
  });
}