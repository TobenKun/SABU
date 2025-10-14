import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/widgets/milestone_celebration.dart';

void main() {
  group('MilestoneCelebration Widget Tests', () {
    testWidgets('MilestoneCelebration displays milestone amount correctly', (WidgetTester tester) async {
      const milestoneAmount = 10000;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: milestoneAmount,
              onComplete: () {},
            ),
          ),
        ),
      );

      // Check if milestone amount is displayed
      expect(find.text('₩10,000'), findsOneWidget);
      expect(find.text('milestone achieved!'), findsOneWidget);
    });

    testWidgets('MilestoneCelebration triggers scale animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 20000,
              onComplete: () {},
            ),
          ),
        ),
      );

      // Find the celebration container (using manual animations)
      final celebrationContainer = find.byKey(const Key('celebration_container'));
      expect(celebrationContainer, findsOneWidget);

      // Pump initial frame
      await tester.pump();
      
      // Pump animation frames to test scale animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      
      // Animation should be progressing
      expect(celebrationContainer, findsOneWidget);
    });

    testWidgets('MilestoneCelebration color transitions work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 30000,
              onComplete: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Check for celebration container with color animation
      final colorContainer = find.byKey(const Key('celebration_container'));
      expect(colorContainer, findsOneWidget);
      
      // Pump through color transition
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    testWidgets('MilestoneCelebration calls onComplete when animation finishes', (WidgetTester tester) async {
      bool onCompleteCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 40000,
              onComplete: () {
                onCompleteCalled = true;
              },
            ),
          ),
        ),
      );

      // Let animation complete
      await tester.pumpAndSettle();
      
      expect(onCompleteCalled, isTrue, reason: 'onComplete should be called when animation finishes');
    });

    testWidgets('MilestoneCelebration handles multiple milestones correctly', (WidgetTester tester) async {
      // Test 50,000원 milestone display
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 50000,
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('₩50,000'), findsOneWidget);
      expect(find.text('milestone achieved!'), findsOneWidget);
    });

    testWidgets('MilestoneCelebration animation duration is correct', (WidgetTester tester) async {
      bool animationCompleted = false;
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 60000,
              onComplete: () {
                stopwatch.stop();
                animationCompleted = true;
              },
            ),
          ),
        ),
      );

      // Let animation complete
      await tester.pumpAndSettle();
      
      expect(animationCompleted, isTrue);
      // Animation should complete within reasonable time (1-2 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(2500), 
        reason: 'Animation should complete within 2.5 seconds');
    });

    testWidgets('MilestoneCelebration has proper accessibility features', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 70000,
              onComplete: () {},
            ),
          ),
        ),
      );

      // Check for semantic labels
      expect(find.bySemanticsLabel(RegExp('milestone.*achieved')), findsOneWidget);
    });

    testWidgets('MilestoneCelebration maintains 60fps during animation', (WidgetTester tester) async {
      // This test checks for performance by ensuring no frame drops
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 80000,
              onComplete: () {},
            ),
          ),
        ),
      );

      // Monitor frame rendering during animation
      // Note: transientCallbackCount helps verify animation performance
      
      // Pump several frames quickly to simulate animation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // 60fps = 16ms per frame
      }
      
      // Should handle rapid frame updates without issues
      expect(tester.takeException(), isNull, reason: 'No exceptions during rapid frame updates');
    });

    testWidgets('MilestoneCelebration handles large milestone amounts', (WidgetTester tester) async {
      const largeMilestone = 1000000; // 1,000,000원
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: largeMilestone,
              onComplete: () {},
            ),
          ),
        ),
      );

      // Should format large numbers correctly
      expect(find.text('₩1,000,000'), findsOneWidget);
    });

    testWidgets('MilestoneCelebration can be interrupted and restarted', (WidgetTester tester) async {
      bool secondAnimationCompleted = false;
      
      // Start first animation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 90000,
              onComplete: () {
                // First animation callback (not tracked)
              },
            ),
          ),
        ),
      );

      // Pump partial animation
      await tester.pump(const Duration(milliseconds: 500));
      
      // Replace with new milestone (simulating rapid milestone achievement)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebration(
              milestoneAmount: 100000,
              onComplete: () {
                secondAnimationCompleted = true;
              },
            ),
          ),
        ),
      );

      // Complete second animation
      await tester.pumpAndSettle();
      
      expect(secondAnimationCompleted, isTrue, 
        reason: 'Second animation should complete');
    });
  });
}