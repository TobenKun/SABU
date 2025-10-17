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
    DatabaseService.useCustomTestDatabase('test_db_widget_v2_$timestamp.db');
  });

  tearDownAll(() async {
    // Restore normal database after tests
    DatabaseService.useNormalDatabase();
  });

  group('HomeScreenV2 Widget Tests', () {
    testWidgets('should display minimal V2 UI only', (WidgetTester tester) async {
      // Pump the HomeScreenV2 widget
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );
      
      // Wait for the widget to settle
      await tester.pumpAndSettle();
      
      // Verify essential V2 elements are present
      expect(find.byType(SimplifiedProgressDisplay), findsOneWidget);
      expect(find.byType(SavingsButton), findsOneWidget);
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget); // Animated turtle
      expect(find.byType(UsageStatsCard), findsOneWidget); // V2 stats card
      
      // Verify stats are displayed in a single card (V2 approach) not individual cards (V1 approach)
      // In V2, stats are in one UsageStatsCard, not separate individual Card widgets
      expect(find.byType(Card), findsNothing); // V1 uses multiple Card widgets for stats
      
      // Verify stats text is present but in the unified stats card
      expect(find.text('오늘'), findsOneWidget); // In UsageStatsCard
      expect(find.text('총 저축'), findsOneWidget); // In UsageStatsCard  
      expect(find.text('연속 기록'), findsOneWidget); // In UsageStatsCard
      
      // The blue progress message container should not be present (V1 specific)
      // This is specifically looking for the V1 progress message container with blue background and border
      final progressMessageContainers = find.byWidgetPredicate((widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color != null &&
        (widget.decoration as BoxDecoration).color.toString().contains('blue') &&
        (widget.decoration as BoxDecoration).border != null &&
        widget.padding == const EdgeInsets.all(16) // V1 progress message container has specific padding
      );
      expect(progressMessageContainers, findsNothing);
    });
    
    testWidgets('should display turtle sprite above savings button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );
      
      // Wait for the widget to settle
      await tester.pumpAndSettle();
      
      // Find the animated turtle sprite and savings button
      final turtleSprite = find.byType(AnimatedTurtleSprite);
      final savingsButton = find.byType(SavingsButton);
      
      expect(turtleSprite, findsOneWidget);
      expect(savingsButton, findsOneWidget);
      
      // Verify turtle is positioned above the button (lower y coordinate)
      final turtleRect = tester.getRect(turtleSprite);
      final buttonRect = tester.getRect(savingsButton);
      
      expect(turtleRect.bottom, lessThanOrEqualTo(buttonRect.top));
    });
    
    testWidgets('should display progress information with current amount only', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );
      
      // Wait for the widget to settle
      await tester.pumpAndSettle();
      
      // Verify SimplifiedProgressDisplay is present
      expect(find.byType(SimplifiedProgressDisplay), findsOneWidget);
      
      // Verify UsageStatsCard is present (contains the detailed stats)
      expect(find.byType(UsageStatsCard), findsOneWidget);
      
      // Find the simplified progress display widget
      final simplifiedProgressDisplay = tester.widget<SimplifiedProgressDisplay>(find.byType(SimplifiedProgressDisplay));
      
      // After database initialization, the screen should show default values
      expect(simplifiedProgressDisplay.currentAmount, equals(0)); // Default value
      expect(simplifiedProgressDisplay.showAnimation, isFalse); // Changed: animation disabled in current implementation
    });
    
    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreenV2(),
        ),
      );
      
      // Wait for the widget to settle
      await tester.pumpAndSettle();
      
      // Verify main structural elements
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      
      // Verify scrollable layout with proper constraints for center alignment
      expect(find.byType(SingleChildScrollView), findsOneWidget,
          reason: 'Regular screen should use scrollable layout for overflow safety');
      
      // Look for our specific ConstrainedBox with the minHeight constraint pattern
      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes, findsAtLeastNWidgets(1),
          reason: 'Should have ConstrainedBox widgets for layout constraints');
      
      expect(find.byType(IntrinsicHeight), findsOneWidget,
          reason: 'Should use IntrinsicHeight for proper sizing');
    });
  });
}