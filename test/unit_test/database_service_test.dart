import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/services/database_service.dart';
import '../../lib/models/user_progress.dart';
import '../../lib/models/savings_result.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.useTestDatabase(); // Use in-memory database for tests
  });

  setUp(() {
    databaseService = DatabaseService();
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
  });

  setUp(() {
    databaseService = DatabaseService();
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    // Clear the static database instance to force fresh DB for each test
    await Future.delayed(Duration(milliseconds: 10));
  });

  group('DatabaseService', () {
    test('should save money and return success result', () async {
      final result = await databaseService.saveMoney();
      
      expect(result.success, isTrue);
      expect(result.newTotal, equals(1000));
      expect(result.todayCount, equals(1));
      expect(result.milestonesHit, isEmpty);
      expect(result.error, isNull);
    });

    test('should update progress correctly after multiple saves', () async {
      // Save money three times
      await databaseService.saveMoney();
      await databaseService.saveMoney();
      final result = await databaseService.saveMoney();
      
      expect(result.newTotal, equals(3000));
      expect(result.todayCount, equals(3));
      
      // Verify progress is consistent
      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(3000));
      expect(progress.totalSessions, equals(3));
      expect(progress.todaySessionCount, equals(3));
    });

    test('should detect milestone at 10,000원', () async {
      // Save enough to reach first milestone
      for (int i = 0; i < 10; i++) {
        final result = await databaseService.saveMoney();
        if (i == 9) { // 10th save = 10,000원
          expect(result.milestonesHit, contains(10000));
        } else {
          expect(result.milestonesHit, isEmpty);
        }
      }
    });

    test('should handle rapid consecutive saves', () async {
      final futures = List.generate(5, (index) => databaseService.saveMoney());
      final results = await Future.wait(futures);
      
      // All saves should succeed
      for (final result in results) {
        expect(result.success, isTrue);
      }
      
      // Final total should be correct
      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(5000));
      expect(progress.totalSessions, equals(5));
    });

    test('should return empty progress for new database', () async {
      final progress = await databaseService.getCurrentProgress();
      
      expect(progress.totalSavings, equals(0));
      expect(progress.totalSessions, equals(0));
      expect(progress.todaySessionCount, equals(0));
      expect(progress.currentStreak, equals(0));
      expect(progress.longestStreak, equals(0));
      expect(progress.milestones, isEmpty);
    });

    test('should get savings history correctly', () async {
      // Create some test data
      await databaseService.saveMoney();
      await databaseService.saveMoney();
      await databaseService.saveMoney();
      
      final history = await databaseService.getSavingsHistory(limit: 10);
      
      expect(history.length, equals(3));
      expect(history.first.amount, equals(1000));
      
      // Should be in descending order by timestamp
      expect(history[0].timestamp.isAfter(history[1].timestamp), isTrue);
      expect(history[1].timestamp.isAfter(history[2].timestamp), isTrue);
    });

    test('should reset user data completely', () async {
      // Create some data
      await databaseService.saveMoney();
      await databaseService.saveMoney();
      
      // Reset
      await databaseService.resetUserData();
      
      // Verify reset
      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(0));
      expect(progress.totalSessions, equals(0));
      
      final history = await databaseService.getSavingsHistory();
      expect(history, isEmpty);
    });

    test('should maintain data integrity under stress', () async {
      const int iterations = 100;
      
      // Perform many saves
      for (int i = 0; i < iterations; i++) {
        final result = await databaseService.saveMoney();
        expect(result.success, isTrue);
      }
      
      // Verify final state
      final progress = await databaseService.getCurrentProgress();
      expect(progress.totalSavings, equals(iterations * 1000));
      expect(progress.totalSessions, equals(iterations));
      expect(progress.validate(), isTrue);
    });

    group('Enhanced Progress Calculations (Phase 4)', () {
      test('should calculate progress percentages correctly', () async {
        // Test milestone progress calculations
        await databaseService.saveMoney(); // 1000
        await databaseService.saveMoney(); // 2000
        await databaseService.saveMoney(); // 3000
        
        final progress = await databaseService.getCurrentProgress();
        
        // Progress towards 10,000 milestone should be 30%
        final percentageToFirstMilestone = (progress.totalSavings / 10000) * 100;
        expect(percentageToFirstMilestone, equals(30.0));
        
        // Remaining amount to first milestone should be 7000
        final remainingToMilestone = 10000 - progress.totalSavings;
        expect(remainingToMilestone, equals(7000));
      });

      test('should track savings history with detailed analytics', () async {
        // Create test data with specific timestamps
        await databaseService.saveMoney();
        await Future.delayed(Duration(milliseconds: 100));
        await databaseService.saveMoney();
        await Future.delayed(Duration(milliseconds: 100));
        await databaseService.saveMoney();
        
        final history = await databaseService.getSavingsHistory();
        
        expect(history.length, equals(3));
        expect(history.every((session) => session.amount == 1000), isTrue);
        
        // Verify cumulative calculations
        int cumulativeTotal = 0;
        for (int i = history.length - 1; i >= 0; i--) {
          cumulativeTotal += history[i].amount;
          // Each save should contribute to growing total
          expect(cumulativeTotal, equals((history.length - i) * 1000));
        }
      });

      test('should handle date-filtered history queries', () async {
        final now = DateTime.now();
        final yesterday = now.subtract(Duration(days: 1));
        final tomorrow = now.add(Duration(days: 1));
        
        // Create saves
        await databaseService.saveMoney();
        await databaseService.saveMoney();
        
        // Test date range filtering
        final todayHistory = await databaseService.getSavingsHistory(
          startDate: yesterday,
          endDate: tomorrow,
        );
        
        expect(todayHistory.length, equals(2));
        
        // Test future date (should be empty)
        final futureHistory = await databaseService.getSavingsHistory(
          startDate: tomorrow,
        );
        
        expect(futureHistory, isEmpty);
      });

      test('should persist calculation state across database sessions', () async {
        // First session - save money
        await databaseService.saveMoney();
        await databaseService.saveMoney();
        
        final firstProgress = await databaseService.getCurrentProgress();
        expect(firstProgress.totalSavings, equals(2000));
        
        // Simulate app restart by closing and reopening database
        await DatabaseService.closeDatabase();
        
        // Second session - verify persistence
        final secondProgress = await databaseService.getCurrentProgress();
        expect(secondProgress.totalSavings, equals(2000));
        expect(secondProgress.totalSessions, equals(2));
        
        // Add more saves in second session
        await databaseService.saveMoney();
        
        final finalProgress = await databaseService.getCurrentProgress();
        expect(finalProgress.totalSavings, equals(3000));
        expect(finalProgress.totalSessions, equals(3));
      });

      test('should calculate accurate session averages and trends', () async {
        // Create varying session data
        for (int i = 0; i < 15; i++) {
          await databaseService.saveMoney();
        }
        
        final progress = await databaseService.getCurrentProgress();
        final history = await databaseService.getSavingsHistory();
        
        // Verify total calculations
        expect(progress.totalSavings, equals(15000));
        expect(history.length, equals(15));
        
        // Average per session should always be 1000 (fixed amount)
        final averagePerSession = progress.totalSavings / progress.totalSessions;
        expect(averagePerSession, equals(1000.0));
        
        // Verify milestone detection at 10k
        expect(progress.totalSavings, greaterThan(10000));
        final milestonesReached = (progress.totalSavings / 10000).floor();
        expect(milestonesReached, equals(1)); // Should have hit 10k milestone
      });

      test('should handle concurrent progress calculations safely', () async {
        // Test race conditions in progress updates
        final futures = List.generate(20, (index) async {
          await Future.delayed(Duration(milliseconds: index * 10));
          return await databaseService.saveMoney();
        });
        
        final results = await Future.wait(futures);
        
        // All saves should succeed
        expect(results.every((r) => r.success), isTrue);
        
        // Final state should be consistent
        final progress = await databaseService.getCurrentProgress();
        expect(progress.totalSavings, equals(20000));
        expect(progress.totalSessions, equals(20));
        
        // History should match
        final history = await databaseService.getSavingsHistory();
        expect(history.length, equals(20));
      });
    });
  });
}