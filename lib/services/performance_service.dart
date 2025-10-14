import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'logger_service.dart';

class PerformanceService {
  static const int _maxOperationTimeMs = 50; // Performance requirement
  static const int _warningThresholdMs = 30;
  static const int _maxMemoryMb = 100; // Memory limit requirement
  static const int _memoryWarningThresholdMb = 80;
  
  /// Monitor a database operation and log performance metrics
  static Future<T> monitorDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final durationMs = stopwatch.elapsedMilliseconds;
      
      // Log performance metrics
      _logPerformanceMetrics(operationName, durationMs, metadata, null);
      
      return result;
    } catch (error) {
      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;
      
      // Log performance metrics even for failed operations
      _logPerformanceMetrics(operationName, durationMs, metadata, error);
      
      rethrow;
    }
  }
  
  /// Monitor any operation with timing
  static Future<T> monitorOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    int maxTimeMs = 100,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final durationMs = stopwatch.elapsedMilliseconds;
      
      // Log if operation took too long
      if (durationMs > maxTimeMs) {
        LoggerService.logPerformanceIssue(
          'Slow operation: $operationName took ${durationMs}ms (max: ${maxTimeMs}ms)',
          metadata ?? {},
        );
      } else if (durationMs > maxTimeMs * 0.7) {
        LoggerService.logPerformanceWarning(
          'Operation approaching limit: $operationName took ${durationMs}ms (max: ${maxTimeMs}ms)',
          metadata ?? {},
        );
      }
      
      return result;
    } catch (error) {
      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;
      
      LoggerService.logPerformanceError(
        'Failed operation: $operationName failed after ${durationMs}ms',
        error,
        metadata ?? {},
      );
      
      rethrow;
    }
  }
  
  static void _logPerformanceMetrics(
    String operationName,
    int durationMs,
    Map<String, dynamic>? metadata,
    dynamic error,
  ) {
    final logData = {
      'operation': operationName,
      'duration_ms': durationMs,
      'max_allowed_ms': _maxOperationTimeMs,
      'warning_threshold_ms': _warningThresholdMs,
      'success': error == null,
      if (metadata != null) ...metadata,
      if (error != null) 'error_type': error.runtimeType.toString(),
    };
    
    if (error != null) {
      LoggerService.logPerformanceError(
        'Database operation failed: $operationName (${durationMs}ms)',
        error,
        logData,
      );
    } else if (durationMs > _maxOperationTimeMs) {
      LoggerService.logPerformanceIssue(
        'Database operation exceeded limit: $operationName took ${durationMs}ms (limit: ${_maxOperationTimeMs}ms)',
        logData,
      );
    } else if (durationMs > _warningThresholdMs) {
      LoggerService.logPerformanceWarning(
        'Database operation approaching limit: $operationName took ${durationMs}ms (warning: ${_warningThresholdMs}ms)',
        logData,
      );
    } else {
      LoggerService.logPerformanceSuccess(
        'Database operation completed: $operationName (${durationMs}ms)',
        logData,
      );
    }
  }
  
  /// Monitor animation frame timing
  static void monitorFrameRate() {
    if (!kDebugMode) return;
    
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameDurationMs = timing.totalSpan.inMilliseconds;
        const targetFrameMs = 16; // 60fps = ~16.67ms per frame
        
        if (frameDurationMs > targetFrameMs) {
          LoggerService.logPerformanceWarning(
            'Frame drop detected: ${frameDurationMs}ms (target: ${targetFrameMs}ms)',
            {
              'frame_duration_ms': frameDurationMs,
              'target_ms': targetFrameMs,
              'fps_equivalent': (1000 / frameDurationMs).round(),
            },
          );
        }
      }
    });
  }
  
  /// Get performance stats for debugging
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'database_operation_limit_ms': _maxOperationTimeMs,
      'database_warning_threshold_ms': _warningThresholdMs,
      'target_frame_time_ms': 16,
      'target_fps': 60,
      'memory_limit_mb': _maxMemoryMb,
      'memory_warning_threshold_mb': _memoryWarningThresholdMb,
    };
  }
  
  /// Monitor memory usage and enforce limits
  static Future<void> checkMemoryUsage() async {
    if (!kDebugMode) return;
    
    try {
      // Get current memory usage
      final memoryInfo = ProcessInfo.currentRss;
      final memoryMb = (memoryInfo / (1024 * 1024)).round();
      
      final logData = {
        'memory_mb': memoryMb,
        'memory_limit_mb': _maxMemoryMb,
        'memory_warning_threshold_mb': _memoryWarningThresholdMb,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (memoryMb > _maxMemoryMb) {
        LoggerService.logPerformanceError(
          'Memory usage exceeded limit: ${memoryMb}MB (limit: ${_maxMemoryMb}MB)',
          Exception('Memory limit exceeded'),
          logData,
        );
        
        // Force garbage collection
        await _forceGarbageCollection();
        
        // Check again after GC
        final newMemoryInfo = ProcessInfo.currentRss;
        final newMemoryMb = (newMemoryInfo / (1024 * 1024)).round();
        
        if (newMemoryMb > _maxMemoryMb) {
          LoggerService.logPerformanceError(
            'Memory usage still high after GC: ${newMemoryMb}MB (limit: ${_maxMemoryMb}MB)',
            Exception('Memory limit still exceeded after garbage collection'),
            {...logData, 'memory_after_gc_mb': newMemoryMb},
          );
        } else {
          LoggerService.logPerformanceSuccess(
            'Memory usage reduced after GC: ${newMemoryMb}MB (was: ${memoryMb}MB)',
            {...logData, 'memory_after_gc_mb': newMemoryMb},
          );
        }
      } else if (memoryMb > _memoryWarningThresholdMb) {
        LoggerService.logPerformanceWarning(
          'Memory usage approaching limit: ${memoryMb}MB (limit: ${_maxMemoryMb}MB)',
          logData,
        );
      } else {
        LoggerService.logPerformanceSuccess(
          'Memory usage normal: ${memoryMb}MB (limit: ${_maxMemoryMb}MB)',
          logData,
        );
      }
    } catch (error) {
      LoggerService.logPerformanceError(
        'Failed to check memory usage',
        error,
        {'error_type': error.runtimeType.toString()},
      );
    }
  }
  
  /// Start periodic memory monitoring
  static void startMemoryMonitoring() {
    if (!kDebugMode) return;
    
    // Check memory every 30 seconds
    Stream.periodic(const Duration(seconds: 30)).listen((_) async {
      await checkMemoryUsage();
    });
  }
  
  /// Track animation frame timing
  static void trackAnimationFrame(String animationName, Duration duration) {
    if (!kDebugMode) return;
    
    final durationMs = duration.inMilliseconds;
    const targetFrameMs = 16; // 60fps = ~16.67ms per frame
    
    final logData = {
      'animation': animationName,
      'duration_ms': durationMs,
      'target_ms': targetFrameMs,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (durationMs > targetFrameMs * 2) {
      LoggerService.logPerformanceIssue(
        'Slow animation: $animationName took ${durationMs}ms (target: ${targetFrameMs}ms)',
        logData,
      );
    } else if (durationMs > targetFrameMs) {
      LoggerService.logPerformanceWarning(
        'Animation frame drop: $animationName took ${durationMs}ms (target: ${targetFrameMs}ms)',
        logData,
      );
    } else {
      LoggerService.logPerformanceSuccess(
        'Animation completed smoothly: $animationName (${durationMs}ms)',
        logData,
      );
    }
  }
  
  /// Force garbage collection to free memory
  static Future<void> _forceGarbageCollection() async {
    // Request multiple garbage collection cycles
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
      // Note: Dart doesn't expose direct GC control, but creating
      // some allocation pressure can trigger it indirectly
      final temp = List.generate(1000, (index) => index);
      temp.clear();
    }
  }
}