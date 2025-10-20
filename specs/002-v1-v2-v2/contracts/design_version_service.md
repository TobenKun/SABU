# Design Version Service API Contract

**Version**: 1.0.0  
**Generated**: October 16, 2025  
**Service**: DesignVersionService

## Overview

Manages user preference between V1 (full interface) and V2 (simplified interface) designs. Provides persistence, analytics tracking, and migration support for existing users.

## API Methods

### Core Version Management

#### `Future<DesignVersion> getCurrentDesignVersion()`

**Purpose**: Get user's current interface preference

**Returns**:
```dart
enum DesignVersion {
  v1,    // Full interface with all widgets (default for existing users)
  v2;    // Simplified interface with essentials + turtle
}
```

**Default Behavior**:
- Existing users: `DesignVersion.v1` (backwards compatibility)
- New users: `DesignVersion.v2` (modern experience)

**Performance**: <1ms (SharedPreferences read)

---

#### `Future<void> setDesignVersion(DesignVersion version)`

**Purpose**: Update user's interface preference

**Parameters**:
- `version`: Target design version to switch to

**Behavior**:
- Persists new version to SharedPreferences
- Updates switch timestamp and count for analytics
- Triggers version change notification
- Does not affect any savings data

**Performance**: <10ms including UI notification  
**Side Effects**: Notifies listeners, rebuilds interface

---

#### `Future<bool> hasSeenV2Introduction()`

**Purpose**: Check if user has viewed V2 tutorial/introduction

**Returns**: Boolean indicating tutorial completion status

**Usage**: Determine whether to show V2 onboarding flow

---

#### `Future<void> markV2IntroductionSeen()`

**Purpose**: Record that user has completed V2 introduction

**Behavior**: Persists flag to prevent repeated tutorial display

## Migration and Onboarding

#### `Future<bool> isFirstTimeUser()`

**Purpose**: Detect if this is a new user (no existing savings data)

**Logic**: Checks for existing savings sessions or progress data

**Returns**: 
- `true`: New user → default to V2 with introduction
- `false`: Existing user → default to V1, offer V2 as option

---

#### `Future<void> performFirstRunSetup()`

**Purpose**: Initialize design version settings for new installation

**Behavior**:
- Sets appropriate default version based on user type
- Initializes analytics counters
- Sets up introduction flags

## Analytics and Monitoring

#### `Future<DesignVersionStats> getUsageStats()`

**Purpose**: Retrieve version switching analytics

**Returns**:
```dart
class DesignVersionStats {
  final int totalSwitches;
  final DateTime lastSwitchTimestamp;
  final Duration timeInV1;
  final Duration timeInV2;
  final DesignVersion preferredVersion; // most frequently used
}
```

**Usage**: Analytics dashboard, user behavior insights

---

#### `Stream<DesignVersionChange> get versionChangeStream`

**Purpose**: Real-time notifications of version switches

**Event Data**:
```dart
class DesignVersionChange {
  final DesignVersion oldVersion;
  final DesignVersion newVersion;
  final DateTime timestamp;
  final String trigger; // 'user_choice', 'first_run', 'reset'
}
```

## Interface Integration Contract

### Home Screen Routing
```dart
// Expected integration pattern
Widget buildHomeScreen() {
  return FutureBuilder<DesignVersion>(
    future: designVersionService.getCurrentDesignVersion(),
    builder: (context, snapshot) {
      final version = snapshot.data ?? DesignVersion.v1;
      
      switch (version) {
        case DesignVersion.v1:
          return HomeScreen(); // Existing full interface
        case DesignVersion.v2:
          return HomeScreenV2(); // New simplified interface
      }
    },
  );
}
```

### Settings Screen Integration
```dart
// Settings toggle widget
DesignVersionToggle(
  currentVersion: currentVersion,
  onVersionChanged: (newVersion) {
    designVersionService.setDesignVersion(newVersion);
  },
)
```

## State Persistence Contract

### SharedPreferences Keys
```dart
static const String designVersionKey = 'design_version_preference';
static const String hasSeenIntroKey = 'has_seen_v2_introduction';
static const String lastSwitchKey = 'last_version_switch_timestamp';
static const String switchCountKey = 'version_switch_count';
static const String firstRunKey = 'is_first_run_completed';
```

### Data Format
- `designVersion`: String ('v1' or 'v2')
- `hasSeenIntroduction`: bool
- `lastSwitchTimestamp`: int (millisecondsSinceEpoch)
- `switchCount`: int
- `firstRunCompleted`: bool

## Feature Compatibility Matrix

### Data Access Consistency
```
                 V1 Interface    V2 Interface
Savings Data        ✅              ✅         (identical access)
Progress Display    ✅              ✅         (same calculations)
Session History     ✅              ✅         (same data source)
Milestone Events    ✅              ❌         (V2 hides celebrations)
Quick Stats         ✅              ❌         (V2 simplified view)
Turtle Animation    ❌              ✅         (V2 exclusive)
```

### UI Element Mapping
```dart
// V1 → V2 element preservation
V1_ProgressDisplay → V2_SimpleProgressDisplay  (essential data only)
V1_SavingsButton  → V2_SavingsButton          (identical functionality)
V1_QuickStats     → [hidden in V2]            (not shown)
V1_Milestones     → [hidden in V2]            (not shown)
[new in V2]       → V2_TurtleAnimation        (V2 exclusive)
```

## Performance Guarantees

- **Version switching time**: <3 seconds for complete interface rebuild
- **Settings persistence**: <5ms for preference storage
- **First launch setup**: <100ms for new user initialization
- **Memory overhead**: <500 bytes additional storage per user

## Error Handling

### Fallback Behavior
1. Corrupted version setting → defaults to V1 (safe fallback)
2. Missing introduction flag → shows introduction (better UX)
3. Invalid switch count → resets to 0
4. Failed persistence → continues with in-memory state

### Migration Safety
1. **No data loss**: V1 ↔ V2 switching preserves all savings data
2. **Rollback capability**: Users can always return to V1
3. **Graceful degradation**: V2 features fail safely to V1 equivalents

## Testing Contract

### Required Test Coverage
```dart
// Unit tests
test('defaults to V1 for existing users');
test('defaults to V2 for new users');
test('persists version changes correctly');
test('handles corrupted preferences gracefully');

// Widget tests  
testWidgets('V1 interface shows all elements');
testWidgets('V2 interface shows only essential elements');
testWidgets('version toggle updates interface immediately');

// Integration tests
testWidgets('switching preserves savings data');
testWidgets('V2 introduction flow works correctly');
```

### Mock Configuration
```dart
// For testing: inject mock behavior
void setMockFirstTimeUser(bool isFirstTime);
void setMockCurrentVersion(DesignVersion version);
void clearAllPreferences(); // Reset to clean state
```