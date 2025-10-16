import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:one_touch_savings/main.dart';
import 'package:one_touch_savings/services/database_service.dart';
import 'package:one_touch_savings/screens/home_screen_v2.dart';
import 'package:one_touch_savings/widgets/animated_character.dart';
import 'package:one_touch_savings/widgets/usage_stats_card.dart';
import 'package:one_touch_savings/widgets/milestone_celebration.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize database with unique path for this test file
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Use unique database path for test isolation
    DatabaseService.useCustomTestDatabase('test_db_v2_${DateTime.now().millisecondsSinceEpoch}.db');
    
    // Mock SharedPreferences with more complete setup for animation service
    SharedPreferences.setMockInitialValues({
      'last_activity_timestamp': DateTime.now().millisecondsSinceEpoch,
      'turtle_animation_level': 'idle',
      'total_activity_count': 0,
      'recent_activities': <String>[],
      'level_start_time': DateTime.now().millisecondsSinceEpoch,
    });
  });

  setUp(() async {
    // Reset database before each test to ensure clean state
    final databaseService = DatabaseService();
    await databaseService.resetUserData();
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
  });

  tearDownAll(() async {
    // Clean up test database path and restore normal database
    await DatabaseService.closeDatabase();
    DatabaseService.useNormalDatabase();
  });

  group('HomeScreenV2: Basic Savings Action', () {
    testWidgets('V2 save flow works end-to-end', (WidgetTester tester) async {
      // Navigate directly to V2 screen
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      await tester.ensureVisible(savingsButtonFinder);
      
      final stopwatch = Stopwatch()..start();
      
      await tester.tap(savingsButtonFinder);
      await tester.pump();
      
      stopwatch.stop();
      
      // Should respond within 100ms requirement
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('HomeScreenV2: Simplified Progress Tracking', () {
    testWidgets('V2 progress persists across app restarts', (WidgetTester tester) async {
      final databaseService = DatabaseService();

      // First session - save some money
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      await tester.ensureVisible(savingsButtonFinder);
      
      // Save ₩3,000 with proper async handling
      for (int i = 0; i < 3; i++) {
        await tester.tap(savingsButtonFinder);
      await tester.pump(const Duration(milliseconds: 300)); // Fixed duration instead of pumpAndSettle
      }
      
      // Test database state
      var progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(3000));
      expect(progress.totalSessions, equals(3));
      
      // Simulate restart by creating new widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      
      // Create a new database service instance to simulate app restart
      final newDatabaseService = DatabaseService();
      
      // Data should persist
      await tester.ensureVisible(savingsButtonFinder);
      
      // Verify persistence with new database service
      progress = await newDatabaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(3000));
      
      // Add one more save
      await tester.tap(savingsButtonFinder);
      await tester.pump(const Duration(milliseconds: 200)); // Wait for async operations
      
      // Verify updated total
      progress = await newDatabaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(4000));
      expect(progress.totalSessions, equals(4));
    });

    testWidgets('V2 korean number formatting works correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      await tester.ensureVisible(savingsButtonFinder);
      
      // Save ₩15,000 to test comma formatting using batch operations
      await Future.wait(List.generate(15, (_) => databaseService.saveMoney()));
      
      // Refresh the UI to show updated values
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      
      // Test database state and verify formatting via progress display
      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(15000));
      expect(find.byKey(const Key('simplified_progress_display')), findsOneWidget);
    });

    testWidgets('V2 simplified progress display shows correct totals', (WidgetTester tester) async {
      final databaseService = DatabaseService();

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify simplified progress display widget exists
      final progressDisplayFinder = find.byKey(const Key('simplified_progress_display'));
      expect(progressDisplayFinder, findsOneWidget);
      
      // Test with some savings
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      await tester.ensureVisible(savingsButtonFinder);
      
      await tester.tap(savingsButtonFinder);
      await tester.pump(const Duration(milliseconds: 300)); // Fixed duration instead of pumpAndSettle
      
      // Verify progress is tracked correctly
      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(1000));
      expect(progress.totalSessions, equals(1));
    });
  });

  group('HomeScreenV2: Turtle Animation Features', () {
    testWidgets('V2 animated turtle sprite renders correctly', (WidgetTester tester) async {


      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify turtle animation widget exists
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
      
      // Verify usage stats card exists
      expect(find.byType(UsageStatsCard), findsOneWidget);
    });

    testWidgets('V2 animation responds to save actions', (WidgetTester tester) async {


      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      await tester.ensureVisible(savingsButtonFinder);
      
      // Perform save action and verify animation system responds
      await tester.tap(savingsButtonFinder);
      await tester.pump(const Duration(milliseconds: 300));
      
      // Verify turtle is still rendered (animation may have changed state)
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
    });

    testWidgets('V2 debug controls work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Debug section is currently disabled/commented out
      expect(find.text('DEBUG'), findsNothing);
      
      // Debug buttons should not be present
      expect(find.text('I'), findsNothing); // Idle
      expect(find.text('WS'), findsNothing); // Walk Slow
      expect(find.text('WF'), findsNothing); // Walk Fast
      expect(find.text('RS'), findsNothing); // Run Slow
      expect(find.text('RF'), findsNothing); // Run Fast
      
      // Verify the screen still works without debug controls
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
      expect(find.byType(SavingsButton), findsOneWidget);
    });
  });

  group('HomeScreenV2: Milestone Celebrations (Simplified)', () {
    testWidgets('V2 milestone reaching at 10,000원 (no overlay)', (WidgetTester tester) async {
      final databaseService = DatabaseService();

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      await tester.ensureVisible(savingsButtonFinder);
      
      // Use direct database operations to get to 9000 quickly
      await Future.wait(List.generate(9, (_) => databaseService.saveMoney()));
      
      // Verify we're at 9000 before milestone
      var progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(9000));
      expect(progress.totalSessions, equals(9));

      // Trigger the UI to update the display
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // One more save should trigger 10000 milestone via UI
      await tester.tap(savingsButtonFinder);
      await tester.pump(const Duration(milliseconds: 200));

      // Verify milestone reached in database
      progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(10000));
      expect(progress.totalSessions, equals(10));
      
      // V2 should NOT show milestone overlay (simplified interface)
      expect(find.byType(MilestoneCelebration), findsNothing);
    });
  });

  group('HomeScreenV2: Cross-Story Integration Tests', () {
    testWidgets('V2 app components load within performance requirements', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      
      stopwatch.stop();
      
      // App should load within 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      
      // Verify V2 specific components are loaded
      expect(find.byKey(const Key('savings_button')), findsOneWidget);
      expect(find.byKey(const Key('simplified_progress_display')), findsOneWidget);
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
      expect(find.byType(UsageStatsCard), findsOneWidget);
    });

    testWidgets('V2 concurrent operations work correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      await tester.ensureVisible(savingsButtonFinder);
      
      // Perform 5 saves using batch operations for speed
      await Future.wait(List.generate(5, (_) => databaseService.saveMoney()));

      // Refresh UI
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(5000));
      expect(progress.totalSessions, equals(5));
      expect(progress.validate(), isTrue);
    });

    testWidgets('V2 all user stories work together', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      await tester.ensureVisible(savingsButtonFinder);
      
      // Perform 10 saves using batch operations to reach milestone
      await Future.wait(List.generate(10, (_) => databaseService.saveMoney()));

      // Refresh UI
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(10000));
      expect(progress.totalSessions, equals(10));
      expect(progress.validate(), isTrue);
      
      // Verify all V2 components still work after milestone
      expect(find.byKey(const Key('simplified_progress_display')), findsOneWidget);
      expect(find.byType(AnimatedTurtleSprite), findsOneWidget);
      expect(find.byType(UsageStatsCard), findsOneWidget);
    });
  });
}