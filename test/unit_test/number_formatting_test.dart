import 'package:flutter_test/flutter_test.dart';

// Korean number formatting utility for testing
class KoreanNumberFormatter {
  static String formatCurrency(int amount) {
    // Format Korean Won with thousands separators
    // Example: 1000 -> ₩1,000, 10000 -> ₩10,000
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedAmount = amount.toString().replaceAllMapped(
      formatter, 
      (Match match) => '${match[1]},'
    );
    return '₩$formattedAmount';
  }
  
  static String formatProgress(int current, int target) {
    // Format progress as "current / target"
    return '${formatCurrency(current)} / ${formatCurrency(target)}';
  }
  
  static double calculatePercentage(int current, int target) {
    if (target == 0) return 0.0;
    return (current / target * 100).clamp(0.0, 100.0);
  }
  
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}

void main() {
  group('Korean Number Formatting', () {
    test('should format basic amounts correctly', () {
      expect(KoreanNumberFormatter.formatCurrency(1000), equals('₩1,000'));
      expect(KoreanNumberFormatter.formatCurrency(10000), equals('₩10,000'));
      expect(KoreanNumberFormatter.formatCurrency(100000), equals('₩100,000'));
      expect(KoreanNumberFormatter.formatCurrency(1000000), equals('₩1,000,000'));
    });

    test('should format small amounts without commas', () {
      expect(KoreanNumberFormatter.formatCurrency(0), equals('₩0'));
      expect(KoreanNumberFormatter.formatCurrency(100), equals('₩100'));
      expect(KoreanNumberFormatter.formatCurrency(999), equals('₩999'));
    });

    test('should format progress strings correctly', () {
      expect(
        KoreanNumberFormatter.formatProgress(3000, 10000),
        equals('₩3,000 / ₩10,000')
      );
      expect(
        KoreanNumberFormatter.formatProgress(15000, 20000),
        equals('₩15,000 / ₩20,000')
      );
    });

    test('should calculate percentages accurately', () {
      expect(KoreanNumberFormatter.calculatePercentage(3000, 10000), equals(30.0));
      expect(KoreanNumberFormatter.calculatePercentage(5000, 10000), equals(50.0));
      expect(KoreanNumberFormatter.calculatePercentage(10000, 10000), equals(100.0));
      expect(KoreanNumberFormatter.calculatePercentage(15000, 10000), equals(100.0)); // Clamped
    });

    test('should handle edge cases in percentage calculation', () {
      expect(KoreanNumberFormatter.calculatePercentage(0, 10000), equals(0.0));
      expect(KoreanNumberFormatter.calculatePercentage(1000, 0), equals(0.0)); // Division by zero
      expect(KoreanNumberFormatter.calculatePercentage(0, 0), equals(0.0));
    });

    test('should format percentage strings with one decimal place', () {
      expect(KoreanNumberFormatter.formatPercentage(30.0), equals('30.0%'));
      expect(KoreanNumberFormatter.formatPercentage(33.333), equals('33.3%'));
      expect(KoreanNumberFormatter.formatPercentage(100.0), equals('100.0%'));
    });

    test('should handle milestone calculations', () {
      const milestoneAmounts = [10000, 20000, 50000, 100000];
      
      for (final milestone in milestoneAmounts) {
        // Test progress towards each milestone
        final halfWay = milestone ~/ 2;
        final percentage = KoreanNumberFormatter.calculatePercentage(halfWay, milestone);
        expect(percentage, equals(50.0));
        
        final progressString = KoreanNumberFormatter.formatProgress(halfWay, milestone);
        final expectedString = '${KoreanNumberFormatter.formatCurrency(halfWay)} / ${KoreanNumberFormatter.formatCurrency(milestone)}';
        expect(progressString, equals(expectedString));
      }
    });

    test('should format large amounts correctly', () {
      // Test formatting for large savings amounts
      expect(KoreanNumberFormatter.formatCurrency(1234567), equals('₩1,234,567'));
      expect(KoreanNumberFormatter.formatCurrency(10000000), equals('₩10,000,000'));
      expect(KoreanNumberFormatter.formatCurrency(999999999), equals('₩999,999,999'));
    });

    test('should maintain consistency across different input ranges', () {
      final testAmounts = [
        0, 1, 10, 100, 999, 1000, 1001, 9999, 10000, 10001,
        99999, 100000, 100001, 999999, 1000000
      ];
      
      for (final amount in testAmounts) {
        final formatted = KoreanNumberFormatter.formatCurrency(amount);
        
        // Should always start with ₩
        expect(formatted.startsWith('₩'), isTrue);
        
        // Should not have trailing commas
        expect(formatted.endsWith(','), isFalse);
        
        // Should properly format numbers >= 1000 with commas
        if (amount >= 1000) {
          expect(formatted.contains(','), isTrue);
        } else {
          expect(formatted.contains(','), isFalse);
        }
      }
    });
  });

  group('Progress Display Calculations', () {
    test('should calculate milestone progress correctly', () {
      // Test progress towards first milestone (10,000)
      final testCases = [
        {'current': 0, 'expected': 0.0},
        {'current': 1000, 'expected': 10.0},
        {'current': 5000, 'expected': 50.0},
        {'current': 9000, 'expected': 90.0},
        {'current': 10000, 'expected': 100.0},
      ];
      
      for (final testCase in testCases) {
        final current = testCase['current'] as int;
        final expected = testCase['expected'] as double;
        final percentage = KoreanNumberFormatter.calculatePercentage(current, 10000);
        expect(percentage, equals(expected), reason: 'Failed for amount: $current');
      }
    });

    test('should handle multi-milestone scenarios', () {
      // Test when user has passed multiple milestones
      const currentAmount = 35000; // Passed 3 milestones, working towards 4th
      
      // Progress towards next milestone (40,000)
      const nextMilestone = 40000;
      final percentage = KoreanNumberFormatter.calculatePercentage(currentAmount, nextMilestone);
      expect(percentage, equals(87.5)); // 35000/40000 = 87.5%
      
      // Format display
      final progressDisplay = KoreanNumberFormatter.formatProgress(currentAmount, nextMilestone);
      expect(progressDisplay, equals('₩35,000 / ₩40,000'));
    });
  });
}