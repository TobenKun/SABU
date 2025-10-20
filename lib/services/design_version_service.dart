import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/design_version_setting.dart';
import 'database_service.dart';

class DesignVersionService {
  static const String _designVersionKey = 'design_version_preference';
  static const String _hasSeenIntroKey = 'has_seen_v2_introduction';
  static const String _lastSwitchKey = 'last_version_switch_timestamp';
  static const String _switchCountKey = 'version_switch_count';
  static const String _firstRunKey = 'is_first_run_completed';

  // Singleton pattern
  static final DesignVersionService _instance = DesignVersionService._internal();
  factory DesignVersionService() => _instance;
  DesignVersionService._internal();

  // Stream controller for version change notifications
  final StreamController<DesignVersionChange> _versionChangeController =
      StreamController<DesignVersionChange>.broadcast();

  Stream<DesignVersionChange> get versionChangeStream =>
      _versionChangeController.stream;

  /// Get user's current interface preference
  /// Returns V1 for existing users, V2 for new users by default
  Future<DesignVersion> getCurrentDesignVersion() async {
    // Support for testing mocks
    if (_mockCurrentVersion != null) {
      return _mockCurrentVersion!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final versionString = prefs.getString(_designVersionKey);

      if (versionString != null) {
        // User has a saved preference
        return DesignVersion.fromString(versionString);
      }

      // No saved preference - determine default based on user type
      final isFirst = await isFirstTimeUser();
      return isFirst ? DesignVersion.v2 : DesignVersion.v1;
    } catch (e) {
      // Error reading preferences - fallback to V1 (safe default)
      return DesignVersion.v1;
    }
  }

  /// Update user's interface preference
  Future<void> setDesignVersion(DesignVersion version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldVersion = await getCurrentDesignVersion();

      // Save new version
      await prefs.setString(_designVersionKey, version.value);

      // Update analytics
      final currentTime = DateTime.now();
      await prefs.setInt(_lastSwitchKey, currentTime.millisecondsSinceEpoch);

      final currentCount = prefs.getInt(_switchCountKey) ?? 0;
      await prefs.setInt(_switchCountKey, currentCount + 1);

      // Notify listeners of the change
      _versionChangeController.add(DesignVersionChange(
        oldVersion: oldVersion,
        newVersion: version,
        timestamp: currentTime,
        trigger: 'user_choice',
      ));
    } catch (e) {
      // If persistence fails, continue with in-memory state
      // The change will still be notified to UI components
      rethrow;
    }
  }

  /// Check if user has viewed V2 tutorial/introduction
  Future<bool> hasSeenV2Introduction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenIntroKey) ?? false;
    } catch (e) {
      return false; // Safe default - show introduction
    }
  }

  /// Record that user has completed V2 introduction
  Future<void> markV2IntroductionSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenIntroKey, true);
    } catch (e) {
      // If persistence fails, continue gracefully
      // Introduction might be shown again, but that's acceptable
    }
  }

  /// Detect if this is a new user (no existing savings data)
  Future<bool> isFirstTimeUser() async {
    // Support for testing mocks
    if (_mockIsFirstTimeUser != null) {
      return _mockIsFirstTimeUser!;
    }

    try {
      final progress = await DatabaseService().getCurrentProgress();
      // Consider a user "existing" if they have any savings or sessions
      return progress.totalSavings == 0 && progress.totalSessions == 0;
    } catch (e) {
      // If database check fails, assume new user (safer for UX)
      return true;
    }
  }

  /// Initialize design version settings for new installation
  Future<void> performFirstRunSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if first run setup already completed
      final isCompleted = prefs.getBool(_firstRunKey) ?? false;
      if (isCompleted) return;

      final isFirst = await isFirstTimeUser();
      final defaultVersion = isFirst ? DesignVersion.v2 : DesignVersion.v1;

      // Set default version if not already set
      final existingVersion = prefs.getString(_designVersionKey);
      if (existingVersion == null) {
        await prefs.setString(_designVersionKey, defaultVersion.value);

        // Notify of initial setup
        _versionChangeController.add(DesignVersionChange(
          oldVersion: DesignVersion.v1, // Arbitrary old version for setup
          newVersion: defaultVersion,
          timestamp: DateTime.now(),
          trigger: 'first_run',
        ));
      }

      // Initialize analytics counters
      if (!prefs.containsKey(_switchCountKey)) {
        await prefs.setInt(_switchCountKey, 0);
      }

      // Mark setup as completed
      await prefs.setBool(_firstRunKey, true);
    } catch (e) {
      // If setup fails, continue gracefully
      // App will still function with default behaviors
    }
  }

  /// Retrieve version switching analytics
  Future<DesignVersionStats> getUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalSwitches = prefs.getInt(_switchCountKey) ?? 0;
      final lastSwitchMs = prefs.getInt(_lastSwitchKey);
      final currentVersion = await getCurrentDesignVersion();

      DateTime? lastSwitchTimestamp;
      if (lastSwitchMs != null) {
        lastSwitchTimestamp = DateTime.fromMillisecondsSinceEpoch(lastSwitchMs);
      }

      return DesignVersionStats(
        totalSwitches: totalSwitches,
        lastSwitchTimestamp: lastSwitchTimestamp,
        timeInV1: Duration.zero, // TODO: Track usage time in future
        timeInV2: Duration.zero, // TODO: Track usage time in future
        preferredVersion: currentVersion, // Current version as preference
      );
    } catch (e) {
      // Return empty stats on error
      return const DesignVersionStats(
        totalSwitches: 0,
        preferredVersion: DesignVersion.v2,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _versionChangeController.close();
  }

  // Testing support methods
  /// Clear all preferences (for testing)
  Future<void> clearAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_designVersionKey);
      await prefs.remove(_hasSeenIntroKey);
      await prefs.remove(_lastSwitchKey);
      await prefs.remove(_switchCountKey);
      await prefs.remove(_firstRunKey);
    } catch (e) {
      // Ignore errors during test cleanup
    }
  }

  /// Set mock first time user state (for testing)
  static bool? _mockIsFirstTimeUser;
  static void setMockFirstTimeUser(bool isFirstTime) {
    _mockIsFirstTimeUser = isFirstTime;
  }

  /// Set mock current version (for testing)
  static DesignVersion? _mockCurrentVersion;
  static void setMockCurrentVersion(DesignVersion version) {
    _mockCurrentVersion = version;
  }

  /// Reset mocks (for testing)
  static void resetMocks() {
    _mockIsFirstTimeUser = null;
    _mockCurrentVersion = null;
  }
}