import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_touch_savings/services/performance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('PerformanceService', () {
    group('Database Operation Monitoring', () {
      test('should monitor successful database operation within limits', () async {
        const operationName = 'testOperation';
        final result = await PerformanceService.monitorDatabaseOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 10));
            return 'success';
          },
        );
        
        expect(result, equals('success'));
      });
      
      test('should monitor successful database operation with metadata', () async {
        const operationName = 'testOperationWithMetadata';
        const metadata = {'operation_type': 'save_money', 'user_id': 123};
        
        final result = await PerformanceService.monitorDatabaseOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 5));
            return 'success_with_metadata';
          },
          metadata: metadata,
        );
        
        expect(result, equals('success_with_metadata'));
      });
      
      test('should monitor slow database operation and log warning', () async {
        const operationName = 'slowOperation';
        
        final result = await PerformanceService.monitorDatabaseOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 35)); // Above warning threshold
            return 'slow_success';
          },
        );
        
        expect(result, equals('slow_success'));
      });
      
      test('should monitor very slow database operation and log error', () async {
        const operationName = 'verySlowOperation';
        
        final result = await PerformanceService.monitorDatabaseOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 60)); // Above max limit
            return 'very_slow_success';
          },
        );
        
        expect(result, equals('very_slow_success'));
      });
      
      test('should handle failed database operation and rethrow error', () async {
        const operationName = 'failedOperation';
        final testError = Exception('Test database error');
        
        expect(
          () => PerformanceService.monitorDatabaseOperation(
            operationName,
            () async {
              await Future.delayed(const Duration(milliseconds: 15));
              throw testError;
            },
          ),
          throwsA(testError),
        );
      });
      
      test('should handle failed database operation with metadata', () async {
        const operationName = 'failedOperationWithMetadata';
        const metadata = {'operation_type': 'complex_query', 'retry_count': 3};
        final testError = Exception('Test database failure');
        
        expect(
          () => PerformanceService.monitorDatabaseOperation(
            operationName,
            () async {
              await Future.delayed(const Duration(milliseconds: 25));
              throw testError;
            },
            metadata: metadata,
          ),
          throwsA(testError),
        );
      });
    });
    
    group('General Operation Monitoring', () {
      test('should monitor successful operation within default limits', () async {
        const operationName = 'fastOperation';
        
        final result = await PerformanceService.monitorOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'fast_result';
          },
        );
        
        expect(result, equals('fast_result'));
      });
      
      test('should monitor operation with custom time limit', () async {
        const operationName = 'customLimitOperation';
        const maxTimeMs = 200;
        
        final result = await PerformanceService.monitorOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 150));
            return 'custom_result';
          },
          maxTimeMs: maxTimeMs,
        );
        
        expect(result, equals('custom_result'));
      });
      
      test('should log warning for operation approaching time limit', () async {
        const operationName = 'approachingLimitOperation';
        const maxTimeMs = 100;
        
        final result = await PerformanceService.monitorOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 80)); // 80% of 100ms
            return 'warning_result';
          },
          maxTimeMs: maxTimeMs,
        );
        
        expect(result, equals('warning_result'));
      });
      
      test('should log error for operation exceeding time limit', () async {
        const operationName = 'exceedingLimitOperation';
        const maxTimeMs = 50;
        
        final result = await PerformanceService.monitorOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 75)); // Exceeds 50ms
            return 'slow_result';
          },
          maxTimeMs: maxTimeMs,
        );
        
        expect(result, equals('slow_result'));
      });
      
      test('should monitor operation with metadata', () async {
        const operationName = 'operationWithMetadata';
        const metadata = {'component': 'ui_animation', 'frames': 60};
        
        final result = await PerformanceService.monitorOperation(
          operationName,
          () async {
            await Future.delayed(const Duration(milliseconds: 30));
            return 'metadata_result';
          },
          metadata: metadata,
        );
        
        expect(result, equals('metadata_result'));
      });
      
      test('should handle failed operation and rethrow error', () async {
        const operationName = 'failedGeneralOperation';
        final testError = Exception('Test general operation error');
        
        expect(
          () => PerformanceService.monitorOperation(
            operationName,
            () async {
              await Future.delayed(const Duration(milliseconds: 20));
              throw testError;
            },
          ),
          throwsA(testError),
        );
      });
      
      test('should handle failed operation with metadata and log error', () async {
        const operationName = 'failedOperationWithMetadata';
        const metadata = {'ui_component': 'savings_button', 'action': 'press'};
        final testError = Exception('UI operation failed');
        
        expect(
          () => PerformanceService.monitorOperation(
            operationName,
            () async {
              await Future.delayed(const Duration(milliseconds: 40));
              throw testError;
            },
            metadata: metadata,
          ),
          throwsA(testError),
        );
      });
    });
    
    group('Performance Stats', () {
      test('should return correct performance stats', () {
        final stats = PerformanceService.getPerformanceStats();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['database_operation_limit_ms'], equals(50));
        expect(stats['database_warning_threshold_ms'], equals(30));
        expect(stats['target_frame_time_ms'], equals(16));
        expect(stats['target_fps'], equals(60));
        expect(stats['memory_limit_mb'], equals(100));
        expect(stats['memory_warning_threshold_mb'], equals(80));
      });
      
      test('should return immutable performance stats', () {
        final stats1 = PerformanceService.getPerformanceStats();
        final stats2 = PerformanceService.getPerformanceStats();
        
        expect(stats1, equals(stats2));
        
        // Modify one and ensure the other is unchanged
        stats1['database_operation_limit_ms'] = 999;
        expect(stats2['database_operation_limit_ms'], equals(50));
      });
    });
    
    group('Frame Rate Monitoring', () {
      test('should initialize frame rate monitoring without error', () {
        expect(() => PerformanceService.monitorFrameRate(), returnsNormally);
      });
    });
    
    group('Memory Monitoring', () {
      test('should check memory usage without error', () async {
        await expectLater(
          PerformanceService.checkMemoryUsage(),
          completes,
        );
      });
      
      test('should start memory monitoring without error', () {
        expect(() => PerformanceService.startMemoryMonitoring(), returnsNormally);
      });
    });
    
    group('Edge Cases and Error Handling', () {
      test('should handle zero-duration operations', () async {
        final result = await PerformanceService.monitorDatabaseOperation(
          'instantOperation',
          () async => 'instant',
        );
        
        expect(result, equals('instant'));
      });
      
      test('should handle operations with null metadata', () async {
        final result = await PerformanceService.monitorOperation(
          'nullMetadataOperation',
          () async {
            await Future.delayed(const Duration(milliseconds: 10));
            return 'null_metadata_result';
          },
          metadata: null,
        );
        
        expect(result, equals('null_metadata_result'));
      });
      
      test('should handle operations with empty metadata', () async {
        final result = await PerformanceService.monitorDatabaseOperation(
          'emptyMetadataOperation',
          () async {
            await Future.delayed(const Duration(milliseconds: 5));
            return 'empty_metadata_result';
          },
          metadata: {},
        );
        
        expect(result, equals('empty_metadata_result'));
      });
      
      test('should handle operations with complex metadata', () async {
        final complexMetadata = {
          'nested': {'level': 2, 'data': [1, 2, 3]},
          'string': 'test',
          'number': 42,
          'boolean': true,
          'null_value': null,
        };
        
        final result = await PerformanceService.monitorOperation(
          'complexMetadataOperation',
          () async {
            await Future.delayed(const Duration(milliseconds: 15));
            return 'complex_metadata_result';
          },
          metadata: complexMetadata,
        );
        
        expect(result, equals('complex_metadata_result'));
      });
      
      test('should handle different error types in database operations', () async {
        final errorTypes = [
          ArgumentError('Invalid argument'),
          StateError('Invalid state'),
          FormatException('Format error'),
          TypeError(),
        ];
        
        for (final error in errorTypes) {
          expect(
            () => PerformanceService.monitorDatabaseOperation(
              'errorTypeTest',
              () async {
                await Future.delayed(const Duration(milliseconds: 10));
                throw error;
              },
            ),
            throwsA(error),
          );
        }
      });
      
      test('should handle different error types in general operations', () async {
        final errorTypes = [
          RangeError('Range error'),
          UnsupportedError('Unsupported operation'),
          ConcurrentModificationError('Concurrent modification'),
        ];
        
        for (final error in errorTypes) {
          expect(
            () => PerformanceService.monitorOperation(
              'generalErrorTypeTest',
              () async {
                await Future.delayed(const Duration(milliseconds: 5));
                throw error;
              },
            ),
            throwsA(error),
          );
        }
      });
    });
    
    group('Timing Accuracy', () {
      test('should measure timing accurately for fast operations', () async {
        final stopwatch = Stopwatch()..start();
        
        await PerformanceService.monitorDatabaseOperation(
          'timingTest',
          () async {
            await Future.delayed(const Duration(milliseconds: 10));
            return 'timing_result';
          },
        );
        
        stopwatch.stop();
        
        // Should complete in reasonable time (allowing for test environment overhead)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
      
      test('should measure timing accurately for longer operations', () async {
        final stopwatch = Stopwatch()..start();
        
        await PerformanceService.monitorOperation(
          'longerTimingTest',
          () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return 'longer_timing_result';
          },
          maxTimeMs: 200,
        );
        
        stopwatch.stop();
        
        // Should take at least 100ms but not much more than 150ms in test environment
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });
  });
}