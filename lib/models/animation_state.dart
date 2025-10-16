enum TurtleAnimationLevel {
  idle(1),           // 16+ hours inactivity
  walkSlow(2),       // 8-16 hours inactivity  
  walkFast(3),       // 4-8 hours inactivity
  runSlow(4),        // 2-4 hours inactivity
  runFast(5);        // 0-2 hours inactivity

  const TurtleAnimationLevel(this.level);
  final int level;

  static TurtleAnimationLevel fromString(String? value) {
    switch (value) {
      case 'idle':
        return TurtleAnimationLevel.idle;
      case 'walkSlow':
        return TurtleAnimationLevel.walkSlow;
      case 'walkFast':
        return TurtleAnimationLevel.walkFast;
      case 'runSlow':
        return TurtleAnimationLevel.runSlow;
      case 'runFast':
        return TurtleAnimationLevel.runFast;
      default:
        return TurtleAnimationLevel.idle;
    }
  }
}

class AnimationState {
  final TurtleAnimationLevel level;
  final DateTime lastActivity;
  final int totalActivityCount;
  final List<DateTime> recentActivities; // 최근 활동 시간들
  final DateTime? levelStartTime; // 현재 레벨 시작 시간

  const AnimationState({
    required this.level,
    required this.lastActivity,
    required this.totalActivityCount,
    this.recentActivities = const [],
    this.levelStartTime,
  });

  AnimationState copyWith({
    TurtleAnimationLevel? level,
    DateTime? lastActivity,
    int? totalActivityCount,
    List<DateTime>? recentActivities,
    DateTime? levelStartTime,
  }) {
    return AnimationState(
      level: level ?? this.level,
      lastActivity: lastActivity ?? this.lastActivity,
      totalActivityCount: totalActivityCount ?? this.totalActivityCount,
      recentActivities: recentActivities ?? this.recentActivities,
      levelStartTime: levelStartTime ?? this.levelStartTime,
    );
  }

  // 최근 2시간 내 활동 횟수 계산
  int getRecentActivityCount({Duration timeWindow = const Duration(hours: 2)}) {
    final cutoff = DateTime.now().subtract(timeWindow);
    return recentActivities.where((activity) => activity.isAfter(cutoff)).length;
  }

  // 현재 레벨에서 머문 시간 계산
  Duration getCurrentLevelDuration() {
    if (levelStartTime == null) return Duration.zero;
    return DateTime.now().difference(levelStartTime!);
  }

  // 점진적 레벨 상승 로직
  static TurtleAnimationLevel calculateProgressiveLevel({
    required TurtleAnimationLevel currentLevel,
    required int recentActivityCount,
    required Duration currentLevelDuration,
  }) {
    // runFast에서 추가 활동 시 상태 유지 (지속 시간 연장)
    if (currentLevel == TurtleAnimationLevel.runFast) {
      return TurtleAnimationLevel.runFast;
    }

    // 점진적 상승 로직
    switch (currentLevel) {
      case TurtleAnimationLevel.idle:
        // idle에서 1-2회 활동 시 walkSlow로
        if (recentActivityCount >= 1) {
          return TurtleAnimationLevel.walkSlow;
        }
        break;
      
      case TurtleAnimationLevel.walkSlow:
        // walkSlow에서 3-4회 활동 시 walkFast로
        if (recentActivityCount >= 3) {
          return TurtleAnimationLevel.walkFast;
        }
        break;
      
      case TurtleAnimationLevel.walkFast:
        // walkFast에서 5-6회 활동 시 runSlow로
        if (recentActivityCount >= 5) {
          return TurtleAnimationLevel.runSlow;
        }
        break;
      
      case TurtleAnimationLevel.runSlow:
        // runSlow에서 7-8회 활동 시 runFast로
        if (recentActivityCount >= 7) {
          return TurtleAnimationLevel.runFast;
        }
        break;
      
      case TurtleAnimationLevel.runFast:
        // 이미 최고 레벨
        break;
    }

    return currentLevel;
  }

  static TurtleAnimationLevel calculateLevelFromTime(DateTime lastActivity) {
    final elapsed = DateTime.now().difference(lastActivity);
    final hours = elapsed.inHours;

    if (hours >= 16) return TurtleAnimationLevel.idle;
    if (hours >= 8) return TurtleAnimationLevel.walkSlow;
    if (hours >= 4) return TurtleAnimationLevel.walkFast;
    if (hours >= 2) return TurtleAnimationLevel.runSlow;
    return TurtleAnimationLevel.runFast;
  }
}