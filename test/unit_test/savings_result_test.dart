import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/models/savings_result.dart';

void main() {
  group('SavingsResult', () {
    group('Constructor Tests', () {
      test('should create SavingsResult with all parameters', () {
        final result = SavingsResult(
          newTotal: 5000,
          todayCount: 3,
          milestonesHit: [10000, 20000],
          success: true,
          error: null,
        );

        expect(result.newTotal, equals(5000));
        expect(result.todayCount, equals(3));
        expect(result.milestonesHit, equals([10000, 20000]));
        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('should create SavingsResult with error', () {
        const errorMessage = 'Database connection failed';
        final result = SavingsResult(
          newTotal: 0,
          todayCount: 0,
          milestonesHit: const [],
          success: false,
          error: errorMessage,
        );

        expect(result.newTotal, equals(0));
        expect(result.todayCount, equals(0));
        expect(result.milestonesHit, isEmpty);
        expect(result.success, isFalse);
        expect(result.error, equals(errorMessage));
      });
    });

    group('Factory Constructor Tests', () {
      test('SavingsResult.success should create successful result', () {
        final result = SavingsResult.success(
          newTotal: 15000,
          todayCount: 5,
          milestonesHit: [10000],
        );

        expect(result.newTotal, equals(15000));
        expect(result.todayCount, equals(5));
        expect(result.milestonesHit, equals([10000]));
        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('SavingsResult.success should use default empty milestones', () {
        final result = SavingsResult.success(
          newTotal: 3000,
          todayCount: 2,
        );

        expect(result.newTotal, equals(3000));
        expect(result.todayCount, equals(2));
        expect(result.milestonesHit, isEmpty);
        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('SavingsResult.failure should create failure result', () {
        const errorMessage = 'Network error occurred';
        final result = SavingsResult.failure(errorMessage);

        expect(result.newTotal, equals(0));
        expect(result.todayCount, equals(0));
        expect(result.milestonesHit, isEmpty);
        expect(result.success, isFalse);
        expect(result.error, equals(errorMessage));
      });
    });

    group('toString Tests', () {
      test('should return formatted string representation', () {
        final result = SavingsResult(
          newTotal: 7500,
          todayCount: 4,
          milestonesHit: [5000, 10000],
          success: true,
          error: null,
        );

        final stringResult = result.toString();
        expect(stringResult, contains('newTotal: 7500'));
        expect(stringResult, contains('todayCount: 4'));
        expect(stringResult, contains('milestonesHit: [5000, 10000]'));
        expect(stringResult, contains('success: true'));
        expect(stringResult, contains('error: null'));
      });

      test('should include error in string representation', () {
        const errorMessage = 'Save operation failed';
        final result = SavingsResult.failure(errorMessage);

        final stringResult = result.toString();
        expect(stringResult, contains('error: $errorMessage'));
        expect(stringResult, contains('success: false'));
      });
    });

    group('Equality Tests', () {
      test('should be equal when all properties match', () {
        final result1 = SavingsResult(
          newTotal: 10000,
          todayCount: 5,
          milestonesHit: [5000, 10000],
          success: true,
          error: null,
        );

        final result2 = SavingsResult(
          newTotal: 10000,
          todayCount: 5,
          milestonesHit: [5000, 10000],
          success: true,
          error: null,
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final result1 = SavingsResult(
          newTotal: 10000,
          todayCount: 5,
          milestonesHit: [5000, 10000],
          success: true,
          error: null,
        );

        final result2 = SavingsResult(
          newTotal: 12000, // Different total
          todayCount: 5,
          milestonesHit: [5000, 10000],
          success: true,
          error: null,
        );

        expect(result1, isNot(equals(result2)));
        expect(result1.hashCode, isNot(equals(result2.hashCode)));
      });

      test('should not be equal when milestones differ', () {
        final result1 = SavingsResult.success(
          newTotal: 10000,
          todayCount: 5,
          milestonesHit: [5000, 10000],
        );

        final result2 = SavingsResult.success(
          newTotal: 10000,
          todayCount: 5,
          milestonesHit: [5000], // Different milestones
        );

        expect(result1, isNot(equals(result2)));
      });

      test('should not be equal when success status differs', () {
        final result1 = SavingsResult.success(
          newTotal: 10000,
          todayCount: 5,
        );

        final result2 = SavingsResult.failure('Some error');

        expect(result1, isNot(equals(result2)));
      });

      test('should handle identical instances', () {
        final result = SavingsResult.success(
          newTotal: 5000,
          todayCount: 3,
        );

        expect(result, equals(result));
      });

      test('should handle comparison with non-SavingsResult object', () {
        final result = SavingsResult.success(
          newTotal: 5000,
          todayCount: 3,
        );

        expect(result, isNot(equals('not a savings result')));
        expect(result, isNot(equals(42)));
        expect(result, isNot(equals(null)));
      });
    });

    group('List Equality Helper Tests', () {
      test('should handle empty lists', () {
        final result1 = SavingsResult.success(
          newTotal: 1000,
          todayCount: 1,
          milestonesHit: [],
        );

        final result2 = SavingsResult.success(
          newTotal: 1000,
          todayCount: 1,
          milestonesHit: [],
        );

        expect(result1, equals(result2));
      });

      test('should handle different length lists', () {
        final result1 = SavingsResult.success(
          newTotal: 1000,
          todayCount: 1,
          milestonesHit: [1000],
        );

        final result2 = SavingsResult.success(
          newTotal: 1000,
          todayCount: 1,
          milestonesHit: [1000, 2000],
        );

        expect(result1, isNot(equals(result2)));
      });
    });
  });
}