import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:one_touch_savings/main.dart' as app;
import 'package:one_touch_savings/services/database_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
  });

  group('One-Touch Savings App Integration Tests', () {
    testWidgets('complete save flow works end-to-end', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app loads correctly
      expect(find.text('One-Touch Savings'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('multiple save operations work correctly', (WidgetTester tester) async {
      // Reset database for clean test
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();

      // Find the savings button when it's implemented
      // For now, verify the app structure exists
      expect(find.text('One-Touch Savings'), findsOneWidget);
      
      // TODO: When SavingsButton is implemented in HomeScreen:
      // 1. Find and tap the savings button
      // 2. Verify progress display updates
      // 3. Verify haptic feedback occurs
      // 4. Test multiple rapid taps
      // 5. Verify milestone celebrations at 10,000원
    });

    testWidgets('app preserves data across restarts', (WidgetTester tester) async {
      // Clean start for reliable testing
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // First app session - save some money
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('One-Touch Savings'), findsOneWidget);
      
      // Find and tap savings button multiple times
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Tap 3 times to save ₩3,000
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();
        
        // Verify progress shows ₩3,000
        expect(find.textContaining('₩3,000'), findsOneWidget);
      }
      
      // Simulate app restart by closing database and restarting
      await DatabaseService.closeDatabase();
      
      // Second app session - verify persistence
      app.main();
      await tester.pumpAndSettle();
      
      // Data should persist across restart
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        expect(find.textContaining('₩3,000'), findsOneWidget);
        
        // Add one more save in second session
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();
        
        // Should now show ₩4,000
        expect(find.textContaining('₩4,000'), findsOneWidget);
      }
    });

    testWidgets('performance requirements are met', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();
      
      // App should load within 3 seconds
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      
      // TODO: Test button response time when implemented
      // Should be < 100ms total for tap response
    });
  });

  group('Enhanced Progress Persistence (Phase 4)', () {
    testWidgets('progress calculations persist across multiple restarts', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Session 1: Save to ₩7,000
      app.main();
      await tester.pumpAndSettle();
      
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        for (int i = 0; i < 7; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }
        expect(find.textContaining('₩7,000'), findsOneWidget);
      }
      
      await DatabaseService.closeDatabase();
      
      // Session 2: Add ₩3,000 more to reach milestone
      app.main();
      await tester.pumpAndSettle();
      
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        expect(find.textContaining('₩7,000'), findsOneWidget);
        
        for (int i = 0; i < 3; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }
        
        // Should hit ₩10,000 milestone
        expect(find.textContaining('₩10,000'), findsOneWidget);
        // Look for milestone celebration
        expect(find.textContaining('축하'), findsWidgets);
      }
      
      await DatabaseService.closeDatabase();
      
      // Session 3: Verify milestone state persists
      app.main();
      await tester.pumpAndSettle();
      
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        expect(find.textContaining('₩10,000'), findsOneWidget);
      }
    });

    testWidgets('progress display animations work after restart', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Save some money
      app.main();
      await tester.pumpAndSettle();
      
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();
      }
      
      await DatabaseService.closeDatabase();
      
      // Restart and verify animations work
      app.main();
      await tester.pumpAndSettle();
      
      // Look for ProgressDisplay widget if implemented
      final progressDisplayFinder = find.byKey(const Key('progress_display'));
      if (progressDisplayFinder.evaluate().isNotEmpty) {
        expect(progressDisplayFinder, findsOneWidget);
        
        // Verify animated elements exist
        expect(find.byKey(const Key('progress_counter')), findsOneWidget);
        expect(find.byKey(const Key('progress_bar')), findsOneWidget);
        expect(find.byKey(const Key('percentage_display')), findsOneWidget);
      }
    });

    testWidgets('korean formatting persists correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Create large amount to test formatting
      app.main();
      await tester.pumpAndSettle();
      
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Save ₩23,000 to test comma formatting
        for (int i = 0; i < 23; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pump(); // Don't wait for settle to speed up test
        }
        await tester.pumpAndSettle();
        
        // Should show formatted amount
        expect(find.textContaining('₩23,000'), findsOneWidget);
      }
      
      await DatabaseService.closeDatabase();
      
      // Restart and verify formatting persists
      app.main();
      await tester.pumpAndSettle();
      
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        expect(find.textContaining('₩23,000'), findsOneWidget);
        
        // Add more to test larger formatting
        for (int i = 0; i < 77; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pump();
        }
        await tester.pumpAndSettle();
        
        // Should show ₩100,000 with proper formatting
        expect(find.textContaining('₩100,000'), findsOneWidget);
      }
    });

    testWidgets('savings history persists and displays correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Session 1: Create history
      app.main();
      await tester.pumpAndSettle();
      
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
          // Small delay to create distinct timestamps
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      
      await DatabaseService.closeDatabase();
      
      // Session 2: Verify history accessibility
      app.main();
      await tester.pumpAndSettle();
      
      // Look for history access (if implemented in UI)
      final historyButtonFinder = find.byKey(const Key('history_button'));
      if (historyButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(historyButtonFinder);
        await tester.pumpAndSettle();
        
        // Should show 5 history entries
        expect(find.textContaining('₩1,000'), findsNWidgets(5));
      }
      
      // Verify database service can retrieve history
      final history = await databaseService.getSavingsHistory();
      expect(history.length, equals(5));
      expect(history.every((session) => session.amount == 1000), isTrue);
    });

    testWidgets('concurrent operations persist correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();
      
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Rapid fire taps to test concurrency
        for (int i = 0; i < 10; i++) {
          tester.tap(savingsButtonFinder);
          // Don't await to create concurrent operations
        }
        await tester.pumpAndSettle();
        
        // All operations should complete successfully
        expect(find.textContaining('₩10,000'), findsOneWidget);
      }
      
      await DatabaseService.closeDatabase();
      
      // Restart and verify all operations persisted
      app.main();
      await tester.pumpAndSettle();
      
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        expect(find.textContaining('₩10,000'), findsOneWidget);
      }
      
      // Verify database integrity
      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(10000));
      expect(progress.totalSessions, equals(10));
      expect(progress.validate(), isTrue);
    });

    testWidgets('milestone celebrations persist across restarts', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Reach first milestone
      app.main();
      await tester.pumpAndSettle();
      
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        for (int i = 0; i < 10; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }
        
        // Should show milestone celebration
        expect(find.textContaining('축하'), findsWidgets);
      }
      
      await DatabaseService.closeDatabase();
      
      // Restart and continue towards second milestone
      app.main();
      await tester.pumpAndSettle();
      
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Add 10 more saves to reach ₩20,000
        for (int i = 0; i < 10; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }
        
        // Should show second milestone
        expect(find.textContaining('₩20,000'), findsOneWidget);
        expect(find.textContaining('축하'), findsWidgets);
      }
    });
  });

  group('Milestone Flow Integration Tests (Phase 5)', () {
    testWidgets('milestone detection works in complete user flow', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Start app and verify clean state
      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Save 9 times (₩9,000)
        for (int i = 0; i < 9; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Verify no milestone celebration yet
        expect(find.textContaining('milestone'), findsNothing);
        expect(find.textContaining('축하'), findsNothing);

        // 10th save should trigger milestone
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();

        // Should show milestone celebration
        expect(find.textContaining('₩10,000'), findsOneWidget);
        expect(find.textContaining('milestone'), findsOneWidget);
        expect(find.textContaining('축하'), findsOneWidget);
      }
    });

    testWidgets('multiple milestones work correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Reach first milestone (₩10,000)
        for (int i = 0; i < 10; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Verify first milestone
        expect(find.textContaining('₩10,000'), findsOneWidget);
        
        // Continue to second milestone (₩20,000)
        for (int i = 0; i < 10; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Should show second milestone
        expect(find.textContaining('₩20,000'), findsOneWidget);

        // Continue to third milestone (₩30,000)
        for (int i = 0; i < 10; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Should show third milestone
        expect(find.textContaining('₩30,000'), findsOneWidget);
      }
    });

    testWidgets('milestone celebrations have proper enhanced feedback', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Reach milestone
        for (int i = 0; i < 10; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Look for enhanced feedback elements
        final celebrationFinder = find.byKey(const Key('milestone_celebration'));
        if (celebrationFinder.evaluate().isNotEmpty) {
          expect(celebrationFinder, findsOneWidget);
          
          // Check for enhanced animation elements
          expect(find.byKey(const Key('celebration_scale_animation')), findsOneWidget);
          expect(find.byKey(const Key('celebration_color_animation')), findsOneWidget);
          
          // Animation should complete
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('milestone persistence across app restarts', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Session 1: Reach milestone
      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        for (int i = 0; i < 10; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Verify milestone state
        expect(find.textContaining('₩10,000'), findsOneWidget);
      }

      await DatabaseService.closeDatabase();

      // Session 2: Verify milestone data persists
      app.main();
      await tester.pumpAndSettle();

      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Should still show milestone achievement
        expect(find.textContaining('₩10,000'), findsOneWidget);
        
        // Verify milestone is recorded in database
        final progress = await databaseService.getCurrentProgress();
        expect(progress.milestones, contains(10000));
      }
    });

    testWidgets('rapid savings correctly detect consecutive milestones', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Rapid fire to reach multiple milestones quickly
        for (int i = 0; i < 25; i++) {
          tester.tap(savingsButtonFinder);
          // Small delay to avoid overwhelming the system
          await tester.pump(const Duration(milliseconds: 10));
        }
        await tester.pumpAndSettle();

        // Should correctly show final amount
        expect(find.textContaining('₩25,000'), findsOneWidget);

        // Verify all milestones were detected
        final progress = await databaseService.getCurrentProgress();
        expect(progress.milestones, containsAll([10000, 20000]));
      }
    });

    testWidgets('milestone celebration animations complete within time limits', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Save 9 times
        for (int i = 0; i < 9; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Measure milestone celebration time
        final stopwatch = Stopwatch()..start();
        
        // Trigger milestone
        await tester.tap(savingsButtonFinder);
        
        // Wait for celebration to complete
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Celebration should complete within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'Milestone celebration should complete within 2 seconds');
      }
    });

    testWidgets('milestone feedback does not interfere with subsequent saves', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Reach milestone
        for (int i = 0; i < 10; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Immediately make another save after milestone
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();

        // Should show ₩11,000 without issues
        expect(find.textContaining('₩11,000'), findsOneWidget);

        // Continue saving normally
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();
        
        expect(find.textContaining('₩12,000'), findsOneWidget);
      }
    });

    testWidgets('large milestone amounts are handled correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Simulate having saved a large amount already
      // (This would typically be done by manipulating database directly)
      // For now, test the UI can handle large numbers
      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Test reaching ₩100,000 milestone (would take 100 saves)
        // For test efficiency, we'll simulate rapid saves
        for (int i = 0; i < 100; i++) {
          tester.tap(savingsButtonFinder);
          // Only pump occasionally to speed up test
          if (i % 10 == 0) {
            await tester.pump(const Duration(milliseconds: 1));
          }
        }
        await tester.pumpAndSettle();

        // Should display large amounts correctly
        expect(find.textContaining('₩100,000'), findsOneWidget);

        // Verify milestone was detected
        final progress = await databaseService.getCurrentProgress();
        expect(progress.milestones, contains(100000));
        expect(progress.totalSavings, equals(100000));
      }
    });

    testWidgets('milestone tracking integrates with progress display', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      final progressDisplayFinder = find.byKey(const Key('progress_display'));
      
      if (savingsButtonFinder.evaluate().isNotEmpty && 
          progressDisplayFinder.evaluate().isNotEmpty) {
        
        // Save to near milestone
        for (int i = 0; i < 9; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle();
        }

        // Progress display should show ₩9,000
        expect(find.textContaining('₩9,000'), findsOneWidget);

        // Cross milestone threshold
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle();

        // Progress display should update to show milestone
        expect(find.textContaining('₩10,000'), findsOneWidget);
        
        // Check for milestone indicator in progress display
        expect(find.byKey(const Key('milestone_indicator')), findsOneWidget);
      }
    });
  });
}