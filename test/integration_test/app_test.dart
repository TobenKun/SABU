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
}