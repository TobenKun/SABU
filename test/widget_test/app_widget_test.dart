// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:one_touch_savings/main.dart';
import 'package:one_touch_savings/services/design_version_service.dart';
import 'package:one_touch_savings/models/design_version_setting.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    // Mock SharedPreferences for clean test state
    SharedPreferences.setMockInitialValues({});
    // Mock design version service to return V1 so test behaves like before
    DesignVersionService.setMockCurrentVersion(DesignVersion.v1);
  });

  tearDown(() {
    // Clean up mocks after each test
    DesignVersionService.resetMocks();
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SavingsApp());

    // Wait for the router to complete loading (try a few pumps)
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify that the settings button is present (replaces AppBar title check)
    expect(find.byIcon(Icons.settings), findsOneWidget);
    
    // Verify that the save button text is present
    expect(find.textContaining('저축하기'), findsOneWidget);
  });
}
