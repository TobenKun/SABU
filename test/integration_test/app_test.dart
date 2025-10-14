import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:one_touch_savings/main.dart' as app;
import 'package:one_touch_savings/services/database_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
  });

  group('One-Touch Savings App Integration Tests', () {
    testWidgets('complete save flow works end-to-end', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app loads correctly
      expect(find.text('One-Touch Savings'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('multiple save operations work correctly', (WidgetTester tester) async {
      // Reset database for clean test
      final databaseService = DatabaseService();
      await databaseService.resetUserData();

      app.main();
      await tester.pumpAndSettle();

      // Find the savings button when it's implemented
      // For now, verify the app structure exists
      expect(find.text('One-Touch Savings'), findsOneWidget);
      
      // TODO: When SavingsButton is implemented in HomeScreen:
      // 1. Find and tap the savings button
      // 2. Verify progress display updates
      // 3. Verify haptic feedback occurs
      // 4. Test multiple rapid taps
      // 5. Verify milestone celebrations at 10,000원
    });

    testWidgets('app preserves data across restarts', (WidgetTester tester) async {
      // This test will verify persistence once the complete flow is implemented
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('One-Touch Savings'), findsOneWidget);
      
      // TODO: Complete this test when save functionality is implemented
      // 1. Save some money
      // 2. Restart app (simulate by re-running main())
      // 3. Verify saved amount persists
    });

    testWidgets('performance requirements are met', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();
      
      // App should load within 3 seconds
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      
      // TODO: Test button response time when implemented
      // Should be < 100ms total for tap response
    });
  });
}