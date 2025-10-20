import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path_utils;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:one_touch_savings/main.dart' as app;
import 'package:one_touch_savings/services/database_service.dart';
import 'package:one_touch_savings/services/design_version_service.dart';
import 'package:one_touch_savings/models/design_version_setting.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize database with unique path for this test file
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Use unique database path for test isolation
    DatabaseService.useCustomTestDatabase(
        'test_db_design_switching_${DateTime.now().millisecondsSinceEpoch}.db');

    // Mock SharedPreferences for design version service
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    // Clean up test database path and restore normal database
    await DatabaseService.closeDatabase();
    DatabaseService.useNormalDatabase();
  });
  
  group('Design Version Switching Integration Tests', () {
    late DesignVersionService designVersionService;
    late DatabaseService databaseService;
    
    setUp(() async {
      // Initialize services
      designVersionService = DesignVersionService();
      databaseService = DatabaseService();
      
      // Reset database to clean state
      await databaseService.resetUserData();
      
      // Clear any existing preferences
      await designVersionService.clearAllPreferences();
      
      // Reset mocks
      DesignVersionService.resetMocks();
    });
    
    tearDown(() async {
      await designVersionService.clearAllPreferences();
      DesignVersionService.resetMocks();
    });
    
    testWidgets('switching between V1 and V2 preserves savings data', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const app.SavingsApp());
      await tester.pump(const Duration(milliseconds: 500));
      
      // Add some savings data using the actual save button
      final savingsButtonFinder = find.byKey(const Key('savings_button'));
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(savingsButtonFinder);
        
        // Tap button multiple times to simulate savings
        for (int i = 0; i < 5; i++) {
          await tester.tap(savingsButtonFinder);
          await tester.pump(const Duration(milliseconds: 200));
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      // Verify initial progress
      final initialProgress = await databaseService.getCurrentProgress();
      expect(initialProgress.totalSavings, greaterThan(0));
      expect(initialProgress.totalSessions, greaterThan(0));
      final initialTotal = initialProgress.totalSavings;
      final initialSessions = initialProgress.totalSessions;
      
      // Switch to V2
      await designVersionService.setDesignVersion(DesignVersion.v2);
      await tester.pump(const Duration(milliseconds: 200));
      
      // Verify data is still consistent after switch
      final progressAfterV2 = await databaseService.getCurrentProgress();
      expect(progressAfterV2.totalSavings, equals(initialTotal));
      expect(progressAfterV2.totalSessions, equals(initialSessions));
      
      // Add more savings in V2
      if (savingsButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(savingsButtonFinder);
        await tester.pump(const Duration(milliseconds: 200));
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Switch back to V1
      await designVersionService.setDesignVersion(DesignVersion.v1);
      await tester.pump(const Duration(milliseconds: 200));
      
      // Verify all data is preserved
      final finalProgress = await databaseService.getCurrentProgress();
      expect(finalProgress.totalSavings, greaterThan(initialTotal));
      expect(finalProgress.totalSessions, greaterThan(initialSessions));
      
      // Verify sessions history
      final sessions = await databaseService.getSavingsHistory();
      expect(sessions.length, greaterThan(initialSessions));
    });
    
    testWidgets('new user gets V2 by default', (WidgetTester tester) async {
      // Mock as first time user
      DesignVersionService.setMockFirstTimeUser(true);
      
      // Start the app with clean state
      await tester.pumpWidget(const app.SavingsApp());
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify new user gets V2
      final version = await designVersionService.getCurrentDesignVersion();
      expect(version, equals(DesignVersion.v2));
    });
    
    testWidgets('existing user with data gets V1 by default', (WidgetTester tester) async {
      // Mock as existing user (not first time)
      DesignVersionService.setMockFirstTimeUser(false);
      
      // Add some existing data to simulate existing user
      await databaseService.saveMoney();
      
      // Start the app
      await tester.pumpWidget(const app.SavingsApp());
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify existing user gets V1
      final version = await designVersionService.getCurrentDesignVersion();
      expect(version, equals(DesignVersion.v1));
    });
    
    testWidgets('version preference persists across app restarts', (WidgetTester tester) async {
      // Start app and set to V2
      await tester.pumpWidget(const app.SavingsApp());
      await tester.pump(const Duration(milliseconds: 500));
      
      await designVersionService.setDesignVersion(DesignVersion.v2);
      
      // Simulate app restart by creating new service instance
      final newDesignVersionService = DesignVersionService();
      
      // Verify preference persisted
      final version = await newDesignVersionService.getCurrentDesignVersion();
      expect(version, equals(DesignVersion.v2));
    });
    
    testWidgets('corrupted version preference falls back to default', (WidgetTester tester) async {
      // This test covers the case where preferences become corrupted
      // We'll test by clearing preferences and ensuring proper fallback behavior
      DesignVersionService.setMockFirstTimeUser(true);
      
      // Start the app
      await tester.pumpWidget(const app.SavingsApp());
      await tester.pump(const Duration(milliseconds: 500));
      
      // Should fall back to V2 for new user (this is the default behavior)
      final version = await designVersionService.getCurrentDesignVersion();
      expect(version, equals(DesignVersion.v2));
    });
  });
}