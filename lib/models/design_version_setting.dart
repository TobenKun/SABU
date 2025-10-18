enum DesignVersion {
  v1,    // Full interface with all widgets (default for existing users)
  v2;    // Simplified interface with essentials + turtle

  String get value {
    switch (this) {
      case DesignVersion.v1:
        return 'v1';
      case DesignVersion.v2:
        return 'v2';
    }
  }

  static DesignVersion fromString(String value) {
    switch (value.toLowerCase()) {
      case 'v1':
        return DesignVersion.v1;
      case 'v2':
        return DesignVersion.v2;
      default:
        return DesignVersion.v1; // Safe fallback
    }
  }
}

class DesignVersionSetting {
  final DesignVersion currentVersion;
  final bool hasSeenV2Introduction;
  final DateTime? lastSwitchTimestamp;
  final int switchCount;
  final bool isFirstRunCompleted;

  const DesignVersionSetting({
    required this.currentVersion,
    this.hasSeenV2Introduction = false,
    this.lastSwitchTimestamp,
    this.switchCount = 0,
    this.isFirstRunCompleted = false,
  });

  DesignVersionSetting copyWith({
    DesignVersion? currentVersion,
    bool? hasSeenV2Introduction,
    DateTime? lastSwitchTimestamp,
    int? switchCount,
    bool? isFirstRunCompleted,
  }) {
    return DesignVersionSetting(
      currentVersion: currentVersion ?? this.currentVersion,
      hasSeenV2Introduction: hasSeenV2Introduction ?? this.hasSeenV2Introduction,
      lastSwitchTimestamp: lastSwitchTimestamp ?? this.lastSwitchTimestamp,
      switchCount: switchCount ?? this.switchCount,
      isFirstRunCompleted: isFirstRunCompleted ?? this.isFirstRunCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DesignVersionSetting &&
        other.currentVersion == currentVersion &&
        other.hasSeenV2Introduction == hasSeenV2Introduction &&
        other.lastSwitchTimestamp == lastSwitchTimestamp &&
        other.switchCount == switchCount &&
        other.isFirstRunCompleted == isFirstRunCompleted;
  }

  @override
  int get hashCode {
    return currentVersion.hashCode ^
        hasSeenV2Introduction.hashCode ^
        lastSwitchTimestamp.hashCode ^
        switchCount.hashCode ^
        isFirstRunCompleted.hashCode;
  }
}

class DesignVersionStats {
  final int totalSwitches;
  final DateTime? lastSwitchTimestamp;
  final Duration timeInV1;
  final Duration timeInV2;
  final DesignVersion preferredVersion;

  const DesignVersionStats({
    required this.totalSwitches,
    this.lastSwitchTimestamp,
    this.timeInV1 = Duration.zero,
    this.timeInV2 = Duration.zero,
    this.preferredVersion = DesignVersion.v1,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DesignVersionStats &&
        other.totalSwitches == totalSwitches &&
        other.lastSwitchTimestamp == lastSwitchTimestamp &&
        other.timeInV1 == timeInV1 &&
        other.timeInV2 == timeInV2 &&
        other.preferredVersion == preferredVersion;
  }

  @override
  int get hashCode {
    return totalSwitches.hashCode ^
        lastSwitchTimestamp.hashCode ^
        timeInV1.hashCode ^
        timeInV2.hashCode ^
        preferredVersion.hashCode;
  }
}

class DesignVersionChange {
  final DesignVersion oldVersion;
  final DesignVersion newVersion;
  final DateTime timestamp;
  final String trigger;

  const DesignVersionChange({
    required this.oldVersion,
    required this.newVersion,
    required this.timestamp,
    required this.trigger,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DesignVersionChange &&
        other.oldVersion == oldVersion &&
        other.newVersion == newVersion &&
        other.timestamp == timestamp &&
        other.trigger == trigger;
  }

  @override
  int get hashCode {
    return oldVersion.hashCode ^
        newVersion.hashCode ^
        timestamp.hashCode ^
        trigger.hashCode;
  }
}