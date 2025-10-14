# Research Findings: One-Touch Savings App

**Generated**: 2025-10-14  
**Purpose**: Resolve NEEDS CLARIFICATION items from Technical Context

## Animation Libraries for Flutter

### Decision: flutter_animate + Built-in Flutter Animations
**Rationale**: 
- Built-in animations (AnimatedContainer, TweenAnimationBuilder) handle 90% of requirements efficiently
- flutter_animate adds polish for complex milestone celebrations without performance overhead
- Combines 60fps performance with minimal memory usage
- Native haptic feedback integration through Flutter/services

**Alternatives considered**:
- Lottie: Too heavy for basic interactions, reserved for major milestones only
- Rive: Overkill for simple button/counter animations
- Custom animations: More development time without significant benefit

**Implementation approach**:
```dart
// Button press: AnimatedScale with 150ms duration
// Number counting: TweenAnimationBuilder with easeOut curve
// Milestone celebrations: flutter_animate with chained effects
// Haptic feedback: HapticFeedback.lightImpact() built-in
```

## Widget Testing Strategy for Flutter

### Decision: Comprehensive 3-tier testing with flutter_test
**Rationale**:
- flutter_test (built-in) handles widget and unit testing efficiently
- integration_test package for E2E scenarios
- sqflite_common_ffi enables in-memory SQLite testing
- Supports 80% code coverage requirement from constitution

**Testing structure**:
```
test/
├── widget_test/           # UI component testing
├── unit_test/            # Service layer testing  
└── integration_test/     # E2E user scenarios
```

**Key techniques**:
- `WidgetTester.pump()` for animation frame control
- `WidgetTester.pumpAndSettle()` for completion verification
- In-memory SQLite databases for isolated testing
- Performance testing with Stopwatch for <100ms requirement

**Alternatives considered**:
- Mockito only: Insufficient for database integration testing
- Golden tests: Not needed for simple UI components
- Third-party testing frameworks: Built-in tools sufficient

## Animation Performance Targets

### Decision: 60fps with <16ms frame budget
**Rationale**:
- Meets constitutional performance requirements (200ms p95)
- Exceeds spec requirement of 100ms button response  
- Standard mobile app performance benchmark
- Achievable with Flutter's optimized rendering engine

**Memory usage limits**: 100MB threshold with active monitoring

**Implementation strategy**:
- Use `SingleTickerProviderStateMixin` for single-controller animations
- Implement debouncing (300ms) for rapid tap prevention
- Cache frequently displayed numbers (amounts)
- Enable SQLite WAL mode for concurrent access

**Alternatives considered**:
- 30fps target: Too low for premium user experience
- Unlimited memory: Risk of crashes on budget devices
- No debouncing: Risk of accidental over-saving

## Memory Usage Limits and Monitoring

### Decision: 100MB app memory limit with proactive monitoring
**Rationale**:
- Conservative limit ensures performance on budget Android devices
- Aligns with typical Flutter app memory usage patterns
- Allows headroom for system processes and other apps
- Enables graceful degradation before OS kills app

**Monitoring approach**:
- Timer-based checks every 30 seconds
- Platform-specific memory info via method channels
- Automatic cache clearing when approaching limits
- Performance DevTools integration for development

**Alternatives considered**:
- 200MB limit: Too high for budget devices
- No monitoring: Risk of memory-related crashes
- Continuous monitoring: Unnecessary performance overhead

## Max Savings Amount Handling

### Decision: 64-bit integer support up to 999,999,999,999원
**Rationale**:
- Dart int type supports up to 2^63-1 (9.2 quintillion)
- 999 trillion won practical upper limit for mobile display
- SQLite INTEGER type handles 64-bit values natively
- Korean number formatting scales appropriately

**Display formatting**:
- Use NumberFormat('#,###', 'ko_KR') for thousand separators
- Cache formatted strings for frequently displayed amounts
- FontFeature.tabularFigures() for consistent digit alignment
- Graceful truncation for extremely large numbers

**Alternatives considered**:
- 32-bit limit: Too restrictive (2.1 billion won = ~$1.6M)
- Decimal type: Unnecessary precision for whole won amounts
- String storage: Poor query performance and sorting

## Research Summary

All NEEDS CLARIFICATION items have been resolved with specific technical decisions:

✅ **Animation libraries**: flutter_animate + built-in animations  
✅ **Widget testing strategy**: 3-tier testing with flutter_test  
✅ **Animation performance targets**: 60fps with <16ms frames  
✅ **Memory usage limits**: 100MB with proactive monitoring  
✅ **Max savings amount handling**: 64-bit integers up to 999 trillion won

Implementation can proceed to Phase 1 (Design & Contracts) with these technical foundations established.