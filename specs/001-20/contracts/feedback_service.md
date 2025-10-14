# Feedback Service Contract

**Purpose**: Handle visual and haptic feedback for user interactions  
**Implementation**: Flutter services + animation controllers

## Core Operations

### FeedbackService

#### triggerSaveFeedback()
**Purpose**: Provide immediate feedback for save button tap (FR-002)
```dart
Future<void> triggerSaveFeedback({
  required FeedbackType type,
  int? milestoneAmount,
}) async
```

**Behavior**:
- Triggers haptic feedback immediately (0-5ms)
- Starts visual animations (scale, color)
- Plays sound if enabled
- Records feedback event for analytics

**Feedback Types**:
```dart
enum FeedbackType {
  basic,     // Normal 1000원 save
  milestone  // 10,000원 increment milestone
}
```

**Performance Requirements**:
- Haptic feedback MUST start within 5ms
- Visual feedback MUST start within 10ms
- MUST not block UI thread
- MUST handle rapid consecutive calls

#### triggerMilestoneCelebration()
**Purpose**: Enhanced feedback for milestone achievements (FR-010)
```dart
Future<void> triggerMilestoneCelebration(int milestoneAmount) async
```

**Behavior**:
- Longer duration haptic feedback (heavy impact)
- Enhanced visual effects (color changes, animations)
- Celebration animation sequence
- Optional sound effect

**Performance Requirements**:
- MUST complete within 1000ms total
- MUST maintain 60fps during animations
- MUST not interfere with subsequent save actions

### Animation Contracts

#### ButtonAnimationController
**Purpose**: Handle save button press animations
```dart
class ButtonAnimationController {
  Future<void> animatePress() async;
  Future<void> animateRelease() async;
  void reset();
}
```

**Animation Specifications**:
- Press: Scale down to 0.95 over 75ms
- Release: Scale back to 1.0 over 75ms  
- Color transition: Blue → Green during press
- Easing: Curves.easeOut for natural feel

#### CounterAnimationController  
**Purpose**: Animate number changes in savings display
```dart
class CounterAnimationController {
  Future<void> animateCounterChange({
    required int fromValue,
    required int toValue,
    Duration duration = const Duration(milliseconds: 800),
  }) async;
}
```

**Animation Specifications**:
- Duration: 800ms for smooth counting effect
- Easing: Curves.easeInOut for smooth acceleration
- Number formatting: Korean won with thousand separators
- Performance: Use tabular figures font for consistent spacing

### Haptic Feedback Contracts

#### Basic Save Feedback
```dart
// Light haptic for regular saves
await HapticFeedback.lightImpact();
```

#### Milestone Feedback  
```dart
// Heavy haptic for milestones
await HapticFeedback.heavyImpact();
```

**Platform Support**:
- iOS: Full haptic feedback support
- Android: Vibration fallback
- Graceful degradation for unsupported devices

### Visual Feedback Specifications

#### Button Visual States
```dart
enum ButtonState {
  idle,      // Default appearance
  pressed,   // During tap (scaled, color changed)  
  disabled,  // When processing (rare)
}
```

**Visual Properties**:
- Idle: Blue color, normal scale
- Pressed: Green color, 0.95 scale
- Transition: 150ms total duration
- Shadow: Subtle elevation changes

#### Progress Display Updates
```dart
class ProgressDisplayUpdate {
  final int oldValue;
  final int newValue;
  final bool isMilestone;
  final Duration animationDuration;
}
```

**Update Animations**:
- Number counting: Smooth interpolation over 800ms
- Milestone highlight: Brief color pulse (500ms)
- Daily counter: Instant update with scale bounce

### Performance Requirements

#### Response Times
- Haptic feedback trigger: <5ms
- Animation start: <10ms  
- Visual state change: <16ms (single frame)
- Complete animation cycle: <1000ms

#### Memory Usage
- Animation controllers: Reuse existing instances
- Texture cache: Limit to 50MB
- Dispose unused controllers properly

#### Frame Rate Targets
- Maintain 60fps during all animations
- No frame drops during rapid button tapping
- Smooth performance on budget devices (Android 7+)

## Error Handling

### Platform Errors
```dart
enum FeedbackError {
  hapticUnsupported,
  animationFailed,
  soundPlaybackFailed,
  platformChannelError
}

class FeedbackException implements Exception {
  final FeedbackError type;
  final String message;
  
  FeedbackException(this.type, this.message);
}
```

### Graceful Degradation
- Missing haptic support: Continue without haptic
- Animation failures: Show instant state changes
- Sound failures: Continue with visual feedback only
- Never block save operations due to feedback issues

## Testing Contracts

### Widget Tests
```dart
// Animation testing
testWidgets('button animates on press');
testWidgets('counter animates number changes');
testWidgets('milestone celebration triggers correctly');

// Performance testing  
testWidgets('animations maintain 60fps');
testWidgets('rapid taps do not cause animation conflicts');
```

### Platform Integration Tests
```dart
// Haptic feedback testing
test('haptic feedback triggers on supported platforms');
test('graceful degradation on unsupported platforms');

// Animation performance
test('animations complete within time requirements');
test('memory usage stays within limits during animations');
```

### Mock Contracts
```dart
// For testing without actual device feedback
class MockHapticService implements HapticService {
  bool lastFeedbackWasTriggered = false;
  FeedbackType? lastFeedbackType;
  
  @override
  Future<void> triggerFeedback(FeedbackType type) async {
    lastFeedbackWasTriggered = true;
    lastFeedbackType = type;
  }
}
```

## Integration Points

### Database Service Integration
- Record feedback events for analytics
- Coordinate with save operations
- Handle milestone detection results

### UI State Management
- Update button visual states
- Coordinate with progress displays
- Handle concurrent animation requests

### Platform Services
- Haptic feedback through Flutter services
- Sound playback through audio players
- Animation through Flutter animation framework