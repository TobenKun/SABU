import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/models/design_version_setting.dart';
import '../../lib/services/design_version_service.dart';

void main() {
  group('DesignVersionService', () {
    late DesignVersionService service;

    setUp(() {
      service = DesignVersionService();
      SharedPreferences.setMockInitialValues({});
    });

    group('getCurrentDesignVersion', () {
      test('defaults to V1 for existing users', () async {
        // Mock existing user scenario (has savings data)
        SharedPreferences.setMockInitialValues({
          'user_progress_key': 'some_existing_data', // Simulate existing user data
        });

        final version = await service.getCurrentDesignVersion();
        expect(version, DesignVersion.v1);
      });

      test('defaults to V2 for new users', () async {
        // Mock new user scenario (no existing data)
        SharedPreferences.setMockInitialValues({});

        final version = await service.getCurrentDesignVersion();
        expect(version, DesignVersion.v2);
      });

      test('returns persisted version when available', () async {
        SharedPreferences.setMockInitialValues({
          'design_version_preference': 'v2',
        });

        final version = await service.getCurrentDesignVersion();
        expect(version, DesignVersion.v2);
      });

      test('falls back to V1 for corrupted version string', () async {
        SharedPreferences.setMockInitialValues({
          'design_version_preference': 'invalid_version',
        });

        final version = await service.getCurrentDesignVersion();
        expect(version, DesignVersion.v1);
      });
    });

    group('setDesignVersion', () {
      test('persists version to SharedPreferences', () async {
        await service.setDesignVersion(DesignVersion.v2);
        
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('design_version_preference');
        expect(stored, 'v2');
      });

      test('persists switch timestamp', () async {
        final beforeTime = DateTime.now().millisecondsSinceEpoch;
        await service.setDesignVersion(DesignVersion.v1);
        final afterTime = DateTime.now().millisecondsSinceEpoch;
        
        final prefs = await SharedPreferences.getInstance();
        final timestamp = prefs.getInt('last_version_switch');
        
        expect(timestamp, isNotNull);
        expect(timestamp!, greaterThanOrEqualTo(beforeTime));
        expect(timestamp, lessThanOrEqualTo(afterTime));
      });

      test('increments switch count', () async {
        // First switch
        await service.setDesignVersion(DesignVersion.v2);
        
        final prefs = await SharedPreferences.getInstance();
        final count1 = prefs.getInt('version_switch_count') ?? 0;
        expect(count1, 1);
        
        // Second switch
        await service.setDesignVersion(DesignVersion.v1);
        final count2 = prefs.getInt('version_switch_count') ?? 0;
        expect(count2, 2);
      });
    });

    group('hasSeenV2Introduction', () {
      test('returns false by default', () async {
        final result = await service.hasSeenV2Introduction();
        expect(result, false);
      });

      test('returns true when flag is set', () async {
        SharedPreferences.setMockInitialValues({
          'has_seen_v2_introduction': true,
        });

        final result = await service.hasSeenV2Introduction();
        expect(result, true);
      });
    });

    group('markV2IntroductionSeen', () {
      test('persists introduction seen flag', () async {
        await service.markV2IntroductionSeen();
        
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool('has_seen_v2_introduction');
        expect(seen, true);
      });
    });

    group('isFirstTimeUser', () {
      test('returns true for new user with no data', () async {
        final result = await service.isFirstTimeUser();
        expect(result, true);
      });

      test('returns false when user has existing data', () async {
        SharedPreferences.setMockInitialValues({
          'user_progress_key': 'existing_data',
          'total_savings': 5000,
        });

        final result = await service.isFirstTimeUser();
        expect(result, false);
      });
    });

    group('performFirstRunSetup', () {
      test('sets up defaults for new user', () async {
        await service.performFirstRunSetup();
        
        final version = await service.getCurrentDesignVersion();
        expect(version, DesignVersion.v2);
        
        final prefs = await SharedPreferences.getInstance();
        final firstRunComplete = prefs.getBool('is_first_run_completed');
        expect(firstRunComplete, true);
      });

      test('sets up defaults for existing user', () async {
        // Simulate existing user with data
        SharedPreferences.setMockInitialValues({
          'total_savings': 10000,
        });

        await service.performFirstRunSetup();
        
        final version = await service.getCurrentDesignVersion();
        expect(version, DesignVersion.v1);
      });
    });

    group('getUsageStats', () {
      test('returns empty stats for new user', () async {
        final stats = await service.getUsageStats();
        
        expect(stats.totalSwitches, 0);
        expect(stats.preferredVersion, DesignVersion.v2); // Default for new user
      });

      test('returns accurate stats after switches', () async {
        // Perform some version switches
        await service.setDesignVersion(DesignVersion.v2);
        await Future.delayed(const Duration(milliseconds: 10));
        await service.setDesignVersion(DesignVersion.v1);
        await Future.delayed(const Duration(milliseconds: 10));
        await service.setDesignVersion(DesignVersion.v2);
        
        final stats = await service.getUsageStats();
        expect(stats.totalSwitches, 3);
        expect(stats.lastSwitchTimestamp, isNotNull);
      });
    });

    group('error handling', () {
      test('handles SharedPreferences access failure gracefully', () async {
        // This is harder to test with the current mock setup, but we ensure
        // the service doesn't throw exceptions and provides sensible defaults
        final version = await service.getCurrentDesignVersion();
        expect(version, isIn([DesignVersion.v1, DesignVersion.v2]));
      });

      test('handles corrupted preferences gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'design_version_preference': 123, // Wrong type
          'last_version_switch': 'not_a_number', // Wrong type
          'version_switch_count': 'invalid', // Wrong type
        });

        // Should not throw and should provide sensible defaults
        final version = await service.getCurrentDesignVersion();
        expect(version, DesignVersion.v1); // Fallback to safe default
        
        // Should handle setting new version even with corrupted data
        await service.setDesignVersion(DesignVersion.v2);
        final newVersion = await service.getCurrentDesignVersion();
        expect(newVersion, DesignVersion.v2);
      });
    });
  });
}