import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/utils/korean_number_formatter.dart';

void main() {
  group('KoreanNumberFormatter', () {
    group('Currency Formatting', () {
      test('should format small amounts with currency symbol', () {
        expect(KoreanNumberFormatter.formatCurrency(0), '₩0');
        expect(KoreanNumberFormatter.formatCurrency(100), '₩100');
        expect(KoreanNumberFormatter.formatCurrency(999), '₩999');
      });

      test('should format amounts with thousands separators', () {
        expect(KoreanNumberFormatter.formatCurrency(1000), '₩1,000');
        expect(KoreanNumberFormatter.formatCurrency(10000), '₩10,000');
        expect(KoreanNumberFormatter.formatCurrency(100000), '₩100,000');
        expect(KoreanNumberFormatter.formatCurrency(1000000), '₩1,000,000');
      });

      test('should format complex amounts correctly', () {
        expect(KoreanNumberFormatter.formatCurrency(12345), '₩12,345');
        expect(KoreanNumberFormatter.formatCurrency(123456), '₩123,456');
        expect(KoreanNumberFormatter.formatCurrency(1234567), '₩1,234,567');
      });
    });

    group('Progress Formatting', () {
      test('should format progress with both current and target', () {
        expect(
          KoreanNumberFormatter.formatProgress(3000, 10000),
          '₩3,000 / ₩10,000',
        );
        expect(
          KoreanNumberFormatter.formatProgress(0, 5000),
          '₩0 / ₩5,000',
        );
        expect(
          KoreanNumberFormatter.formatProgress(15000, 20000),
          '₩15,000 / ₩20,000',
        );
      });
    });

    group('Percentage Calculations', () {
      test('should calculate percentage correctly', () {
        expect(KoreanNumberFormatter.calculatePercentage(0, 100), 0.0);
        expect(KoreanNumberFormatter.calculatePercentage(50, 100), 50.0);
        expect(KoreanNumberFormatter.calculatePercentage(100, 100), 100.0);
        expect(KoreanNumberFormatter.calculatePercentage(75, 100), 75.0);
      });

      test('should handle zero target', () {
        expect(KoreanNumberFormatter.calculatePercentage(50, 0), 0.0);
      });

      test('should clamp percentages above 100%', () {
        expect(KoreanNumberFormatter.calculatePercentage(150, 100), 100.0);
        expect(KoreanNumberFormatter.calculatePercentage(200, 100), 100.0);
      });

      test('should format percentage with one decimal place', () {
        expect(KoreanNumberFormatter.formatPercentage(33.333), '33.3%');
        expect(KoreanNumberFormatter.formatPercentage(66.666), '66.7%');
        expect(KoreanNumberFormatter.formatPercentage(100.0), '100.0%');
        expect(KoreanNumberFormatter.formatPercentage(0.0), '0.0%');
      });
    });

    group('Milestone Calculations', () {
      test('should calculate next milestone correctly', () {
        expect(KoreanNumberFormatter.getNextMilestone(0), 0);
        expect(KoreanNumberFormatter.getNextMilestone(1), 10000);
        expect(KoreanNumberFormatter.getNextMilestone(5000), 10000);
        expect(KoreanNumberFormatter.getNextMilestone(10000), 10000);
        expect(KoreanNumberFormatter.getNextMilestone(10001), 20000);
        expect(KoreanNumberFormatter.getNextMilestone(15000), 20000);
        expect(KoreanNumberFormatter.getNextMilestone(25000), 30000);
      });

      test('should calculate milestone progress correctly', () {
        expect(KoreanNumberFormatter.getMilestoneProgress(0), 0.0);
        expect(KoreanNumberFormatter.getMilestoneProgress(5000), 50.0);
        expect(KoreanNumberFormatter.getMilestoneProgress(10000), 100.0);
        expect(KoreanNumberFormatter.getMilestoneProgress(15000), 50.0);
        expect(KoreanNumberFormatter.getMilestoneProgress(18000), 80.0);
      });

      test('should detect milestones correctly', () {
        expect(KoreanNumberFormatter.isMilestone(0), false);
        expect(KoreanNumberFormatter.isMilestone(5000), false);
        expect(KoreanNumberFormatter.isMilestone(10000), true);
        expect(KoreanNumberFormatter.isMilestone(20000), true);
        expect(KoreanNumberFormatter.isMilestone(15000), false);
        expect(KoreanNumberFormatter.isMilestone(30000), true);
      });

      test('should get milestone level correctly', () {
        expect(KoreanNumberFormatter.getMilestoneLevel(0), 0);
        expect(KoreanNumberFormatter.getMilestoneLevel(5000), 0);
        expect(KoreanNumberFormatter.getMilestoneLevel(10000), 1);
        expect(KoreanNumberFormatter.getMilestoneLevel(20000), 2);
        expect(KoreanNumberFormatter.getMilestoneLevel(30000), 3);
        expect(KoreanNumberFormatter.getMilestoneLevel(15000), 0);
      });
    });

    group('Milestone Messages', () {
      test('should format milestone messages correctly', () {
        expect(
          KoreanNumberFormatter.formatMilestoneMessage(10000),
          '첫 번째 목표 달성! ₩10,000',
        );
        expect(
          KoreanNumberFormatter.formatMilestoneMessage(20000),
          '두 번째 목표 달성! ₩20,000',
        );
        expect(
          KoreanNumberFormatter.formatMilestoneMessage(30000),
          '세 번째 목표 달성! ₩30,000',
        );
      });

      test('should return empty string for non-milestones', () {
        expect(KoreanNumberFormatter.formatMilestoneMessage(0), '');
        expect(KoreanNumberFormatter.formatMilestoneMessage(5000), '');
        expect(KoreanNumberFormatter.formatMilestoneMessage(15000), '');
      });

      test('should handle milestone levels beyond 10', () {
        expect(
          KoreanNumberFormatter.formatMilestoneMessage(110000),
          '11번째 목표 달성! ₩110,000',
        );
        expect(
          KoreanNumberFormatter.formatMilestoneMessage(250000),
          '25번째 목표 달성! ₩250,000',
        );
      });

      test('should format first 10 milestone levels in Korean', () {
        final expectedMessages = [
          '첫 번째 목표 달성! ₩10,000',
          '두 번째 목표 달성! ₩20,000',
          '세 번째 목표 달성! ₩30,000',
          '네 번째 목표 달성! ₩40,000',
          '다섯 번째 목표 달성! ₩50,000',
          '여섯 번째 목표 달성! ₩60,000',
          '일곱 번째 목표 달성! ₩70,000',
          '여덟 번째 목표 달성! ₩80,000',
          '아홉 번째 목표 달성! ₩90,000',
          '열 번째 목표 달성! ₩100,000',
        ];

        for (int i = 1; i <= 10; i++) {
          expect(
            KoreanNumberFormatter.formatMilestoneMessage(i * 10000),
            expectedMessages[i - 1],
          );
        }
      });
    });

    group('Savings Session Formatting', () {
      test('should format savings session with time', () {
        final timestamp = DateTime(2023, 1, 1, 14, 30);
        final result = KoreanNumberFormatter.formatSavingSession(1000, timestamp);
        expect(result, '₩1,000 (저장 시간: 14:30)');
      });

      test('should pad minutes with zero', () {
        final timestamp = DateTime(2023, 1, 1, 9, 5);
        final result = KoreanNumberFormatter.formatSavingSession(2000, timestamp);
        expect(result, '₩2,000 (저장 시간: 9:05)');
      });
    });

    group('Averages Calculation', () {
      test('should calculate averages correctly', () {
        final result = KoreanNumberFormatter.calculateAverages(30000, 10, 30);
        
        expect(result['daily'], '₩1,000');
        expect(result['weekly'], '₩7,000');
        expect(result['monthly'], '₩30,000');
        expect(result['perSession'], '₩3,000');
      });

      test('should handle zero days gracefully', () {
        final result = KoreanNumberFormatter.calculateAverages(10000, 5, 0);
        
        expect(result['daily'], '₩0');
        expect(result['weekly'], '₩0');
        expect(result['monthly'], '₩0');
        expect(result['perSession'], '₩0');
      });

      test('should handle zero sessions gracefully', () {
        final result = KoreanNumberFormatter.calculateAverages(10000, 0, 30);
        
        expect(result['daily'], '₩0');
        expect(result['weekly'], '₩0');
        expect(result['monthly'], '₩0');
        expect(result['perSession'], '₩0');
      });

      test('should round averages correctly', () {
        final result = KoreanNumberFormatter.calculateAverages(10333, 3, 7);
        
        // Daily: 10333/7 = 1476.14... -> 1476
        // Weekly: 1476 * 7 = 10332
        // Monthly: 1476 * 30 = 44280
        // Per session: 10333/3 = 3444.33... -> 3444
        expect(result['daily'], '₩1,476');
        expect(result['weekly'], '₩10,332');
        expect(result['monthly'], '₩44,280');
        expect(result['perSession'], '₩3,444');
      });
    });

    group('Progress Messages', () {
      test('should show achievement message at 100%', () {
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(1.0, 0);
        expect(result, '목표 달성! 축하합니다! 🎉');
      });

      test('should show achievement message above 100%', () {
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(1.2, 0);
        expect(result, '목표 달성! 축하합니다! 🎉');
      });

      test('should show almost there message at 90%+', () {
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(0.95, 500);
        expect(result, '거의 다 왔어요! ₩500 남았습니다');
      });

      test('should show halfway message at 50%+', () {
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(0.75, 2500);
        expect(result, '절반 이상 달성! 75.0% 완료');
      });

      test('should show good start message at 25%+', () {
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(0.30, 7000);
        expect(result, '좋은 시작이에요! 30.0% 완료');
      });

      test('should show encouragement message below 25%', () {
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(0.10, 9000);
        expect(result, '화이팅! ₩9,000 남았습니다');
      });

      test('should show encouragement message at 0%', () {
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(0.0, 10000);
        expect(result, '화이팅! ₩10,000 남았습니다');
      });

      // Milestone-based progress scenarios
      test('should show correct progress at milestone start (10,000)', () {
        // At exactly 10,000 won (first milestone), progress should be 0% for next milestone
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(0.0, 10000);
        expect(result, '화이팅! ₩10,000 남았습니다');
      });

      test('should show correct progress at 15,000 (50% to second milestone)', () {
        // At 15,000 won, halfway to 20,000 milestone
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(0.5, 5000);
        expect(result, '절반 이상 달성! 50.0% 완료');
      });

      test('should show correct progress at 19,500 (95% to second milestone)', () {
        // At 19,500 won, 95% to 20,000 milestone
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(0.95, 500);
        expect(result, '거의 다 왔어요! ₩500 남았습니다');
      });

      test('should show achievement at milestone completion', () {
        // At exactly 20,000 won (second milestone), 100% progress
        final result = KoreanNumberFormatter.formatProgressMessageFromProgress(1.0, 0);
        expect(result, '목표 달성! 축하합니다! 🎉');
      });
    });
  });
}