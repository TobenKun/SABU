import 'package:flutter/foundation.dart';
import 'dart:io';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LoggerService {
  static bool _loggingEnabled = kDebugMode; // Enable logging in debug mode by default
  static LogLevel _minLogLevel = LogLevel.warning; // Only show warnings and errors by default
  
  /// Enable or disable logging
  static void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }
  
  /// Set minimum log level to display
  static void setMinLogLevel(LogLevel level) {
    _minLogLevel = level;
  }
  
  /// Enable verbose logging (shows DEBUG and INFO)
  static void enableVerboseLogging() {
    _minLogLevel = LogLevel.debug;
  }
  
  /// Disable verbose logging (only WARNING and ERROR)
  static void disableVerboseLogging() {
    _minLogLevel = LogLevel.warning;
  }
  
  /// Check if logging is currently enabled
  static bool get loggingEnabled => _loggingEnabled;
  
  /// Check if verbose logging is enabled
  static bool get verboseLoggingEnabled => _minLogLevel.index <= LogLevel.info.index;
  
  /// Initialize logger with environment settings
  static void initialize() {
    // Check environment variables for log level control
    final verboseEnv = Platform.environment['FLUTTER_VERBOSE_LOGS'];
    if (verboseEnv?.toLowerCase() == 'true') {
      enableVerboseLogging();
    }
  }
  
  /// Log a debug message
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }
  
  /// Log an info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }
  
  /// Log a warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }
  
  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }
  
  static void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    if (!_loggingEnabled) return;
    
    // Only show logs at or above the minimum level
    if (level.index < _minLogLevel.index) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    
    if (kDebugMode) {
      print('[$timestamp] $levelStr: $message');
      if (error != null) {
        print('  Error: $error');
      }
      if (stackTrace != null) {
        print('  Stack trace: $stackTrace');
      }
    }
  }
  
  /// Log save operation success
  static void logSaveSuccess(int newTotal, int todayCount) {
    info('Save operation successful - Total: ₩$newTotal, Today: $todayCount');
  }
  
  /// Log save operation error
  static void logSaveError(String errorMessage, [Object? error]) {
    LoggerService.error('Save operation failed: $errorMessage', error);
  }
  
  /// Log milestone achievement
  static void logMilestone(List<int> milestones) {
    info('Milestone achieved: ${milestones.join(', ')}');
  }
  
  /// Log database operations
  static void logDatabaseOperation(String operation, [Map<String, dynamic>? data]) {
    debug('Database operation: $operation${data != null ? ' - Data: $data' : ''}');
  }
  
  /// Log performance success
  static void logPerformanceSuccess(String message, Map<String, dynamic> data) {
    debug('PERF-OK: $message - Data: $data');
  }
  
  /// Log performance warning
  static void logPerformanceWarning(String message, Map<String, dynamic> data) {
    warning('PERF-WARN: $message - Data: $data');
  }
  
  /// Log performance issue
  static void logPerformanceIssue(String message, Map<String, dynamic> data) {
    error('PERF-ISSUE: $message - Data: $data');
  }
  
  /// Log performance error
  static void logPerformanceError(String message, Object? error, Map<String, dynamic> data) {
    LoggerService.error('PERF-ERROR: $message - Data: $data', error);
  }
}