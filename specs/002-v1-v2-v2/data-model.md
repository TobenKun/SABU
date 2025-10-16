# Data Model: Animation State and Design Version Management

**Generated**: October 16, 2025  
**Status**: Phase 1 Complete

## Entity Overview

This feature introduces two new data entities to support V2 interface with animated character functionality while maintaining full backwards compatibility with existing V1 data structures.

## Core Entities

### 1. AnimationState

**Purpose**: Tracks turtle character animation level and timing for progressive activity feedback

**Fields**:
```dart
class AnimationState {
  final TurtleAnimationLevel level;           // Current animation intensity (1-5)
  final DateTime lastActivityTimestamp;       // When user last performed savings action
  final DateTime lastUpdateTimestamp;         // When state was last recalculated
  final Duration activeDuration;              // How long current state has been active
  final int totalActivityCount;               // Total savings actions (for analytics)
}

enum TurtleAnimationLevel {
  idle(1),           // 16+ hours inactivity
  walkSlow(2),       // 8-16 hours inactivity  
  walkFast(3),       // 4-8 hours inactivity
  runSlow(4),        // 2-4 hours inactivity
  runFast(5);        // 0-2 hours inactivity (most active)
  
  const TurtleAnimationLevel(this.value);
  final int value;
}
```

**Validation Rules**:
- `level` must be valid TurtleAnimationLevel enum value
- `lastActivityTimestamp` cannot be in the future
- `lastUpdateTimestamp` must be >= `lastActivityTimestamp`
- `activeDuration` must be non-negative
- `totalActivityCount` must be non-negative integer

**State Transitions**:
```
User Action → runFast(5) → [2hr] → runSlow(4) → [2hr] → walkFast(3) → [4hr] → walkSlow(2) → [8hr] → idle(1)
      ↑                                                                                                    ↓
      └─────────────────────── User performs savings action ──────────────────────────────────────────────┘
```

**Storage**: SharedPreferences for fast access + SQLite for analytics logging

### 2. DesignVersionSetting

**Purpose**: Stores user preference for V1 (full) vs V2 (simplified) interface

**Fields**:
```dart
class DesignVersionSetting {
  final DesignVersion currentVersion;         // User's chosen interface version
  final DateTime lastChanged;                 // When user last switched versions
  final int switchCount;                      // How many times user has switched (analytics)
  final bool hasSeenV2Introduction;           // Whether user has seen V2 tutorial
}

enum DesignVersion {
  v1,    // Full interface with all widgets (default for existing users)
  v2;    // Simplified interface with only essentials + turtle
}
```

**Validation Rules**:
- `currentVersion` must be valid DesignVersion enum value
- `lastChanged` cannot be in the future
- `switchCount` must be non-negative integer
- `hasSeenV2Introduction` defaults to false for existing users, true for new users

**Storage**: SharedPreferences for user preference persistence

## Data Relationships

### Existing Entity Integration

**No changes required to existing entities**:
- `SavingsResult` - unchanged, used by both V1 and V2
- `SavingsSession` - unchanged, used by both V1 and V2  
- `UserProgress` - unchanged, used by both V1 and V2

**New relationship patterns**:
```
UserProgress ──────┐
                   ├─── V1 Interface (shows all widgets)
SavingsSession ────┤
                   ├─── V2 Interface (simplified view)
SavingsResult ─────┘
                   
AnimationState ────── V2 Interface only (turtle display)
                   
DesignVersionSetting ── Interface Router (V1/V2 selection)
```

## Storage Strategy

### SharedPreferences Keys
```dart
class StorageKeys {
  static const String designVersion = 'design_version_v2';
  static const String hasSeenV2Intro = 'has_seen_v2_introduction';
  static const String lastVersionSwitch = 'last_version_switch_timestamp';
  static const String versionSwitchCount = 'version_switch_count';
  
  static const String turtleAnimationLevel = 'turtle_animation_level';
  static const String lastActivityTimestamp = 'last_activity_timestamp';
  static const String lastAnimationUpdate = 'last_animation_update';
  static const String totalActivityCount = 'total_activity_count';
}
```

### SQLite Analytics Tables
```sql
-- Optional analytics logging (extends existing database)
CREATE TABLE IF NOT EXISTS animation_state_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  level INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  trigger_type TEXT NOT NULL, -- 'user_action', 'timer_stepdown', 'app_start'
  activity_count INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS design_version_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  version TEXT NOT NULL, -- 'v1' or 'v2'
  timestamp INTEGER NOT NULL,
  previous_version TEXT,
  switch_reason TEXT -- 'user_choice', 'first_run', 'reset'
);
```

## Data Migration Strategy

### Existing User Migration
1. **Default to V1**: Existing users start with `DesignVersion.v1` to maintain familiar experience
2. **Initialize animation state**: Set `AnimationState` to idle level with current timestamp
3. **Preserve all existing data**: No changes to savings data, progress, or sessions

### New User Onboarding  
1. **Default to V2**: New users start with `DesignVersion.v2` for simplified experience
2. **Show V2 introduction**: Set `hasSeenV2Introduction = true` after tutorial
3. **Initialize active animation**: Start with `TurtleAnimationLevel.idle`

## Data Access Patterns

### High-Frequency Reads
- Animation state checks (every app launch, every 30 minutes)
- Design version routing (every screen navigation)
- **Solution**: SharedPreferences with memory caching

### Low-Frequency Writes
- Animation state updates (on user savings actions, timer events)
- Design version changes (user settings modifications)
- **Solution**: SharedPreferences with optional SQLite logging

### Analytics Queries
- Animation state progression over time
- V1/V2 usage patterns
- **Solution**: SQLite queries with indexed timestamps

## Performance Considerations

### Memory Usage
- AnimationState: ~200 bytes per instance
- DesignVersionSetting: ~100 bytes per instance
- Total additional memory: <1KB

### Storage Impact
- SharedPreferences: ~500 bytes additional data
- SQLite logging: ~50 bytes per animation state change
- Asset storage: 3 PNG files moved from tmp_img/ to assets/

### Access Patterns
- SharedPreferences read: <1ms typical
- Animation state update: <5ms including persistence
- Design version switch: <10ms including UI rebuild

## Validation and Constraints

### Business Rules
1. Animation state must step down automatically every 2 hours of inactivity
2. Animation state must immediately jump to runFast(5) on any user savings action
3. Design version changes must preserve all user data
4. V2 interface must show identical savings amounts and progress as V1

### Technical Constraints
1. Animation state updates must not block UI thread
2. SharedPreferences access must be async where possible
3. SQLite logging must be optional and non-blocking
4. Asset loading must be optimized for 60fps animation performance

### Error Handling
1. Invalid animation states default to idle level
2. Corrupted design version settings default to V1 for existing users
3. Missing timestamps default to current time
4. Failed SQLite logging does not affect core functionality