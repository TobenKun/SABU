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
  });
}