import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/screens/home_screen_v2.dart';
import 'package:one_touch_savings/widgets/simplified_progress_display.dart';
import 'package:one_touch_savings/widgets/savings_button.dart';
import 'package:one_touch_savings/widgets/animated_character.dart';
import 'package:one_touch_savings/widgets/usage_stats_card.dart';
import 'package:one_touch_savings/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    // Initialize the ffi loader if needed for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Use unique test database for widget tests
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    DatabaseService.useCustomTestDatabase(
        'test_db_small_screen_v2_$timestamp.db');
  });

  tearDownAll(() async {
    // Restore normal database after tests
    DatabaseService.useNormalDatabase();
  });

  group('HomeScreenV2 Small Screen Support Tests', () {
    testWidgets(
        'should maintain unchanged layout on iPhone 16 Pro baseline (393x852)',
        (WidgetTester tester) async {
      // Set iPhone 16 Pro screen size (baseline)
      await tester.binding.setSurfaceSize(const Size(393, 852));

      // Pump the HomeScreenV2 widget with explicit MediaQuery override
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(393, 852),
              devicePixelRatio: 3.0,
              padding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: HomeScreenV2(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify essential V2 elements are present
      expect(find.byType(SimplifiedProgressDisplay), findsOneWidget);
      expect(find.byType(SavingsButton), findsOneWidget);
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
      expect(find.byType(UsageStatsCard), findsOneWidget);

      // Verify button text label IS present (V2 design updated)
      expect(find.text('터치해서 ₩1,000 저축하기'), findsOneWidget);

      // Verify baseline layout characteristics for iPhone 16 Pro
      // Check that main content fits within screen bounds
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      final scaffoldRect = tester.getRect(scaffold);
      expect(scaffoldRect.width, lessThanOrEqualTo(393));
      expect(scaffoldRect.height, lessThanOrEqualTo(852));

      // Verify baseline turtle size (should be 250x150 on iPhone 16 Pro)
      final turtle = find.byType(AnimatedTurtleSprite);
      final turtleWidget = tester.widget<AnimatedTurtleSprite>(turtle);
      expect(turtleWidget.width, equals(250.0));
      expect(turtleWidget.height, equals(150.0));

      // Verify all essential elements are visible within screen bounds
      final progressDisplay = find.byType(SimplifiedProgressDisplay);
      final progressRect = tester.getRect(progressDisplay);
      expect(progressRect.top, greaterThanOrEqualTo(0));
      expect(progressRect.bottom, lessThanOrEqualTo(852));

      final savingsButton = find.byType(SavingsButton);
      final buttonRect = tester.getRect(savingsButton);
      expect(buttonRect.top, greaterThanOrEqualTo(0));
      expect(buttonRect.bottom, lessThanOrEqualTo(852));

      final turtleRect = tester.getRect(turtle);
      expect(turtleRect.top, greaterThanOrEqualTo(0));
      expect(turtleRect.bottom, lessThanOrEqualTo(852));
    });

    testWidgets(
        'should fit entirely on small screen (800x480) without scrolling',
        (WidgetTester tester) async {
      // Set small screen size (800x480 WVGA)
      await tester.binding.setSurfaceSize(const Size(800, 480));

      // Pump the HomeScreenV2 widget with explicit MediaQuery override
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(800, 480),
              devicePixelRatio: 1.0,
              padding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: HomeScreenV2(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify essential V2 elements are present
      expect(find.byType(SimplifiedProgressDisplay), findsOneWidget);
      expect(find.byType(SavingsButton), findsOneWidget);
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
      expect(find.byType(UsageStatsCard), findsOneWidget);

      // Verify button text label IS present (V2 design updated per tasks.md)
      expect(find.text('터치해서 ₩1,000 저축하기'), findsOneWidget);

      // Check that main content fits within screen bounds
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      final scaffoldRect = tester.getRect(scaffold);
      expect(scaffoldRect.width, lessThanOrEqualTo(800));
      expect(scaffoldRect.height, lessThanOrEqualTo(480));

      // Small screens should NOT have SingleChildScrollView since they fit without scrolling
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsNothing,
          reason:
              'Small screen layout should not use SingleChildScrollView since content should fit without scrolling');

      // Verify all essential elements are visible within 480px height bounds
      final progressDisplay = find.byType(SimplifiedProgressDisplay);
      final progressRect = tester.getRect(progressDisplay);
      expect(progressRect.top, greaterThanOrEqualTo(0));
      expect(progressRect.bottom, lessThanOrEqualTo(480));

      final savingsButton = find.byType(SavingsButton);
      final buttonRect = tester.getRect(savingsButton);
      expect(buttonRect.top, greaterThanOrEqualTo(0));
      expect(buttonRect.bottom, lessThanOrEqualTo(480));

      final turtle = find.byType(AnimatedTurtleSprite);
      final turtleRect = tester.getRect(turtle);
      expect(turtleRect.top, greaterThanOrEqualTo(0));
      expect(turtleRect.bottom, lessThanOrEqualTo(480));

      // Verify button text is within bounds
      final buttonText = find.text('터치해서 ₩1,000 저축하기');
      final textRect = tester.getRect(buttonText);
      expect(textRect.top, greaterThanOrEqualTo(0));
      expect(textRect.bottom, lessThanOrEqualTo(480));
    });

    testWidgets(
        'should maintain proper horizontal layout and vertical order on small screen',
        (WidgetTester tester) async {
      // Test on 800x480 screen size
      await tester.binding.setSurfaceSize(const Size(800, 480));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 480),
              devicePixelRatio: 1.0,
              padding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: const HomeScreenV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all major elements
      final progressDisplay = find.byType(SimplifiedProgressDisplay);
      final usageStats = find.byType(UsageStatsCard);
      final turtle = find.byType(AnimatedTurtleSprite);
      final savingsButton = find.byType(SavingsButton);
      final buttonText = find.text('터치해서 ₩1,000 저축하기');

      // Get their positions
      final progressRect = tester.getRect(progressDisplay);
      final statsRect = tester.getRect(usageStats);
      final turtleRect = tester.getRect(turtle);
      final buttonRect = tester.getRect(savingsButton);
      final textRect = tester.getRect(buttonText);

      // NEW: Verify horizontal layout for top row
      // Progress display should be on the left, stats card on the right
      expect(progressRect.left, lessThan(statsRect.left),
          reason: 'Progress display should be to the left of stats card');
      expect(progressRect.right, lessThanOrEqualTo(statsRect.left + 10),
          reason: 'Progress and stats should not overlap horizontally');
      
      // Both should be in the same vertical row (similar top position)
      // Increased tolerance for vertical layout in stats card
      expect((progressRect.top - statsRect.top).abs(), lessThan(50),
          reason: 'Progress and stats should be in the same row');

      // NEW: Verify vertical order for rows
      // Row 1 (progress + stats) -> Row 2 (turtle) -> Row 3 (button + text)
      final topRowBottom = math.max(progressRect.bottom, statsRect.bottom);
      expect(topRowBottom, lessThanOrEqualTo(turtleRect.top),
          reason: 'Top row should be above turtle');
      expect(turtleRect.bottom, lessThanOrEqualTo(buttonRect.top),
          reason: 'Turtle should be above button');
      expect(buttonRect.bottom, lessThanOrEqualTo(textRect.top),
          reason: 'Button should be above text');

      // Verify reasonable spacing between rows
      expect(turtleRect.top - topRowBottom, greaterThan(5),
          reason: 'Should have spacing between top row and turtle');
      expect(buttonRect.top - turtleRect.bottom, greaterThan(5),
          reason: 'Should have spacing between turtle and button');
      expect(textRect.top - buttonRect.bottom, greaterThan(2),
          reason: 'Should have minimal spacing between button and text');

      // Verify SafeArea is applied (top row should not start at y=0)
      expect(progressRect.top, greaterThan(0),
          reason: 'SafeArea should provide top padding');
      expect(statsRect.top, greaterThan(0),
          reason: 'SafeArea should provide top padding');
    });

    testWidgets(
        'should maintain V2 design principles on small screens (no AppBar, simplified layout)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 480),
              devicePixelRatio: 1.0,
              padding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: const HomeScreenV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify V2 design characteristics are maintained at small screen size

      // No AppBar (V2 design principle)
      expect(find.byType(AppBar), findsNothing);

      // Simplified progress display (not full ProgressDisplay with progress bar)
      expect(find.byType(SimplifiedProgressDisplay), findsOneWidget);

      // Usage stats in single card format (V2 approach) with maintained card design
      expect(find.byType(UsageStatsCard), findsOneWidget);
      
      // UsageStatsCard should maintain card appearance even in compact mode
      final usageStatsCard = find.byType(UsageStatsCard);
      final usageStatsWidget = tester.widget<UsageStatsCard>(usageStatsCard);
      expect(usageStatsWidget.ultraCompact, isTrue,
          reason: 'Should use ultraCompact mode on small screen');

      // No individual stat cards (V1 uses multiple separate Card widgets)
      // But UsageStatsCard itself should still look like a card
      final cardContainers = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).border != null);
      expect(cardContainers, findsAtLeastNWidgets(1),
          reason: 'UsageStatsCard should maintain card-like appearance');

      // Turtle animation present (V2 exclusive)
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);

      // Button text label present (updated V2 design)
      expect(find.text('터치해서 ₩1,000 저축하기'), findsOneWidget);

      // No progress message container with blue background (V1 feature)
      final progressMessageContainers = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color != null &&
          (widget.decoration as BoxDecoration)
              .color
              .toString()
              .contains('blue') &&
          (widget.decoration as BoxDecoration).border != null &&
          widget.padding == const EdgeInsets.all(16));
      expect(progressMessageContainers, findsNothing);
    });

    testWidgets(
        'should use horizontal layout with proper element sizing on small screen',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 480),
              devicePixelRatio: 1.0,
              padding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: const HomeScreenV2(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find top row elements
      final progressDisplay = find.byType(SimplifiedProgressDisplay);
      final usageStats = find.byType(UsageStatsCard);

      // Get their positions and sizes
      final progressRect = tester.getRect(progressDisplay);
      final statsRect = tester.getRect(usageStats);

      // Verify horizontal arrangement
      expect(progressRect.left, lessThan(statsRect.left),
          reason: 'Progress should be left of stats');
      
      // Verify reasonable widths (both should take reasonable portions of screen width)
      final screenWidth = 800.0;
      expect(progressRect.width, greaterThan(screenWidth * 0.2),
          reason: 'Progress display should be at least 20% of screen width');
      expect(statsRect.width, greaterThan(screenWidth * 0.2),
          reason: 'Stats card should be at least 20% of screen width');
      
      // Together they should utilize most of the screen width for full layout
      expect(progressRect.width + statsRect.width, lessThan(screenWidth * 0.98),
          reason: 'Combined width should leave minimal room for spacing');

      // Verify SafeArea creates top padding
      expect(progressRect.top, greaterThan(10),
          reason: 'SafeArea should create meaningful top padding');

      // Verify all elements fit within screen height
      final turtle = find.byType(AnimatedTurtleSprite);
      final button = find.byType(SavingsButton);
      final buttonText = find.text('터치해서 ₩1,000 저축하기');
      
      final turtleRect = tester.getRect(turtle);
      final buttonRect = tester.getRect(button);
      final textRect = tester.getRect(buttonText);

      expect(textRect.bottom, lessThanOrEqualTo(480),
          reason: 'All content should fit within 480px height');
      expect(turtleRect.bottom, lessThanOrEqualTo(480),
          reason: 'Turtle should fit within screen height');
      expect(buttonRect.bottom, lessThanOrEqualTo(480),
          reason: 'Button should fit within screen height');
    });
  });
}

