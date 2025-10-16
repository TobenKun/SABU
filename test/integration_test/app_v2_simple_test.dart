import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:one_touch_savings/services/database_service.dart';
import 'package:one_touch_savings/screens/home_screen_v2.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize database with unique path for this test file
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Use unique database path for test isolation
    DatabaseService.useCustomTestDatabase('test_db_v2_simple_${DateTime.now().millisecondsSinceEpoch}.db');
    
    // Mock SharedPreferences with complete setup for animation service
    SharedPreferences.setMockInitialValues({
      'last_activity_timestamp': DateTime.now().millisecondsSinceEpoch,
      'turtle_animation_level': 'idle',
      'total_activity_count': 0,
      'recent_activities': <String>[],
      'level_start_time': DateTime.now().millisecondsSinceEpoch,
    });
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
  });

  tearDownAll(() async {
    // Clean up test database path and restore normal database
    await DatabaseService.closeDatabase();
    DatabaseService.useNormalDatabase();
  });

  group('HomeScreenV2: Basic Tests', () {
    testWidgets('V2 minimal load test', (WidgetTester tester) async {
      // Simple test to see if V2 can load at all
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      
      // Just try to pump once and see what happens
      await tester.pump();
      
      // Basic existence check
      expect(find.byType(Scaffold), findsOneWidget);
    });
    
    testWidgets('V2 components load test', (WidgetTester tester) async {
      // Reset database for clean test
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreenV2(),
          debugShowCheckedModeBanner: false,
        ),
      );
      
      // Wait for initial load
      await tester.pump(const Duration(milliseconds: 100));
      
      // Check basic components exist
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('지금까지 저축한 금액'), findsOneWidget);
      expect(find.byKey(const Key('savings_button')), findsOneWidget);
    });
  });
}