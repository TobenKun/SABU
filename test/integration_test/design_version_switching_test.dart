import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sabu/main.dart' as app;
import 'package:sabu/services/database_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Design Version Switching Integration Tests', () {
    late Database testDb;
    
    setUp(() async {
      // Create in-memory test database
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE user_progress(
              id INTEGER PRIMARY KEY,
              total_saved INTEGER NOT NULL DEFAULT 0,
              sessions_completed INTEGER NOT NULL DEFAULT 0,
              milestones_reached TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          
          await db.execute('''
            CREATE TABLE savings_sessions(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount INTEGER NOT NULL,
              timestamp TEXT NOT NULL,
              milestone_reached INTEGER DEFAULT 0
            )
          ''');
          
          await db.execute('''
            CREATE TABLE app_settings(
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        },
      );
      
      // Initialize database service with test database
      await DatabaseService.instance.initializeWithDatabase(testDb);
    });
    
    tearDown(() async {
      await testDb.close();
    });
    
    testWidgets('switching between V1 and V2 preserves savings data', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();
      
      // Add some savings data
      await DatabaseService.instance.saveSavingsSession(5000, DateTime.now());
      await DatabaseService.instance.saveSavingsSession(3000, DateTime.now());
      
      // Verify initial total
      final initialProgress = await DatabaseService.instance.getUserProgress();
      expect(initialProgress.totalSaved, equals(8000));
      expect(initialProgress.sessionsCompleted, equals(2));
      
      // Find and tap settings/version toggle (this would need to be implemented)
      // For now, we'll test the data consistency directly
      
      // Simulate switching to V2
      await DatabaseService.instance.setDesignVersion('V2');
      await tester.pumpAndSettle();
      
      // Verify data is still consistent
      final progressAfterV2 = await DatabaseService.instance.getUserProgress();
      expect(progressAfterV2.totalSaved, equals(8000));
      expect(progressAfterV2.sessionsCompleted, equals(2));
      
      // Add more savings in V2
      await DatabaseService.instance.saveSavingsSession(2000, DateTime.now());
      
      // Switch back to V1
      await DatabaseService.instance.setDesignVersion('V1');
      await tester.pumpAndSettle();
      
      // Verify all data is preserved
      final finalProgress = await DatabaseService.instance.getUserProgress();
      expect(finalProgress.totalSaved, equals(10000));
      expect(finalProgress.sessionsCompleted, equals(3));
      
      // Verify sessions are all there
      final sessions = await DatabaseService.instance.getAllSessions();
      expect(sessions.length, equals(3));
      expect(sessions.map((s) => s.amount).toList(), containsAll([5000, 3000, 2000]));
    });
    
    testWidgets('new user gets V2 by default', (WidgetTester tester) async {
      // Start the app with clean database
      app.main();
      await tester.pumpAndSettle();
      
      // Verify new user gets V2
      final version = await DatabaseService.instance.getDesignVersion();
      expect(version, equals('V2'));
    });
    
    testWidgets('existing user with data gets V1 by default', (WidgetTester tester) async {
      // Add some existing data to simulate existing user
      await DatabaseService.instance.saveSavingsSession(1000, DateTime.now());
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();
      
      // Verify existing user gets V1
      final version = await DatabaseService.instance.getDesignVersion();
      expect(version, equals('V1'));
    });
    
    testWidgets('version preference persists across app restarts', (WidgetTester tester) async {
      // Start app and set to V2
      app.main();
      await tester.pumpAndSettle();
      
      await DatabaseService.instance.setDesignVersion('V2');
      
      // Simulate app restart by reinitializing database service
      await DatabaseService.instance.close();
      await DatabaseService.instance.initializeWithDatabase(testDb);
      
      // Verify preference persisted
      final version = await DatabaseService.instance.getDesignVersion();
      expect(version, equals('V2'));
    });
    
    testWidgets('corrupted version preference falls back to default', (WidgetTester tester) async {
      // Set invalid version preference
      await testDb.insert('app_settings', {
        'key': 'design_version',
        'value': 'INVALID'
      });
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();
      
      // Should fall back to V2 for new user
      final version = await DatabaseService.instance.getDesignVersion();
      expect(version, equals('V2'));
    });
  });
}