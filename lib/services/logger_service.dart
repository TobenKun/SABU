import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LoggerService {
  static bool _loggingEnabled = kDebugMode; // Enable logging in debug mode by default
  
  /// Enable or disable logging
  static void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }
  
  /// Check if logging is currently enabled
  static bool get loggingEnabled => _loggingEnabled;
  
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
}