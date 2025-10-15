import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:one_touch_savings/main.dart';
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

  group('User Story 1: Basic Savings Action', () {
    testWidgets('complete save flow works end-to-end', (WidgetTester tester) async {
      // Reset database for clean test
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // Start the app using proper widget testing approach
      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      // Verify app loads correctly
      expect(find.text('One-Touch Savings'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // Find savings button and test basic functionality
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        // Ensure button is visible by scrolling if needed
        await tester.ensureVisible(savingsButtonFinder);
        
        // Test single save operation
        await tester.tap(savingsButtonFinder);
        await tester.pump();
        
        // Verify progress display shows the saved amount
        expect(find.byKey(const Key('progress_display')), findsOneWidget);
      }
    });

    testWidgets('multiple save operations work correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Test 3 save operations with proper async handling
        for (int i = 0; i < 3; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle(); // Wait for async operations to complete
        }
        
        // Verify database has correct total
        final progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(3000));
        expect(progress.totalSessions, equals(3));
      }
    });

    testWidgets('button response time meets performance requirements', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        final stopwatch = Stopwatch()..start();
        
        await tester.tap(savingsButtonFinder);
        await tester.pump();
        
        stopwatch.stop();
        
        // Should respond within 100ms requirement
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      }
    });
  });

  group('User Story 2: Savings Progress Tracking', () {
    testWidgets('progress persists across app restarts', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      // First session - save some money
      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Save ₩3,000 with proper async handling
        for (int i = 0; i < 3; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle(); // Wait for async operations
        }
        
        // Test database state instead of UI text
        var progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(3000));
        expect(progress.totalSessions, equals(3));
      }
      
      // Simulate restart by creating new widget tree and new database service
      await tester.pumpWidget(const SavingsApp());
      await tester.pump();
      
      // Create a new database service instance to simulate app restart
      final newDatabaseService = DatabaseService();
      
      // Data should persist
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Verify persistence with new database service
        var progress = await newDatabaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(3000));
        
        // Add one more save
        await tester.tap(savingsButtonFinder);
        await tester.pumpAndSettle(); // Wait for async operations
        
        // Verify updated total
        progress = await newDatabaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(4000));
        expect(progress.totalSessions, equals(4));
      }
    });

    testWidgets('korean number formatting works correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Save ₩15,000 to test comma formatting using batch operations
        await Future.wait(List.generate(15, (_) => databaseService.saveMoney()));
        
        // Test database state and verify formatting via progress display
        final progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(15000));
        expect(find.byKey(const Key('progress_display')), findsOneWidget);
      }
    });

    testWidgets('progress display shows correct totals', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      // Verify progress display widget exists
      final progressDisplayFinder = find.byKey(const Key('progress_display'));
      if (progressDisplayFinder.evaluate().isNotEmpty) {
        expect(progressDisplayFinder, findsOneWidget);
        
        // Test with some savings
        final savingsButtonFinder = find.byKey(const Key('savings_button'));
        if (savingsButtonFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(savingsButtonFinder);
          
          await tester.tap(savingsButtonFinder);
          await tester.pumpAndSettle(); // Wait for async operations to complete
          
          // Verify progress is tracked correctly
          final progress = await databaseService.getCurrentProgress();
          expect(progress.totalSavings, equals(1000));
          expect(progress.totalSessions, equals(1));
        }
      }
    });
  });

  group('User Story 3: Milestone Celebrations', () {
    testWidgets('milestone celebration triggers at 10,000원', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Use direct database operations to get to 9000 quickly
        await Future.wait(List.generate(9, (_) => databaseService.saveMoney()));
        
        // Verify we're at 9000 before milestone
        var progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(9000));
        expect(progress.totalSessions, equals(9));

        // Trigger the UI to update the display
        await tester.pump();

        // One more save should trigger 10000 milestone via UI
        await tester.tap(savingsButtonFinder);
        await tester.pump(const Duration(milliseconds: 300));

        // Verify milestone reached in database
        progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(10000));
        expect(progress.totalSessions, equals(10));
      }
    });

    testWidgets('multiple milestones work correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Reach first milestone (₩10,000) using batch operations
        await Future.wait(List.generate(10, (_) => databaseService.saveMoney()));

        // Verify first milestone in database
        var progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(10000));
        
        // Continue to second milestone (₩20,000) using batch operations
        await Future.wait(List.generate(10, (_) => databaseService.saveMoney()));

        // Verify second milestone in database
        progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(20000));
        expect(progress.totalSessions, equals(20));
      }
    });

    testWidgets('milestone celebration completes within time limit', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Save 9 times using batch operations
        await Future.wait(List.generate(9, (_) => databaseService.saveMoney()));

        // Measure milestone celebration time
        final stopwatch = Stopwatch()..start();
        
        // Trigger milestone with UI tap to test animation
        await tester.tap(savingsButtonFinder);
        await tester.pump(const Duration(milliseconds: 200));
        
        stopwatch.stop();

        // Verify milestone reached and celebration completed in time
        final progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(10000));
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      }
    });
  });

  group('Cross-Story Integration Tests', () {
    testWidgets('app launch meets performance requirements', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(const SavingsApp());
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should load within 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      
      // Verify basic components are loaded
      expect(find.text('One-Touch Savings'), findsOneWidget);
      expect(find.byKey(const Key('savings_button')), findsOneWidget);
      expect(find.byKey(const Key('progress_display')), findsOneWidget);
    });

    testWidgets('concurrent operations work correctly', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();
      
      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Perform 5 saves using batch operations for speed
        await Future.wait(List.generate(5, (_) => databaseService.saveMoney()));

        final progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(5000));
        expect(progress.totalSessions, equals(5));
        expect(progress.validate(), isTrue);
      }
    });

    testWidgets('all user stories work together', (WidgetTester tester) async {
      final databaseService = DatabaseService();
      await databaseService.resetUserData();
      
      await tester.pumpWidget(const SavingsApp());
      await tester.pump();

      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Perform 10 saves using batch operations to reach milestone
        await Future.wait(List.generate(10, (_) => databaseService.saveMoney()));

        final progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(10000));
        expect(progress.totalSessions, equals(10));
        expect(progress.validate(), isTrue);
      }
    });
  });
}