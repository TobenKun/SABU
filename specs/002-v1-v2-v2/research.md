# Research: Flutter Sprite Animation Implementation for V2

**Generated**: October 16, 2025  
**Status**: Phase 0 Complete

## Animation Framework Decision

**Decision**: Use built-in Flutter AnimationController with custom sprite widget  
**Rationale**: Better integration with existing codebase, lighter weight than game engines, sufficient performance for 5-state character animation  
**Alternatives considered**: Flame game engine (too heavyweight), Lottie animations (requires After Effects workflow), Rive (requires specialized tooling)

## Asset Management Strategy

**Decision**: Organize individual frame images in assets/images/characters/turtle/[state_name]/ with frame numbering  
**Rationale**: Clear organization, supports multiple animation states, easy to expand with more characters, individual frames allow better performance control  
**Alternatives considered**: Sprite sheets (harder to organize, requires cropping logic), GIF animations (poor quality control), video files (larger size)

## Animation State Persistence

**Decision**: SharedPreferences for animation state + timestamp, SQLite for analytics logging  
**Rationale**: SharedPreferences provides fast access for frequently read state data, SQLite maintains existing pattern for user data  
**Alternatives considered**: SQLite only (overkill for simple state), in-memory only (loses state on restart), file storage (unnecessary complexity)

## Performance Optimization Strategy

**Decision**: Image preloading + RepaintBoundary + controlled frame rates  
**Rationale**: Ensures 60fps performance on mobile devices, prevents janky animations, optimizes memory usage  
**Alternatives considered**: Real-time image loading (causes stuttering), video playback (higher resource usage), GIF rendering (poor control)

## Responsive Layout Approach

**Decision**: MediaQuery-based sizing with landscape/portrait layouts  
**Rationale**: Supports 800x480 to 1440x3120 screens effectively, maintains visual hierarchy, follows Flutter best practices  
**Alternatives considered**: Fixed sizing (poor mobile experience), CSS-like breakpoints (not native Flutter), AspectRatio only (insufficient control)

## Timer Implementation Pattern

**Decision**: Timer.periodic with 30-minute check intervals + immediate state updates on user activity  
**Rationale**: Balances accurate timing with battery efficiency, provides responsive user feedback  
**Alternatives considered**: Continuous timers (battery drain), manual refresh only (poor UX), background isolates (overcomplicated)

## V1/V2 Interface Management

**Decision**: Conditional rendering in existing home_screen.dart + new home_screen_v2.dart  
**Rationale**: Maintains code separation, allows independent testing, preserves existing V1 functionality intact  
**Alternatives considered**: Single screen with mode switching (complex state management), separate apps (poor user experience), feature flags only (testing difficulties)

## Sprite Asset Organization

**Current assets converted from sprite sheets:**
- turtle_idle.png → 6 individual frames
- turtle_walking.png → 6 individual frames
- turtle_running.png → 3 individual frames

**Current structure:**
```
assets/images/characters/turtle/
├── idle/frame_0.png, frame_1.png, frame_2.png, frame_3.png, frame_4.png, frame_5.png
├── walking/frame_0.png, frame_1.png, frame_2.png, frame_3.png, frame_4.png, frame_5.png
└── running/frame_0.png, frame_1.png, frame_2.png
```

**Recommended expansion to 5-state system:**
```
assets/images/characters/turtle/
├── idle/ (current: 6 frames)
├── walk_slow/ (use walking frames with slower timing)
├── walk_fast/ (use walking frames with faster timing)  
├── run_slow/ (use running frames with slower timing)
└── run_fast/ (use running frames with faster timing)
```

## Implementation Priority

1. **Phase 1**: Basic sprite widget with 3 existing assets (idle, walking, running)
2. **Phase 2**: Expand to 5-state animation system with proper frame sequences
3. **Phase 3**: Add responsive layouts and performance optimizations
4. **Phase 4**: Implement V1/V2 switching and settings integration

## Key Technical Constraints Resolved

- **<200ms animation response**: Achieved through preloaded assets and immediate state updates
- **60fps performance**: RepaintBoundary + AnimationController optimization 
- **2-hour step-down timing**: Timer.periodic with persistent timestamp tracking
- **Screen size support**: MediaQuery responsive calculations for 800x480→1440x3120
- **Backwards compatibility**: Separate V2 implementation preserves V1 functionality

## Integration Points with Existing Codebase

- **DatabaseService**: Add animation state logging methods
- **ProgressDisplay**: Coordinate with turtle animation states  
- **SavingsButton**: Trigger animation state updates on user actions
- **Settings Screen**: Add V1/V2 toggle control
- **SharedPreferences**: Store design version preference and animation state