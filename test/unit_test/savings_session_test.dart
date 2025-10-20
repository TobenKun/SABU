import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/models/savings_session.dart';

void main() {
  group('SavingsSession', () {
    late DateTime testTimestamp;
    
    setUp(() {
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
    });
    
    group('Constructor Tests', () {
      test('should create SavingsSession with all parameters', () {
        final session = SavingsSession(
          id: 1,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Test savings',
        );

        expect(session.id, equals(1));
        expect(session.amount, equals(1000));
        expect(session.timestamp, equals(testTimestamp));
        expect(session.notes, equals('Test savings'));
      });

      test('should create SavingsSession with null notes', () {
        final session = SavingsSession(
          id: 2,
          amount: 1000,
          timestamp: testTimestamp,
        );

        expect(session.id, equals(2));
        expect(session.amount, equals(1000));
        expect(session.timestamp, equals(testTimestamp));
        expect(session.notes, isNull);
      });
    });

    group('fromMap Tests', () {
      test('should create SavingsSession from map with all fields', () {
        final map = {
          'id': 3,
          'amount': 1000,
          'timestamp': testTimestamp.millisecondsSinceEpoch,
          'notes': 'Mapped session',
        };

        final session = SavingsSession.fromMap(map);

        expect(session.id, equals(3));
        expect(session.amount, equals(1000));
        expect(session.timestamp, equals(testTimestamp));
        expect(session.notes, equals('Mapped session'));
      });

      test('should create SavingsSession from map with null notes', () {
        final map = {
          'id': 4,
          'amount': 1000,
          'timestamp': testTimestamp.millisecondsSinceEpoch,
          'notes': null,
        };

        final session = SavingsSession.fromMap(map);

        expect(session.id, equals(4));
        expect(session.amount, equals(1000));
        expect(session.timestamp, equals(testTimestamp));
        expect(session.notes, isNull);
      });

      test('should handle different timestamp values', () {
        final laterTimestamp = DateTime(2024, 6, 20, 15, 45);
        final map = {
          'id': 5,
          'amount': 1000,
          'timestamp': laterTimestamp.millisecondsSinceEpoch,
          'notes': 'Later session',
        };

        final session = SavingsSession.fromMap(map);
        expect(session.timestamp, equals(laterTimestamp));
      });
    });

    group('toMap Tests', () {
      test('should convert SavingsSession to map with all fields', () {
        final session = SavingsSession(
          id: 6,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Test conversion',
        );

        final map = session.toMap();

        expect(map['id'], equals(6));
        expect(map['amount'], equals(1000));
        expect(map['timestamp'], equals(testTimestamp.millisecondsSinceEpoch));
        expect(map['notes'], equals('Test conversion'));
      });

      test('should convert SavingsSession to map with null notes', () {
        final session = SavingsSession(
          id: 7,
          amount: 1000,
          timestamp: testTimestamp,
        );

        final map = session.toMap();

        expect(map['id'], equals(7));
        expect(map['amount'], equals(1000));
        expect(map['timestamp'], equals(testTimestamp.millisecondsSinceEpoch));
        expect(map['notes'], isNull);
      });

      test('should round-trip through fromMap and toMap', () {
        final originalSession = SavingsSession(
          id: 8,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Round trip test',
        );

        final map = originalSession.toMap();
        final recreatedSession = SavingsSession.fromMap(map);

        expect(recreatedSession, equals(originalSession));
      });
    });

    group('copyWith Tests', () {
      late SavingsSession originalSession;

      setUp(() {
        originalSession = SavingsSession(
          id: 9,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Original notes',
        );
      });

      test('should copy with new id', () {
        final copiedSession = originalSession.copyWith(id: 10);

        expect(copiedSession.id, equals(10));
        expect(copiedSession.amount, equals(originalSession.amount));
        expect(copiedSession.timestamp, equals(originalSession.timestamp));
        expect(copiedSession.notes, equals(originalSession.notes));
      });

      test('should copy with new amount', () {
        final copiedSession = originalSession.copyWith(amount: 2000);

        expect(copiedSession.id, equals(originalSession.id));
        expect(copiedSession.amount, equals(2000));
        expect(copiedSession.timestamp, equals(originalSession.timestamp));
        expect(copiedSession.notes, equals(originalSession.notes));
      });

      test('should copy with new timestamp', () {
        final newTimestamp = DateTime(2024, 12, 25, 12, 0);
        final copiedSession = originalSession.copyWith(timestamp: newTimestamp);

        expect(copiedSession.id, equals(originalSession.id));
        expect(copiedSession.amount, equals(originalSession.amount));
        expect(copiedSession.timestamp, equals(newTimestamp));
        expect(copiedSession.notes, equals(originalSession.notes));
      });

      test('should copy with new notes', () {
        final copiedSession = originalSession.copyWith(notes: 'Updated notes');

        expect(copiedSession.id, equals(originalSession.id));
        expect(copiedSession.amount, equals(originalSession.amount));
        expect(copiedSession.timestamp, equals(originalSession.timestamp));
        expect(copiedSession.notes, equals('Updated notes'));
      });

      test('should copy with multiple new values', () {
        final newTimestamp = DateTime(2024, 3, 10, 14, 20);
        final copiedSession = originalSession.copyWith(
          id: 11,
          amount: 1500,
          timestamp: newTimestamp,
          notes: 'Multiple updates',
        );

        expect(copiedSession.id, equals(11));
        expect(copiedSession.amount, equals(1500));
        expect(copiedSession.timestamp, equals(newTimestamp));
        expect(copiedSession.notes, equals('Multiple updates'));
      });

      test('should copy with no changes', () {
        final copiedSession = originalSession.copyWith();

        expect(copiedSession, equals(originalSession));
        expect(identical(copiedSession, originalSession), isFalse);
      });
    });

    group('validate Tests', () {
      test('should return true for valid amount (1000)', () {
        final session = SavingsSession(
          id: 12,
          amount: 1000,
          timestamp: testTimestamp,
        );

        expect(session.validate(), isTrue);
      });

      test('should return false for invalid amount (not 1000)', () {
        final session = SavingsSession(
          id: 13,
          amount: 500,
          timestamp: testTimestamp,
        );

        expect(session.validate(), isFalse);
      });

      test('should return false for zero amount', () {
        final session = SavingsSession(
          id: 14,
          amount: 0,
          timestamp: testTimestamp,
        );

        expect(session.validate(), isFalse);
      });

      test('should return false for negative amount', () {
        final session = SavingsSession(
          id: 15,
          amount: -1000,
          timestamp: testTimestamp,
        );

        expect(session.validate(), isFalse);
      });
    });

    group('toString Tests', () {
      test('should return formatted string representation', () {
        final session = SavingsSession(
          id: 16,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'String test',
        );

        final stringResult = session.toString();
        expect(stringResult, contains('id: 16'));
        expect(stringResult, contains('amount: 1000'));
        expect(stringResult, contains('timestamp: $testTimestamp'));
        expect(stringResult, contains('notes: String test'));
      });

      test('should handle null notes in string representation', () {
        final session = SavingsSession(
          id: 17,
          amount: 1000,
          timestamp: testTimestamp,
        );

        final stringResult = session.toString();
        expect(stringResult, contains('notes: null'));
      });
    });

    group('Equality Tests', () {
      test('should be equal when all properties match', () {
        final session1 = SavingsSession(
          id: 18,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Equal test',
        );

        final session2 = SavingsSession(
          id: 18,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Equal test',
        );

        expect(session1, equals(session2));
        expect(session1.hashCode, equals(session2.hashCode));
      });

      test('should not be equal when id differs', () {
        final session1 = SavingsSession(
          id: 19,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Test',
        );

        final session2 = SavingsSession(
          id: 20,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Test',
        );

        expect(session1, isNot(equals(session2)));
      });

      test('should not be equal when amount differs', () {
        final session1 = SavingsSession(
          id: 21,
          amount: 1000,
          timestamp: testTimestamp,
        );

        final session2 = SavingsSession(
          id: 21,
          amount: 2000,
          timestamp: testTimestamp,
        );

        expect(session1, isNot(equals(session2)));
      });

      test('should not be equal when timestamp differs', () {
        final session1 = SavingsSession(
          id: 22,
          amount: 1000,
          timestamp: testTimestamp,
        );

        final session2 = SavingsSession(
          id: 22,
          amount: 1000,
          timestamp: DateTime(2024, 2, 20, 16, 45),
        );

        expect(session1, isNot(equals(session2)));
      });

      test('should not be equal when notes differ', () {
        final session1 = SavingsSession(
          id: 23,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'First notes',
        );

        final session2 = SavingsSession(
          id: 23,
          amount: 1000,
          timestamp: testTimestamp,
          notes: 'Second notes',
        );

        expect(session1, isNot(equals(session2)));
      });

      test('should handle identical instances', () {
        final session = SavingsSession(
          id: 24,
          amount: 1000,
          timestamp: testTimestamp,
        );

        expect(session, equals(session));
      });

      test('should handle comparison with non-SavingsSession object', () {
        final session = SavingsSession(
          id: 25,
          amount: 1000,
          timestamp: testTimestamp,
        );

        expect(session, isNot(equals('not a savings session')));
        expect(session, isNot(equals(42)));
        expect(session, isNot(equals(null)));
      });

      test('should handle null notes equality', () {
        final session1 = SavingsSession(
          id: 26,
          amount: 1000,
          timestamp: testTimestamp,
        );

        final session2 = SavingsSession(
          id: 26,
          amount: 1000,
          timestamp: testTimestamp,
        );

        expect(session1, equals(session2));
      });
    });
  });
}