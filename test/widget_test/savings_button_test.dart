import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/widgets/savings_button.dart';

void main() {
  group('SavingsButton Widget Tests', () {
    testWidgets('should render savings button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsButton(
              onPressed: () {},
            ),
          ),
        ),
      );
      
      // Find the button
      expect(find.byType(SavingsButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should trigger callback on tap', (WidgetTester tester) async {
      bool callbackTriggered = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsButton(
              onPressed: () => callbackTriggered = true,
            ),
          ),
        ),
      );
      
      // Tap the button
      await tester.tap(find.byType(SavingsButton));
      await tester.pumpAndSettle();
      
      expect(callbackTriggered, isTrue);
    });

    testWidgets('should animate on press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsButton(
              onPressed: () {},
            ),
          ),
        ),
      );
      
      // Get initial button properties
      final buttonFinder = find.byType(SavingsButton);
      expect(buttonFinder, findsOneWidget);
      
      // Start tap but don't complete it
      await tester.startGesture(tester.getCenter(buttonFinder));
      await tester.pump();
      
      // Button should show pressed state
      final animatedScale = tester.widget<AnimatedScale>(
        find.descendant(
          of: buttonFinder,
          matching: find.byType(AnimatedScale),
        ),
      );
      
      // Should scale down when pressed
      expect(animatedScale.scale, lessThan(1.0));
    });

    testWidgets('should prevent double-tap', (WidgetTester tester) async {
      int tapCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsButton(
              onPressed: () => tapCount++,
            ),
          ),
        ),
      );
      
      // Rapid double tap
      await tester.tap(find.byType(SavingsButton));
      await tester.tap(find.byType(SavingsButton));
      
      // Wait for debounce timer to complete (50ms + some buffer)
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should only register one tap due to debouncing
      expect(tapCount, equals(1));
    });

    testWidgets('should have correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsButton(
              onPressed: () {},
            ),
          ),
        ),
      );
      
      final containerWidget = tester.widget<Container>(
        find.descendant(
          of: find.byType(SavingsButton),
          matching: find.byType(Container),
        ),
      );
      
      final decoration = containerWidget.decoration as BoxDecoration;
      
      // Check the size using the render object instead
      final RenderBox renderBox = tester.renderObject(find.byType(Container));
      expect(renderBox.size.width, equals(200));
      expect(renderBox.size.height, equals(200));
      expect(decoration.shape, equals(BoxShape.circle));
      expect(decoration.color, equals(Colors.blue));
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, equals(1));
    });

    testWidgets('should change color when pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavingsButton(
              onPressed: () {},
            ),
          ),
        ),
      );
      
      // Start gesture to simulate press
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SavingsButton)),
      );
      await tester.pump();
      
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SavingsButton),
          matching: find.byType(Container),
        ),
      );
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.green));
      
      // Release gesture
      await gesture.up();
      await tester.pumpAndSettle();
      
      final containerAfter = tester.widget<Container>(
        find.descendant(
          of: find.byType(SavingsButton),
          matching: find.byType(Container),
        ),
      );
      
      final decorationAfter = containerAfter.decoration as BoxDecoration;
      expect(decorationAfter.color, equals(Colors.blue));
    });
  });
}