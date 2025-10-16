# Animation Service API Contract

**Version**: 1.0.0  
**Generated**: October 16, 2025  
**Service**: AnimationTimerService

## Overview

Manages turtle character animation state transitions based on user activity patterns. Provides automatic step-down timing and immediate response to user savings actions.

## API Methods

### Core Animation Management

#### `TurtleAnimationLevel getCurrentAnimationLevel()`

**Purpose**: Get current turtle animation intensity level

**Returns**: 
```dart
enum TurtleAnimationLevel {
  idle(1),           // 16+ hours inactivity
  walkSlow(2),       // 8-16 hours inactivity  
  walkFast(3),       // 4-8 hours inactivity
  runSlow(4),        // 2-4 hours inactivity
  runFast(5);        // 0-2 hours inactivity
}
```

**Performance**: <1ms (SharedPreferences read)  
**Error Handling**: Returns `TurtleAnimationLevel.idle` if data corrupted

---

#### `Future<void> onUserSavingsAction()`

**Purpose**: Update animation state when user performs savings action

**Behavior**:
- Sets animation level to `runFast(5)` immediately
- Updates `lastActivityTimestamp` to current time
- Triggers animation state change notification
- Resets step-down timer

**Performance**: <5ms including persistence  
**Side Effects**: Notifies listeners, persists to SharedPreferences

---

#### `void startPeriodicUpdates()`

**Purpose**: Begin automatic animation step-down monitoring

**Behavior**:
- Starts Timer.periodic with 30-minute intervals
- Checks for animation level changes based on elapsed time
- Automatically steps down one level every 2 hours of inactivity

**Timer Logic**:
```
Current Time - Last Activity = Elapsed Hours
if Elapsed >= 16: level = idle(1)
if Elapsed >= 8: level = walkSlow(2)  
if Elapsed >= 4: level = walkFast(3)
if Elapsed >= 2: level = runSlow(4)
if Elapsed < 2: level = runFast(5)
```

**Error Handling**: Graceful fallback if timer creation fails

---

#### `void dispose()`

**Purpose**: Clean up timer resources and listeners

**Behavior**:
- Cancels periodic timer
- Removes all listeners
- Does not affect persisted animation state

**Usage**: Call in widget/service dispose methods

## Notification System

### `Stream<TurtleAnimationLevel> get animationLevelStream`

**Purpose**: Real-time animation level changes for UI updates

**Events Triggered**:
- User performs savings action → immediate `runFast(5)`
- Timer step-down occurs → appropriate lower level
- App restart with state restoration → current calculated level

**Usage Pattern**:
```dart
animationService.animationLevelStream.listen((level) {
  setState(() {
    _currentTurtleLevel = level;
  });
});
```

## State Persistence Contract

### SharedPreferences Keys
```dart
static const String lastActivityKey = 'last_activity_timestamp';
static const String animationLevelKey = 'turtle_animation_level';
static const String totalActivityCountKey = 'total_activity_count';
```

### Data Format
- `lastActivityTimestamp`: int (millisecondsSinceEpoch)
- `animationLevel`: String (enum name: 'idle', 'walkSlow', etc.)
- `totalActivityCount`: int (cumulative savings actions)

## Integration Points

### Required Dependencies
```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animation_state.dart';
```

### Service Registration
```dart
// Register as singleton in main.dart or dependency injection
final animationService = AnimationTimerService();
```

### Widget Integration
```dart
class AnimatedTurtleWidget extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // Start listening to animation changes
    animationService.startPeriodicUpdates();
    animationService.addListener(_onAnimationChange);
  }
  
  void _onAnimationChange() {
    setState(() {
      _turtleLevel = animationService.getCurrentAnimationLevel();
    });
  }
}
```

## Performance Guarantees

- **Animation response time**: <200ms from user action to level change
- **Memory footprint**: <1KB additional app memory + preloaded frame assets
- **Frame animation**: 60fps smooth playback with individual frame images
- **Asset loading**: Preloaded frames prevent animation stuttering
- **Timer efficiency**: 30-minute intervals (not continuous polling)
- **Persistence speed**: <5ms for state saves
- **UI responsiveness**: All operations async, non-blocking

## Error Recovery

### Corrupted State Handling
1. Invalid animation level → defaults to `idle`
2. Missing timestamp → uses current time
3. Timer creation failure → logs error, continues without periodic updates
4. SharedPreferences access failure → uses in-memory fallback

### Testing Hooks
```dart
// For testing: inject mock timer behavior
void setMockTimer(Timer mockTimer);
void setMockTimestamp(DateTime mockTime);
```

## Analytics Integration

### Optional SQLite Logging
```dart
Future<void> logAnimationChange(
  TurtleAnimationLevel oldLevel,
  TurtleAnimationLevel newLevel,
  String trigger, // 'user_action', 'timer_stepdown', 'app_start'
);
```

**Behavior**: Non-blocking logging for analytics, does not affect core functionality if database unavailable.