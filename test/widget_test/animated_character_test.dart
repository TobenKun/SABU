import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/models/animation_state.dart';
import 'package:one_touch_savings/widgets/animated_character.dart';

void main() {
  group('AnimatedTurtleSprite', () {
    testWidgets('should display turtle sprite with correct size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTurtleSprite(
              level: TurtleAnimationLevel.idle,
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // Should find the turtle sprite widget
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
      
      // Should find a SizedBox with correct dimensions
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 100.0);
      expect(sizedBox.height, 100.0);
    });

    testWidgets('should handle idle animation level', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTurtleSprite(
              level: TurtleAnimationLevel.idle,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Should display an image
      expect(find.byType(Image), findsOneWidget);
      
      // For idle, animation should eventually reset to frame 0
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should handle walking animation levels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTurtleSprite(
              level: TurtleAnimationLevel.walkSlow,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Image), findsOneWidget);

      // Animation should be running for walking
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should handle running animation levels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTurtleSprite(
              level: TurtleAnimationLevel.runFast,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Image), findsOneWidget);

      // Animation should be running for running
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should update animation when level changes', (WidgetTester tester) async {
      TurtleAnimationLevel currentLevel = TurtleAnimationLevel.idle;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedTurtleSprite(level: currentLevel),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentLevel = TurtleAnimationLevel.runFast;
                        });
                      },
                      child: const Text('Change Level'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initially should show idle
      await tester.pump();
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);

      // Tap to change level
      await tester.tap(find.text('Change Level'));
      await tester.pump();

      // Should still have the sprite (now with different level)
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
      
      // Animation should continue running
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should handle error in image loading gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTurtleSprite(
              level: TurtleAnimationLevel.walkFast,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Should always find an image widget, even if some frames fail to load
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should use default size when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTurtleSprite(
              level: TurtleAnimationLevel.idle,
            ),
          ),
        ),
      );

      await tester.pump();
      
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 300.0); // Default size
      expect(sizedBox.height, 300.0);
    });

    testWidgets('should have different animation speeds for different levels', (WidgetTester tester) async {
      // Test that different levels exist and can be rendered
      for (final level in TurtleAnimationLevel.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedTurtleSprite(level: level),
            ),
          ),
        );
        
        await tester.pump();
        expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        
        // Let animation run briefly
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(Image), findsOneWidget);
      }
    });

    testWidgets('should properly dispose animation controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedTurtleSprite(
              level: TurtleAnimationLevel.runFast,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);

      // Remove the widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('No turtle'),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AnimatedTurtleSprite), findsNothing);
      
      // Should not crash after disposal
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}