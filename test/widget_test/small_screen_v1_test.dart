import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/screens/home_screen.dart';
import 'package:one_touch_savings/widgets/progress_display.dart';
import 'package:one_touch_savings/widgets/savings_button.dart';
import 'package:one_touch_savings/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    // Initialize the ffi loader if needed for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Use unique test database for widget tests
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    DatabaseService.useCustomTestDatabase('test_db_small_screen_v1_$timestamp.db');
  });

  tearDownAll(() async {
    // Restore normal database after tests
    DatabaseService.useNormalDatabase();
  });

  group('HomeScreen V1 Small Screen Support Tests', () {
    testWidgets('should maintain unchanged layout on iPhone 16 Pro baseline (393x852)', (WidgetTester tester) async {
      // Set iPhone 16 Pro screen size (baseline)
      await tester.binding.setSurfaceSize(const Size(393, 852));
      
      // Pump the HomeScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      
      // Wait for the widget to settle
      await tester.pumpAndSettle();
      
      // Verify essential V1 elements are present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ProgressDisplay), findsOneWidget);
      expect(find.byType(SavingsButton), findsOneWidget);
      
      // Verify button text label IS present (V1 design)
      expect(find.text('터치해서 ₩1,000 저축하기'), findsOneWidget);
      
      // Verify baseline layout characteristics for iPhone 16 Pro
      // Check that main content fits within screen bounds
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);
      
      final scaffoldRect = tester.getRect(scaffold);
      expect(scaffoldRect.width, lessThanOrEqualTo(393));
      expect(scaffoldRect.height, lessThanOrEqualTo(852));
      
      // Verify all essential elements are visible within screen bounds
      final appBar = find.byType(AppBar);
      final appBarRect = tester.getRect(appBar);
      expect(appBarRect.top, greaterThanOrEqualTo(0));
      expect(appBarRect.bottom, lessThanOrEqualTo(852));
      
      final progressDisplay = find.byType(ProgressDisplay);
      final progressRect = tester.getRect(progressDisplay);
      expect(progressRect.top, greaterThanOrEqualTo(0));
      expect(progressRect.bottom, lessThanOrEqualTo(852));
      
      final savingsButton = find.byType(SavingsButton);
      final buttonRect = tester.getRect(savingsButton);
      expect(buttonRect.top, greaterThanOrEqualTo(0));
      expect(buttonRect.bottom, lessThanOrEqualTo(852));
    });

    testWidgets('should fit entirely on small screen (800x480) without scrolling', (WidgetTester tester) async {
      // Set small screen size (800x480 WVGA)
      await tester.binding.setSurfaceSize(const Size(800, 480));
      
      // Pump the HomeScreen widget with explicit MediaQuery override
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
            child: HomeScreen(),
          ),
        ),
      );
      
      // Wait for the widget to settle
      await tester.pumpAndSettle();
      
      // Verify essential V1 elements are present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ProgressDisplay), findsOneWidget);
      expect(find.byType(SavingsButton), findsOneWidget);
      
      // Verify button text label IS present (V1 design)
      expect(find.text('터치해서 ₩1,000 저축하기'), findsOneWidget);
      
      // Check that main content fits within screen bounds
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);
      
      final scaffoldRect = tester.getRect(scaffold);
      expect(scaffoldRect.width, lessThanOrEqualTo(800));
      expect(scaffoldRect.height, lessThanOrEqualTo(480));
      
      // Verify all essential elements are visible within 480px height bounds
      final appBar = find.byType(AppBar);
      final appBarRect = tester.getRect(appBar);
      expect(appBarRect.top, greaterThanOrEqualTo(0));
      expect(appBarRect.bottom, lessThanOrEqualTo(480));
      
      final progressDisplay = find.byType(ProgressDisplay);
      final progressRect = tester.getRect(progressDisplay);
      expect(progressRect.top, greaterThanOrEqualTo(0));
      expect(progressRect.bottom, lessThanOrEqualTo(480));
      
      final savingsButton = find.byType(SavingsButton);
      final buttonRect = tester.getRect(savingsButton);
      expect(buttonRect.top, greaterThanOrEqualTo(0));
      expect(buttonRect.bottom, lessThanOrEqualTo(480));
      
      // Verify button text is within bounds
      final buttonText = find.text('터치해서 ₩1,000 저축하기');
      final textRect = tester.getRect(buttonText);
      expect(textRect.top, greaterThanOrEqualTo(0));
      expect(textRect.bottom, lessThanOrEqualTo(480));
      
      // Check for potential scrolling - V1 should fit without scrolling too
      final scrollView = find.byType(SingleChildScrollView);
      if (scrollView.evaluate().isNotEmpty) {
        final scrollWidget = tester.widget<SingleChildScrollView>(scrollView);
        // If scrolling is present, it should be minimal or disabled for small screens
        expect(scrollWidget.physics, anyOf(
          isA<NeverScrollableScrollPhysics>(),
          isA<ClampingScrollPhysics>(),
        ));
      }
    });

    testWidgets('should maintain proper element order and spacing on small screen', (WidgetTester tester) async {
      // Test on 800x480 screen size
      await tester.binding.setSurfaceSize(const Size(800, 480));
      
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
            child: HomeScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find all major elements
      final appBar = find.byType(AppBar);
      final progressDisplay = find.byType(ProgressDisplay);
      final savingsButton = find.byType(SavingsButton);
      final buttonText = find.text('터치해서 ₩1,000 저축하기');
      
      // Get their positions
      final appBarRect = tester.getRect(appBar);
      final progressRect = tester.getRect(progressDisplay);
      final buttonRect = tester.getRect(savingsButton);
      final textRect = tester.getRect(buttonText);
      
      // Verify proper vertical order: appbar -> progress -> button -> text
      expect(appBarRect.bottom, lessThanOrEqualTo(progressRect.top));
      expect(progressRect.bottom, lessThanOrEqualTo(buttonRect.top));
      expect(buttonRect.bottom, lessThanOrEqualTo(textRect.top));
      
      // Verify reasonable spacing between elements (should be optimized for small screen)
      expect(progressRect.top - appBarRect.bottom, greaterThan(5)); // Reduced spacing
      expect(buttonRect.top - progressRect.bottom, greaterThan(10)); // Reduced spacing
      expect(textRect.top - buttonRect.bottom, greaterThan(5)); // Reduced spacing
    });

    testWidgets('should maintain V1 design principles on small screens (AppBar, full layout)', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      
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
            child: HomeScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify V1 design characteristics are maintained at small screen size
      
      // AppBar present (V1 design principle)
      expect(find.byType(AppBar), findsOneWidget);
      
      // Full progress display (not simplified like V2)
      expect(find.byType(ProgressDisplay), findsOneWidget);
      
      // Savings button present
      expect(find.byType(SavingsButton), findsOneWidget);
      
      // Button text label present (V1 design)
      expect(find.text('터치해서 ₩1,000 저축하기'), findsOneWidget);
      
      // AppBar should have reasonable height even on small screen
      final appBar = find.byType(AppBar);
      final appBarRect = tester.getRect(appBar);
      expect(appBarRect.height, greaterThan(30)); // Minimum usable height
      expect(appBarRect.height, lessThan(100)); // Not too large on small screen
      
      // Verify app title is present in AppBar
      expect(find.text('One-Touch Savings'), findsOneWidget);
    });

    testWidgets('should handle various card layouts properly on small screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      
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
            child: HomeScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // V1 typically uses multiple cards/containers for statistics
      // Verify they fit within the small screen bounds
      final cards = find.byType(Card);
      
      for (final card in cards.evaluate()) {
        final cardRect = tester.getRect(find.byWidget(card.widget));
        expect(cardRect.top, greaterThanOrEqualTo(0));
        expect(cardRect.bottom, lessThanOrEqualTo(480));
        expect(cardRect.left, greaterThanOrEqualTo(0));
        expect(cardRect.right, lessThanOrEqualTo(800));
      }
      
      // Check for any container widgets that might contain stats
      final containers = find.byType(Container);
      
      for (final container in containers.evaluate()) {
        final containerWidget = container.widget as Container;
        // Skip containers that are clearly decorative (no meaningful constraints)
        if (containerWidget.constraints != null) {
          final containerRect = tester.getRect(find.byWidget(containerWidget));
          expect(containerRect.top, greaterThanOrEqualTo(0));
          expect(containerRect.bottom, lessThanOrEqualTo(480));
        }
      }
    });
  });
}