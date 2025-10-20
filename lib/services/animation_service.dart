import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animation_state.dart';

class AnimationTimerService {
  static const String lastActivityKey = 'last_activity_timestamp';
  static const String animationLevelKey = 'turtle_animation_level';
  static const String totalActivityCountKey = 'total_activity_count';
  static const String recentActivitiesKey = 'recent_activities';
  static const String levelStartTimeKey = 'level_start_time';

  Timer? _periodicTimer;
  final StreamController<TurtleAnimationLevel> _animationController = 
      StreamController<TurtleAnimationLevel>.broadcast();
  
  AnimationState? _currentState;
  bool _isInitialized = false;

  Stream<TurtleAnimationLevel> get animationLevelStream => 
      _animationController.stream;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadStateFromPrefs();
      _isInitialized = true;
    }
  }

  Future<TurtleAnimationLevel> getInitialAnimationLevel() async {
    await _ensureInitialized();
    return getCurrentAnimationLevel();
  }

  TurtleAnimationLevel getCurrentAnimationLevel() {
    if (_currentState == null) {
      return TurtleAnimationLevel.idle;
    }

    // Check if we need to step down due to inactivity (only step down, never up)
    final timeBased = AnimationState.calculateLevelFromTime(_currentState!.lastActivity);
    
    // Only update if time-based level is lower than current level (natural decay)
    if (timeBased.level < _currentState!.level.level) {
      _currentState = _currentState!.copyWith(
        level: timeBased,
        levelStartTime: DateTime.now(), // Reset level start time when stepping down
      );
      _saveStateToPrefs();
      _animationController.add(timeBased);
    }

    return _currentState!.level;
  }

  Future<void> onUserSavingsAction() async {
    await _ensureInitialized();
    
    final now = DateTime.now();
    final currentState = _currentState!;
    
    // 최근 활동 목록 업데이트 (최근 2시간 내 활동만 유지)
    final cutoff = now.subtract(const Duration(hours: 2));
    final updatedRecentActivities = [
      ...currentState.recentActivities.where((activity) => activity.isAfter(cutoff)),
      now, // 현재 활동 추가
    ];
    
    // 점진적 레벨 계산
    final recentActivityCount = updatedRecentActivities.length;
    final currentLevelDuration = currentState.getCurrentLevelDuration();
    
    final newLevel = AnimationState.calculateProgressiveLevel(
      currentLevel: currentState.level,
      recentActivityCount: recentActivityCount,
      currentLevelDuration: currentLevelDuration,
    );
    
    // 레벨이 변경되었거나 runFast에서 활동 시 levelStartTime 업데이트
    final shouldUpdateLevelStartTime = newLevel != currentState.level || 
        (newLevel == TurtleAnimationLevel.runFast);
    
    _currentState = currentState.copyWith(
      level: newLevel,
      lastActivity: now,
      totalActivityCount: currentState.totalActivityCount + 1,
      recentActivities: updatedRecentActivities,
      levelStartTime: shouldUpdateLevelStartTime ? now : currentState.levelStartTime,
    );

    await _saveStateToPrefs();
    _animationController.add(newLevel);
  }

  // DEBUG: Method to manually set animation level (TODO: Remove in production)
  Future<void> setAnimationLevel(TurtleAnimationLevel level) async {
    await _ensureInitialized();
    
    final now = DateTime.now();
    _currentState = _currentState?.copyWith(
      level: level,
      levelStartTime: now,
    ) ?? AnimationState(
      level: level,
      lastActivity: now,
      totalActivityCount: 0,
      recentActivities: [],
      levelStartTime: now,
    );

    await _saveStateToPrefs();
    _animationController.add(level);
  }

  void startPeriodicUpdates() {
    _periodicTimer?.cancel();
    
    try {
      // Check if we're in a test environment - multiple ways to detect
      bool isTestEnvironment = false;
      
      // Method 1: Check environment variables
      try {
        isTestEnvironment = const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
                           Platform.environment.containsKey('FLUTTER_TEST') ||
                           Platform.environment['UNIT_TEST_ASSETS'] != null;
      } catch (e) {
        // Platform.environment might not be available in some test contexts
      }
      
      // Method 2: Check if we're running in flutter_tester
      try {
        isTestEnvironment = isTestEnvironment || Platform.executable.contains('flutter_tester');
      } catch (e) {
        // Platform.executable might not be available
      }
      
      if (isTestEnvironment) {
        // Skip periodic updates in test environment to prevent hanging
        print('Skipping periodic updates in test environment');
        return;
      }
      
      _periodicTimer = Timer.periodic(
        const Duration(minutes: 30), 
        (_) => _checkForLevelChange()
      );
    } catch (e) {
      // Graceful fallback if timer creation fails
      print('Failed to start periodic updates: $e');
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _animationController.close();
  }

  void _checkForLevelChange() {
    getCurrentAnimationLevel();
    // getCurrentAnimationLevel already handles level changes and notifications
  }

  Future<void> _loadStateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lastActivityMs = prefs.getInt(lastActivityKey);
      final levelString = prefs.getString(animationLevelKey);
      final totalCount = prefs.getInt(totalActivityCountKey) ?? 0;
      final recentActivitiesStrings = prefs.getStringList(recentActivitiesKey) ?? [];
      final levelStartTimeMs = prefs.getInt(levelStartTimeKey);

      if (lastActivityMs != null) {
        final lastActivity = DateTime.fromMillisecondsSinceEpoch(lastActivityMs);
        final level = TurtleAnimationLevel.fromString(levelString);
        
        // Parse recent activities from stored strings
        final recentActivities = recentActivitiesStrings
            .map((ms) => DateTime.fromMillisecondsSinceEpoch(int.parse(ms)))
            .toList();
        
        // Parse level start time if exists
        DateTime? levelStartTime;
        if (levelStartTimeMs != null) {
          levelStartTime = DateTime.fromMillisecondsSinceEpoch(levelStartTimeMs);
        }
        
        _currentState = AnimationState(
          level: level,
          lastActivity: lastActivity,
          totalActivityCount: totalCount,
          recentActivities: recentActivities,
          levelStartTime: levelStartTime,
        );
      } else {
        // First time - default state
        final now = DateTime.now();
        _currentState = AnimationState(
          level: TurtleAnimationLevel.idle,
          lastActivity: now,
          totalActivityCount: 0,
          recentActivities: [],
          levelStartTime: now,
        );
      }
    } catch (e) {
      // Fallback to default state if SharedPreferences fails
      final now = DateTime.now();
      _currentState = AnimationState(
        level: TurtleAnimationLevel.idle,
        lastActivity: now,
        totalActivityCount: 0,
        recentActivities: [],
        levelStartTime: now,
      );
    }
  }

  Future<void> _saveStateToPrefs() async {
    if (_currentState == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(lastActivityKey, 
          _currentState!.lastActivity.millisecondsSinceEpoch);
      await prefs.setString(animationLevelKey, 
          _currentState!.level.name);
      await prefs.setInt(totalActivityCountKey, 
          _currentState!.totalActivityCount);
      
      // Save recent activities as list of timestamp strings
      final recentActivitiesStrings = _currentState!.recentActivities
          .map((activity) => activity.millisecondsSinceEpoch.toString())
          .toList();
      await prefs.setStringList(recentActivitiesKey, recentActivitiesStrings);
      
      // Save level start time if exists
      if (_currentState!.levelStartTime != null) {
        await prefs.setInt(levelStartTimeKey, 
            _currentState!.levelStartTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      print('Failed to save animation state: $e');
    }
  }
}