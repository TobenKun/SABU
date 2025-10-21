import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/savings_session.dart';
import '../models/user_progress.dart';
import '../models/savings_result.dart';
import 'logger_service.dart';
import 'performance_service.dart';

enum DatabaseError {
  connectionFailed,
  constraintViolation,
  diskFull,
  corruptedData,
  concurrencyConflict
}

class DatabaseException implements Exception {
  final DatabaseError type;
  final String message;
  final dynamic originalError;
  
  DatabaseException(this.type, this.message, [this.originalError]);
  
  @override
  String toString() {
    return 'DatabaseException: $message (Type: $type)';
  }
}

class DatabaseService {
  static Database? _database;
  static String? _testDbPath;

  Future<Database> get database async {
    return await _initDatabase();
  }
  
  static Future<Database> _initDatabase() async {
    try {
      String path;
      if (_testDbPath != null) {
        path = _testDbPath!;
      } else {
        path = join(await getDatabasesPath(), 'savings.db');
      }
      LoggerService.logDatabaseOperation('Initializing database', {'path': path});
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: _onOpen,
      );
    } catch (e) {
      LoggerService.error('Database initialization failed', e);
      throw DatabaseException(
        DatabaseError.connectionFailed,
        'Failed to initialize database',
        e,
      );
    }
  }
  
  static Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS savings_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount INTEGER NOT NULL CHECK (amount = 1000),
          timestamp INTEGER NOT NULL
        )
      ''');
      
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS user_progress (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          total_savings INTEGER NOT NULL DEFAULT 0,
          total_sessions INTEGER NOT NULL DEFAULT 0,
          today_session_count INTEGER NOT NULL DEFAULT 0,
          last_save_date INTEGER NOT NULL DEFAULT 0,
          current_streak INTEGER NOT NULL DEFAULT 0,
          longest_streak INTEGER NOT NULL DEFAULT 0,
          milestones TEXT DEFAULT '[]'
        )
      ''');
      
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_savings_timestamp ON savings_sessions(timestamp)'
      );
      
      // Initialize progress row
      await txn.insert('user_progress', {
        'id': 1,
        'last_save_date': 0,  // Set to 0 to detect first save
      });
    });
  }
  
  static Future<void> _onOpen(Database db) async {
    try {
      // Configure SQLite for optimal performance
      // WAL mode may not be available on all platforms, so handle gracefully
      await db.execute('PRAGMA journal_mode = WAL');
      LoggerService.logDatabaseOperation('WAL mode enabled successfully');
    } catch (e) {
      // WAL mode failed, continue with default mode
      LoggerService.logDatabaseOperation('WAL mode not available, using default journal mode', {'error': e.toString()});
    }
    
    try {
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.execute('PRAGMA cache_size = 2000');
      await db.execute('PRAGMA temp_store = memory');
      LoggerService.logDatabaseOperation('Database optimization settings applied');
    } catch (e) {
      LoggerService.logDatabaseOperation('Some optimization settings failed', {'error': e.toString()});
    }
  }
  
  Future<SavingsResult> saveMoney() async {
    return await PerformanceService.monitorDatabaseOperation(
      'saveMoney',
      () async {
        try {
          LoggerService.logDatabaseOperation('Starting save money operation');
          final db = await database;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          
          late UserProgress updatedProgress;
          
          await db.transaction((txn) async {
            // Insert new session
            await txn.insert('savings_sessions', {
              'amount': 1000,
              'timestamp': timestamp,
            });
            
            // Update progress atomically
            await txn.rawUpdate('''
              UPDATE user_progress 
              SET 
                total_savings = total_savings + 1000,
                total_sessions = total_sessions + 1,
                today_session_count = CASE 
                  WHEN date(last_save_date/1000, 'unixepoch') = date('now') 
                  THEN today_session_count + 1 
                  ELSE 1 
                END,
                last_save_date = ?,
                current_streak = CASE
                  WHEN last_save_date = 0 THEN 1
                  WHEN date(last_save_date/1000, 'unixepoch') = date('now') 
                  THEN current_streak
                  WHEN date(last_save_date/1000, 'unixepoch', '+1 day') = date('now')
                  THEN current_streak + 1
                  ELSE 1
                END,
                longest_streak = MAX(longest_streak, 
                  CASE
                    WHEN last_save_date = 0 THEN 1
                    WHEN date(last_save_date/1000, 'unixepoch') = date('now') 
                    THEN current_streak
                    WHEN date(last_save_date/1000, 'unixepoch', '+1 day') = date('now')
                    THEN current_streak + 1
                    ELSE 1
                  END
                )
              WHERE id = 1
            ''', [timestamp]);
          });
          
          // Get updated progress
          updatedProgress = await getCurrentProgress();
          
          // Check for milestones and update database
          final previousTotal = updatedProgress.totalSavings - 1000;
          final milestones = _detectMilestones(previousTotal, updatedProgress.totalSavings);
          
          // If milestones were achieved, update the database
          if (milestones.isNotEmpty) {
            await _updateMilestonesInDatabase(updatedProgress.milestones, milestones);
            // Refresh progress to get updated milestones
            updatedProgress = await getCurrentProgress();
          }
          
          LoggerService.logDatabaseOperation('Save money operation completed', {
            'newTotal': updatedProgress.totalSavings,
            'todayCount': updatedProgress.todaySessionCount,
            'milestones': milestones,
          });
          
          return SavingsResult(
            success: true,
            newTotal: updatedProgress.totalSavings,
            todayCount: updatedProgress.todaySessionCount,
            milestonesHit: milestones,
          );
        } catch (e) {
          LoggerService.error('Save money operation failed', e);
          if (e is DatabaseException) rethrow;
          
          // Determine error type based on exception
          DatabaseError errorType = DatabaseError.connectionFailed;
          if (e.toString().contains('SQLITE_CONSTRAINT')) {
            errorType = DatabaseError.constraintViolation;
          } else if (e.toString().contains('disk')) {
            errorType = DatabaseError.diskFull;
          }
          
          throw DatabaseException(
            errorType,
            'Failed to save money: ${e.toString()}',
            e,
          );
        }
      },
      metadata: {'operation_type': 'save_money'},
    );
  }
  
  Future<UserProgress> getCurrentProgress() async {
    return await PerformanceService.monitorDatabaseOperation(
      'getCurrentProgress',
      () async {
        try {
          final db = await database;
          
          // Minimal query with specific columns only
          final List<Map<String, dynamic>> result = await db.rawQuery(
            'SELECT total_savings, total_sessions, today_session_count, last_save_date, current_streak, longest_streak, milestones FROM user_progress WHERE id = 1'
          );
          
          if (result.isEmpty) {
            // Initialize if missing
            await _initializeProgress();
            return UserProgress.empty();
          }
          
          final data = result.first;
          
          // Minimal today check - just use approximate day calculation
          final lastSaveDate = data['last_save_date'] as int? ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;
          final isToday = (now - lastSaveDate) < 86400000; // 24 hours in milliseconds
          
          // Create result with minimal processing
          final resultData = <String, dynamic>{
            'total_savings': data['total_savings'],
            'total_sessions': data['total_sessions'],
            'today_session_count': isToday ? data['today_session_count'] : 0,
            'last_save_date': data['last_save_date'],
            'current_streak': data['current_streak'],
            'longest_streak': data['longest_streak'],
            'milestones': data['milestones'],
          };
          
          return UserProgress.fromMap(resultData);
          
        } catch (e) {
          throw DatabaseException(
            DatabaseError.connectionFailed,
            'Failed to get current progress: ${e.toString()}',
            e,
          );
        }
      },
      metadata: {'operation_type': 'get_progress'},
    );
  }
  
  static Future<int> getValidatedCurrentStreak() async {
    return await PerformanceService.monitorDatabaseOperation(
      'getValidatedCurrentStreak',
      () async {
        try {
          final progress = await DatabaseService().getCurrentProgress();
          
          if (progress.lastSaveDate.millisecondsSinceEpoch == 0) {
            return 0; // 아직 저축 안함
          }
          
          final lastSaveDay = progress.lastSaveDate;
          final today = DateTime.now();
          final yesterday = today.subtract(const Duration(days: 1));
          
          // 마지막 저축이 오늘이면 현재 스트릭 유지
          if (_isSameDay(lastSaveDay, today)) {
            return progress.currentStreak;
          }
          
          // 마지막 저축이 어제면 연속 가능 상태 (아직 오늘 저축 안함)
          if (_isSameDay(lastSaveDay, yesterday)) {
            return progress.currentStreak;
          }
          
          // 그 외의 경우 스트릭 깨짐
          return 0;
          
        } catch (e) {
          throw DatabaseException(
            DatabaseError.connectionFailed,
            'Failed to validate current streak: ${e.toString()}',
            e,
          );
        }
      },
      metadata: {'operation_type': 'validate_streak'},
    );
  }
  
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  Future<List<SavingsSession>> getSavingsHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    return await PerformanceService.monitorDatabaseOperation(
      'getSavingsHistory',
      () async {
        try {
          final db = await database;
          
          String whereClause = '';
          List<dynamic> whereArgs = [];
          
          if (startDate != null || endDate != null) {
            whereClause = 'WHERE ';
            List<String> conditions = [];
            
            if (startDate != null) {
              conditions.add('timestamp >= ?');
              whereArgs.add(startDate.millisecondsSinceEpoch);
            }
            
            if (endDate != null) {
              conditions.add('timestamp <= ?');
              whereArgs.add(endDate.millisecondsSinceEpoch);
            }
            
            whereClause += conditions.join(' AND ');
          }
          
          final List<Map<String, dynamic>> maps = await db.rawQuery('''
            SELECT id, amount, timestamp
            FROM savings_sessions
            $whereClause
            ORDER BY timestamp DESC
            LIMIT ?
          ''', [...whereArgs, limit]);
          
          return maps.map((map) => SavingsSession.fromMap(map)).toList();
          
        } catch (e) {
          throw DatabaseException(
            DatabaseError.connectionFailed,
            'Failed to get savings history: ${e.toString()}',
            e,
          );
        }
      },
      metadata: {
        'operation_type': 'get_history',
        'limit': limit,
        'has_date_filter': startDate != null || endDate != null,
      },
    );
  }
  
  Future<void> resetUserData() async {
    try {
      final db = await database;
      
      await db.transaction((txn) async {
        await txn.delete('savings_sessions');
        await txn.delete('user_progress');
        
        // Reinitialize progress
        await txn.insert('user_progress', {
          'id': 1,
          'last_save_date': DateTime.now().millisecondsSinceEpoch,
        });
      });
      
    } catch (e) {
      throw DatabaseException(
        DatabaseError.connectionFailed,
        'Failed to reset user data: ${e.toString()}',
        e,
      );
    }
  }
  
  Future<void> _initializeProgress() async {
    final db = await database;
    await db.insert('user_progress', {
      'id': 1,
      'last_save_date': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  
  List<int> _detectMilestones(int oldTotal, int newTotal) {
    final oldMilestones = (oldTotal / 10000).floor();
    final newMilestones = (newTotal / 10000).floor();
    
    LoggerService.logDatabaseOperation('Milestone detection', {
      'oldTotal': oldTotal,
      'newTotal': newTotal,
      'oldMilestones': oldMilestones,
      'newMilestones': newMilestones,
      'willDetect': newMilestones > oldMilestones,
    });
    
    if (newMilestones > oldMilestones) {
      final milestones = List.generate(
        newMilestones - oldMilestones,
        (i) => (oldMilestones + i + 1) * 10000,
      );
      LoggerService.logDatabaseOperation('Milestones detected', {
        'milestones': milestones,
      });
      return milestones;
    }
    return [];
  }
  
  Future<void> _updateMilestonesInDatabase(List<int> currentMilestones, List<int> newMilestones) async {
    try {
      final db = await database;
      final allMilestones = [...currentMilestones, ...newMilestones];
      final uniqueMilestones = allMilestones.toSet().toList()..sort();
      
      await db.update(
        'user_progress',
        {'milestones': _milestoneListToJson(uniqueMilestones)},
        where: 'id = ?',
        whereArgs: [1],
      );
      
      LoggerService.logDatabaseOperation('Milestones updated in database', {
        'newMilestones': newMilestones,
        'allMilestones': uniqueMilestones,
      });
    } catch (e) {
      LoggerService.error('Failed to update milestones in database', e);
      throw DatabaseException(
        DatabaseError.connectionFailed,
        'Failed to update milestones: ${e.toString()}',
        e,
      );
    }
  }
  
  String _milestoneListToJson(List<int> milestones) {
    // Simple JSON array format: [10000,20000,30000]
    return '[${milestones.join(',')}]';
  }
  
  // Public utility functions for testing
  static bool isMilestone(int amount) {
    return amount > 0 && amount % 10000 == 0;
  }
  
  static List<int> detectNewMilestones(int oldTotal, int newTotal) {
    final oldMilestones = (oldTotal / 10000).floor();
    final newMilestones = (newTotal / 10000).floor();
    
    if (newMilestones > oldMilestones) {
      return List.generate(
        newMilestones - oldMilestones,
        (i) => (oldMilestones + i + 1) * 10000,
      );
    }
    return [];
  }
  
  // For testing - close database connection
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  // For test isolation - use in-memory database
  static void useTestDatabase() {
    _testDbPath = ':memory:';
  }
  
  // For test isolation - use custom test database path
  static void useCustomTestDatabase(String path) {
    _testDbPath = path;
  }
  
  // For test isolation - reset to normal database
  static void useNormalDatabase() {
    _testDbPath = null;
  }
}