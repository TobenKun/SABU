import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/models/user_progress.dart';

void main() {
  group('UserProgress Enhanced Methods', () {
    test('nextMilestone calculation works correctly', () {
      final progress1 = UserProgress(
        totalSavings: 5000,
        totalSessions: 5,
        todaySessionCount: 5,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [],
      );
      
      expect(progress1.nextMilestone, equals(10000));
      
      final progress2 = UserProgress(
        totalSavings: 15000,
        totalSessions: 15,
        todaySessionCount: 15,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [10000],
      );
      
      expect(progress2.nextMilestone, equals(20000));
    });

    test('progressToNextMilestone calculation works correctly', () {
      final progress = UserProgress(
        totalSavings: 5000,
        totalSessions: 5,
        todaySessionCount: 5,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [],
      );
      
      expect(progress.progressToNextMilestone, equals(0.5)); // 50% to next milestone
      
      final progress2 = UserProgress(
        totalSavings: 2500,
        totalSessions: 2,
        todaySessionCount: 2,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [],
      );
      
      expect(progress2.progressToNextMilestone, equals(0.25)); // 25% to next milestone
    });

    test('amountToNextMilestone calculation works correctly', () {
      final progress = UserProgress(
        totalSavings: 7000,
        totalSessions: 7,
        todaySessionCount: 7,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [],
      );
      
      expect(progress.amountToNextMilestone, equals(3000)); // Need 3,000 more for milestone
    });

    test('milestones utility methods work correctly', () {
      final progress = UserProgress(
        totalSavings: 25000,
        totalSessions: 25,
        todaySessionCount: 25,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [10000, 20000],
      );
      
      expect(progress.milestonesCount, equals(2));
      expect(progress.latestMilestone, equals(20000));
      expect(progress.hasAchievedMilestone(10000), isTrue);
      expect(progress.hasAchievedMilestone(30000), isFalse);
      expect(progress.isMilestone(10000), isTrue);
      expect(progress.isMilestone(15000), isFalse);
    });

    test('validateMilestoneIntegrity works correctly', () {
      // Valid milestone data
      final validProgress = UserProgress(
        totalSavings: 20000,
        totalSessions: 20,
        todaySessionCount: 20,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [10000, 20000],
      );
      
      expect(validProgress.validateMilestoneIntegrity(), isTrue);
      
      // Invalid: unsorted milestones
      final invalidProgress1 = UserProgress(
        totalSavings: 20000,
        totalSessions: 20,
        todaySessionCount: 20,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [20000, 10000], // Wrong order
      );
      
      expect(invalidProgress1.validateMilestoneIntegrity(), isFalse);
      
      // Invalid: milestone exceeds total savings
      final invalidProgress2 = UserProgress(
        totalSavings: 15000,
        totalSessions: 15,
        todaySessionCount: 15,
        lastSaveDate: DateTime.now(),
        currentStreak: 1,
        longestStreak: 1,
        milestones: [10000, 20000], // 20k milestone but only 15k total
      );
      
      expect(invalidProgress2.validateMilestoneIntegrity(), isFalse);
    });

    test('empty progress case works correctly', () {
      final emptyProgress = UserProgress.empty();
      
      expect(emptyProgress.nextMilestone, equals(10000));
      expect(emptyProgress.progressToNextMilestone, equals(0.0));
      expect(emptyProgress.amountToNextMilestone, equals(10000));
      expect(emptyProgress.milestonesCount, equals(0));
      expect(emptyProgress.latestMilestone, equals(0));
      expect(emptyProgress.validateMilestoneIntegrity(), isTrue);
    });
  });
}