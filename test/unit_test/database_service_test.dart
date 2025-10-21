import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:one_touch_savings/services/database_service.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Use unique database path for each test to ensure proper isolation
    await DatabaseService.closeDatabase();
    DatabaseService.useCustomTestDatabase(':memory:${DateTime.now().microsecondsSinceEpoch}');
    databaseService = DatabaseService();
    // Ensure database is fully initialized
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    // Properly close database connection
    await DatabaseService.closeDatabase();
    // Allow time for cleanup
    await Future.delayed(const Duration(milliseconds: 50));
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
      // Create some test data with guaranteed time gaps
      await databaseService.saveMoney();
      await Future.delayed(const Duration(milliseconds: 10));
      await databaseService.saveMoney();
      await Future.delayed(const Duration(milliseconds: 10));
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
      setUp(() async {
        // Ensure completely fresh database for each enhanced progress test
        await DatabaseService.closeDatabase();
        DatabaseService.useCustomTestDatabase(':memory:${DateTime.now().microsecondsSinceEpoch}');
        databaseService = DatabaseService();
        await Future.delayed(const Duration(milliseconds: 50));
      });
      
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
        await Future.delayed(const Duration(milliseconds: 100));
        await databaseService.saveMoney();
        await Future.delayed(const Duration(milliseconds: 100));
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
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));
        
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

      test('should persist calculation state during session', () async {
        // Test persistence within the same database session
        await databaseService.saveMoney();
        await databaseService.saveMoney();
        
        final firstProgress = await databaseService.getCurrentProgress();
        expect(firstProgress.totalSavings, equals(2000));
        
        // Add more saves in same session
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

    group('Streak Logic Tests', () {
      setUp(() async {
        // Ensure completely fresh database for each streak test
        await DatabaseService.closeDatabase();
        // Use unique database path for proper isolation
        DatabaseService.useCustomTestDatabase(':memory:${DateTime.now().millisecondsSinceEpoch}');
        databaseService = DatabaseService();
        await Future.delayed(const Duration(milliseconds: 50));
      });
      
      test('should show streak as 1 on first save', () async {
        final result = await databaseService.saveMoney();
        expect(result.success, isTrue);
        
        final progress = await databaseService.getCurrentProgress();
        expect(progress.currentStreak, equals(1));
        expect(progress.longestStreak, equals(1));
      });

      test('should maintain streak on same day saves', () async {
        await databaseService.saveMoney();
        final progress1 = await databaseService.getCurrentProgress();
        expect(progress1.currentStreak, equals(1));
        
        // Save again on same day
        await databaseService.saveMoney();
        final progress2 = await databaseService.getCurrentProgress();
        expect(progress2.currentStreak, equals(1)); // Should stay same
      });

      test('should increment streak on consecutive days', () async {
        // Simulate day 1 save
        await databaseService.saveMoney();
        final progress1 = await databaseService.getCurrentProgress();
        expect(progress1.currentStreak, equals(1));
        
        // Simulate day 2 save (modify last_save_date to yesterday for testing)
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await databaseService.database.then((db) async {
          await db.update('user_progress', 
            {'last_save_date': yesterday.millisecondsSinceEpoch},
            where: 'id = 1'
          );
        });
        
        await databaseService.saveMoney();
        final progress2 = await databaseService.getCurrentProgress();
        expect(progress2.currentStreak, equals(2));
        expect(progress2.longestStreak, equals(2));
      });

      test('should reset streak when gap exists', () async {
        // Save day 1
        await databaseService.saveMoney();
        
        // Simulate last save was 3 days ago
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        await databaseService.database.then((db) async {
          await db.update('user_progress', 
            {'last_save_date': threeDaysAgo.millisecondsSinceEpoch, 'current_streak': 5},
            where: 'id = 1'
          );
        });
        
        await databaseService.saveMoney();
        final progress = await databaseService.getCurrentProgress();
        expect(progress.currentStreak, equals(1)); // Should reset to 1
      });

      test('should validate current streak in real-time - never saved', () async {
        final validatedStreak = await DatabaseService.getValidatedCurrentStreak();
        expect(validatedStreak, equals(0)); // No saves yet
      });

      test('should validate current streak in real-time - saved today', () async {
        await databaseService.saveMoney();
        final validatedStreak = await DatabaseService.getValidatedCurrentStreak();
        expect(validatedStreak, equals(1)); // Saved today
      });

      test('should validate current streak in real-time - saved yesterday (streak continues)', () async {
        // Simulate save yesterday
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await databaseService.database.then((db) async {
          await db.update('user_progress', 
            {'last_save_date': yesterday.millisecondsSinceEpoch, 'current_streak': 3},
            where: 'id = 1'
          );
        });
        
        final validatedStreak = await DatabaseService.getValidatedCurrentStreak();
        expect(validatedStreak, equals(3)); // Can continue streak
      });

      test('should validate current streak in real-time - streak broken', () async {
        // Simulate save 3 days ago
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        await databaseService.database.then((db) async {
          await db.update('user_progress', 
            {'last_save_date': threeDaysAgo.millisecondsSinceEpoch, 'current_streak': 5},
            where: 'id = 1'
          );
        });
        
        final validatedStreak = await DatabaseService.getValidatedCurrentStreak();
        expect(validatedStreak, equals(0)); // Streak broken
      });

      test('should preserve longest streak when current streak resets', () async {
        // Simulate building a 5-day streak by manipulating the database state
        // Start with first save
        await databaseService.saveMoney();
        
        // Manually set up a 5-day streak state in the database
        await databaseService.database.then((db) async {
          await db.update('user_progress', 
            {
              'current_streak': 5,
              'longest_streak': 5,
              'last_save_date': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch
            },
            where: 'id = 1'
          );
        });
        
        // Verify the 5-day streak is set up
        final progress1 = await databaseService.getCurrentProgress();
        expect(progress1.currentStreak, equals(5));
        expect(progress1.longestStreak, equals(5));
        
        // Break streak by setting last save to 3 days ago and saving today
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        await databaseService.database.then((db) async {
          await db.update('user_progress', 
            {'last_save_date': threeDaysAgo.millisecondsSinceEpoch},
            where: 'id = 1'
          );
        });
        
        await databaseService.saveMoney();
        final progress2 = await databaseService.getCurrentProgress();
        expect(progress2.currentStreak, equals(1)); // Reset to 1
        expect(progress2.longestStreak, equals(5)); // Preserved
      });
    });
  });
}