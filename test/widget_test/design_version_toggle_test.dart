import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/design_version_setting.dart';
import '../../lib/widgets/design_version_toggle.dart';

void main() {
  group('DesignVersionToggle Widget Tests', () {
    testWidgets('displays current version correctly', (WidgetTester tester) async {
      DesignVersion? selectedVersion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignVersionToggle(
              currentVersion: DesignVersion.v1,
              onVersionChanged: (version) {
                selectedVersion = version;
              },
            ),
          ),
        ),
      );

      // Check that V1 radio is selected
      final v1Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v1,
      );
      final v2Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v2,
      );

      expect(v1Radio, findsOneWidget);
      expect(v2Radio, findsOneWidget);

      // Verify V1 is selected
      final v1RadioWidget = tester.widget<RadioListTile<DesignVersion>>(v1Radio);
      expect(v1RadioWidget.groupValue, DesignVersion.v1);
      
      final v2RadioWidget = tester.widget<RadioListTile<DesignVersion>>(v2Radio);
      expect(v2RadioWidget.groupValue, DesignVersion.v1);
    });

    testWidgets('displays V2 as selected when currentVersion is v2', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignVersionToggle(
              currentVersion: DesignVersion.v2,
              onVersionChanged: (version) {},
            ),
          ),
        ),
      );

      final v1Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v1,
      );
      final v2Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v2,
      );

      // Verify V2 is selected
      final v1RadioWidget = tester.widget<RadioListTile<DesignVersion>>(v1Radio);
      expect(v1RadioWidget.groupValue, DesignVersion.v2);
      
      final v2RadioWidget = tester.widget<RadioListTile<DesignVersion>>(v2Radio);
      expect(v2RadioWidget.groupValue, DesignVersion.v2);
    });

    testWidgets('triggers callback when V1 is selected', (WidgetTester tester) async {
      DesignVersion? selectedVersion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignVersionToggle(
              currentVersion: DesignVersion.v2,
              onVersionChanged: (version) {
                selectedVersion = version;
              },
            ),
          ),
        ),
      );

      // Tap on V1 radio
      final v1Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v1,
      );
      
      await tester.tap(v1Radio);
      await tester.pump();

      expect(selectedVersion, DesignVersion.v1);
    });

    testWidgets('triggers callback when V2 is selected', (WidgetTester tester) async {
      DesignVersion? selectedVersion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignVersionToggle(
              currentVersion: DesignVersion.v1,
              onVersionChanged: (version) {
                selectedVersion = version;
              },
            ),
          ),
        ),
      );

      // Tap on V2 radio
      final v2Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v2,
      );
      
      await tester.tap(v2Radio);
      await tester.pump();

      expect(selectedVersion, DesignVersion.v2);
    });

    testWidgets('displays correct labels and descriptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignVersionToggle(
              currentVersion: DesignVersion.v1,
              onVersionChanged: (version) {},
            ),
          ),
        ),
      );

      // Check for main title
      expect(find.text('인터페이스 버전'), findsOneWidget);

      // Check for V1 option
      expect(find.text('V1 - 전체 기능'), findsOneWidget);
      expect(find.text('모든 차트와 통계 표시'), findsOneWidget);

      // Check for V2 option
      expect(find.text('V2 - 간단한 화면'), findsOneWidget);
      expect(find.text('필수 기능만 + 귀여운 거북이'), findsOneWidget);
    });

    testWidgets('has proper card styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignVersionToggle(
              currentVersion: DesignVersion.v1,
              onVersionChanged: (version) {},
            ),
          ),
        ),
      );

      // Check that widget is wrapped in a Card
      expect(find.byType(Card), findsOneWidget);

      // Check that content has proper padding
      final paddingFinder = find.byWidgetPredicate(
        (widget) => widget is Padding && 
                   widget.padding == const EdgeInsets.all(16.0),
      );
      expect(paddingFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('maintains selection state correctly', (WidgetTester tester) async {
      DesignVersion currentVersion = DesignVersion.v1;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: DesignVersionToggle(
                  currentVersion: currentVersion,
                  onVersionChanged: (version) {
                    setState(() {
                      currentVersion = version;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Initially V1 should be selected
      final v1Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v1,
      );
      final v1RadioWidget = tester.widget<RadioListTile<DesignVersion>>(v1Radio);
      expect(v1RadioWidget.groupValue, DesignVersion.v1);

      // Tap V2
      final v2Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v2,
      );
      await tester.tap(v2Radio);
      await tester.pump();

      // Now V2 should be selected
      final v1RadioUpdated = tester.widget<RadioListTile<DesignVersion>>(v1Radio);
      final v2RadioUpdated = tester.widget<RadioListTile<DesignVersion>>(v2Radio);
      expect(v1RadioUpdated.groupValue, DesignVersion.v2);
      expect(v2RadioUpdated.groupValue, DesignVersion.v2);
    });

    testWidgets('handles rapid selection changes', (WidgetTester tester) async {
      final List<DesignVersion> selections = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignVersionToggle(
              currentVersion: DesignVersion.v1,
              onVersionChanged: (version) {
                selections.add(version);
              },
            ),
          ),
        ),
      );

      final v1Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v1,
      );
      final v2Radio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<DesignVersion> && 
                   widget.value == DesignVersion.v2,
      );

      // Rapid selections
      await tester.tap(v2Radio);
      await tester.pump();
      await tester.tap(v1Radio);
      await tester.pump();
      await tester.tap(v2Radio);
      await tester.pump();

      expect(selections, [
        DesignVersion.v2,
        DesignVersion.v1,
        DesignVersion.v2,
      ]);
    });
  });
}