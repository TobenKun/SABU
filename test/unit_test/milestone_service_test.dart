import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:one_touch_savings/services/database_service.dart';

void main() {
  group('Milestone Detection Tests', () {
    late DatabaseService databaseService;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      DatabaseService.useTestDatabase();
    });

    setUp(() async {
      databaseService = DatabaseService();
      await databaseService.resetUserData();
    });

    tearDown(() async {
      await DatabaseService.closeDatabase();
    });

    test('isMilestone detects 10,000원 increments correctly', () {
      // Test milestone detection logic using static method
      expect(DatabaseService.isMilestone(10000), isTrue, reason: '10,000원 is a milestone');
      expect(DatabaseService.isMilestone(20000), isTrue, reason: '20,000원 is a milestone');
      expect(DatabaseService.isMilestone(30000), isTrue, reason: '30,000원 is a milestone');
      expect(DatabaseService.isMilestone(100000), isTrue, reason: '100,000원 is a milestone');

      // Test non-milestone amounts
      expect(DatabaseService.isMilestone(5000), isFalse, reason: '5,000원 is not a milestone');
      expect(DatabaseService.isMilestone(15000), isFalse, reason: '15,000원 is not a milestone');
      expect(DatabaseService.isMilestone(25000), isFalse, reason: '25,000원 is not a milestone');
      expect(DatabaseService.isMilestone(0), isFalse, reason: '0원 is not a milestone');
    });

    test('detectNewMilestones finds new milestones correctly', () {
      // Test single milestone detection using static method
      var newMilestones = DatabaseService.detectNewMilestones(9000, 10000);
      expect(newMilestones, equals([10000]), reason: 'Should detect 10,000원 milestone');

      // Test multiple milestones (rare but possible with bulk operations)
      newMilestones = DatabaseService.detectNewMilestones(8000, 22000);
      expect(newMilestones, equals([10000, 20000]), 
        reason: 'Should detect both 10,000원 and 20,000원 milestones');

      // Test no new milestones
      newMilestones = DatabaseService.detectNewMilestones(15000, 18000);
      expect(newMilestones, isEmpty, reason: 'Should detect no new milestones');

      // Test already at milestone
      newMilestones = DatabaseService.detectNewMilestones(10000, 11000);
      expect(newMilestones, isEmpty, reason: 'Should detect no new milestones when starting at milestone');
    });

    test('milestone detection works with actual save operations', () async {
      // Save 9 times to get to 9,000원
      for (int i = 0; i < 9; i++) {
        await databaseService.saveMoney();
      }

      // 10th save should trigger milestone
      final result = await databaseService.saveMoney();
      
      expect(result.success, isTrue, reason: 'Save operation should succeed');
      expect(result.newTotal, equals(10000), reason: 'Total should be 10,000원');
      expect(result.milestonesHit, equals([10000]), 
        reason: 'Should detect 10,000원 milestone');
    });

    test('multiple rapid saves correctly track milestones', () async {
      // Save 19 times to get to 19,000원
      for (int i = 0; i < 19; i++) {
        await databaseService.saveMoney();
      }

      // 20th save should trigger 20,000원 milestone
      final result = await databaseService.saveMoney();
      
      expect(result.success, isTrue, reason: 'Save operation should succeed');
      expect(result.newTotal, equals(20000), reason: 'Total should be 20,000원');
      expect(result.milestonesHit, equals([20000]), 
        reason: 'Should detect 20,000원 milestone');
    });

    test('milestone detection handles edge cases', () {
      // Test boundary conditions using static method
      expect(DatabaseService.isMilestone(9999), isFalse, reason: '9,999원 is not a milestone');
      expect(DatabaseService.isMilestone(10001), isFalse, reason: '10,001원 is not a milestone');
      
      // Test negative numbers (should not happen in app but test for robustness)
      expect(DatabaseService.isMilestone(-10000), isFalse, reason: 'Negative amounts are not milestones');
      
      // Test large numbers
      expect(DatabaseService.isMilestone(1000000), isTrue, reason: '1,000,000원 is a milestone');
    });

    test('milestone progress tracking across app sessions', () async {
      // Save to first milestone
      for (int i = 0; i < 10; i++) {
        await databaseService.saveMoney();
      }

      // Check progress has milestone recorded
      final progress1 = await databaseService.getCurrentProgress();
      expect(progress1.milestones, contains(10000), 
        reason: 'Should track achieved milestone');

      // Continue to second milestone
      for (int i = 0; i < 10; i++) {
        await databaseService.saveMoney();
      }

      final progress2 = await databaseService.getCurrentProgress();
      expect(progress2.milestones, containsAll([10000, 20000]),
        reason: 'Should track all achieved milestones');
    });
  });
}