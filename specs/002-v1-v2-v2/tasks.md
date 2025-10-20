# Tasks: Savings App V2 Design with Animated Characters

Input: Design documents from `/Users/sanghyunshin/fock/sabu/specs/002-v1-v2-v2/`
Prerequisites: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

Tests: Explicitly requested in plan/spec/contracts (TDD). Write tests before implementation within each story.

Organization: Tasks are grouped by user story to enable independent implementation and testing of each story.

Format: `[ID] [P?] [Story] Description`

- [P]: Can run in parallel (different files, no dependencies)
- [Story]: Which user story this task belongs to (e.g., US1, US2, US3)
- Include absolute file paths in descriptions

Path Conventions (Flutter mobile app)

- Source code: `/Users/sanghyunshin/fock/sabu/lib/`
- Tests: `/Users/sanghyunshin/fock/sabu/test/`
- Assets: `/Users/sanghyunshin/fock/sabu/assets/images/`

## Phase 1: Setup (Shared Infrastructure)

Purpose: Project initialization and baseline configuration for V2 work

- [x] T001 Verify turtle assets configured and present on disk
  - Check `pubspec.yaml` has:
    - `assets/images/characters/turtle/idle/`
    - `assets/images/characters/turtle/walking/`
    - `assets/images/characters/turtle/running/`
  - Verify frames exist: `/Users/sanghyunshin/fock/sabu/assets/images/characters/turtle/*/frame_*.png`
- [x] T002 [P] Install deps and validate build
  - Run: `flutter pub get`, `flutter analyze`, `flutter test -q` (sanity)

---

## Phase 2: Foundational (Blocking Prerequisites)

Purpose: Core dependency needed by later stories

⚠️ CRITICAL: Complete before starting stories that require persistence (US2, US4)

- [x] T003 Add SharedPreferences dependency (required by US2/US4)
  - Edit `/Users/sanghyunshin/fock/sabu/pubspec.yaml` → `dependencies:` add `shared_preferences: ^2.3.2`
  - Run: `flutter pub get`

Checkpoint: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Switch to Simplified V2 Interface (Priority: P1) 🎯 MVP

Goal: Provide a minimal V2 screen showing only essential elements and a stationary turtle above the savings button.

Independent Test: Navigate to the V2 screen and verify only these appear: current savings amount (no progress bar/percentage), usage statistics (today/total/streak), savings button with text label, turtle character (stationary). No AppBar, no milestone overlays.

### Tests for User Story 1 (write first)

- [x] T004 [P] [US1] Widget test to assert V2 minimal UI only
  - Create `/Users/sanghyunshin/fock/sabu/test/widget_test/home_screen_v2_test.dart`
  - Pump `HomeScreenV2` and assert:
    - Finds savings amount display (simplified, no progress bar/percentage)
    - Finds usage statistics card (today/total/streak counts)
    - Finds `SavingsButton`
    - Finds a turtle Image above the button
    - Finds button text label "터치해서 ₩1,000 저축하기"
    - Does NOT find AppBar, V1-only widgets (milestone overlay, progress message)

### Implementation for User Story 1

- [x] T005 [US1] Create simplified V2 screen with stationary turtle
  - Add `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart` with a body containing:
    - Simplified savings amount display (no AppBar, no progress bar, no percentage)
    - Usage statistics card showing today/total/streak counts (from V1)
    - `Image.asset('/Users/sanghyunshin/fock/sabu/assets/images/characters/turtle/idle/frame_0.png')` above button (temporary stationary turtle)
    - `SavingsButton` with stubbed handler and text label below button
  - Ensure V1-only elements are absent (milestone overlays, progress bars, AppBar)
- [x] T006 [P] [US1] Register a route for V2 without changing default home
  - Edit `/Users/sanghyunshin/fock/sabu/lib/main.dart` MaterialApp:
    - Add `routes: { '/v2': (context) => const HomeScreenV2(), }`
    - Keep `home: const HomeScreen()` unchanged (V1 remains default)

Checkpoint: US1 independently testable — V2 minimal screen exists and is navigable via `/v2`

- V2 Features: Simplified savings amount (no progress bar/percentage), usage statistics, animated turtle, savings button with text label
- V2 Removals: AppBar, milestone overlays, progress messages

---

## Phase 4: User Story 2 — Animal Character Animation Response (Priority: P2)

Goal: Animate the turtle with 5 progressive levels responding immediately to savings actions and stepping down every 2 hours of inactivity.

Independent Test: Perform savings actions and observe animation speed progression; verify step-down after simulated inactivity.

### Tests for User Story 2 (write first)

- [x] T007 [P] [US2] Unit tests for animation state transitions and timing
  - Create `/Users/sanghyunshin/fock/sabu/test/unit_test/animation_service_test.dart`
  - Cover: `onUserSavingsAction()` → runFast(5); 2hr step-downs; corrupted prefs → idle fallback; persistence keys
- [x] T008 [P] [US2] Widget tests for animated turtle frame playback
  - Create `/Users/sanghyunshin/fock/sabu/test/widget_test/animated_character_test.dart`
  - Verify frames cycle and animation duration changes per level (idle → walkSlow → walkFast → runSlow → runFast)

### Implementation for User Story 2

- [x] T009 [P] [US2] Create animation model
  - Add `/Users/sanghyunshin/fock/sabu/lib/models/animation_state.dart` with `TurtleAnimationLevel` enum and `AnimationState`
- [x] T010 [US2] Implement animation service per contract
  - Add `/Users/sanghyunshin/fock/sabu/lib/services/animation_service.dart` implementing `AnimationTimerService`
  - Methods: `getCurrentAnimationLevel`, `onUserSavingsAction`, `startPeriodicUpdates`, `dispose`
  - Persist using SharedPreferences keys (level, lastActivity, totalActivityCount)
  - Notify UI via ChangeNotifier or stream
- [x] T011 [P] [US2] Implement animated turtle sprite widget
  - Add `/Users/sanghyunshin/fock/sabu/lib/widgets/animated_character.dart` with `AnimatedTurtleSprite`
  - Preload frames from `/Users/sanghyunshin/fock/sabu/assets/images/characters/turtle/`
  - Drive frames via `AnimationController`; adjust duration per level; wrap in `RepaintBoundary`
- [x] T012 [US2] Integrate animation with V2 screen
  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart`:
    - Instantiate `AnimationTimerService`, start periodic updates on `initState`, dispose on `dispose`
    - Listen for level changes and rebuild
    - On savings button press, call `animationService.onUserSavingsAction()` before/after save flow
    - Maintain simplified layout: no AppBar, simplified amount display, usage stats, button with text label

Checkpoint: US2 independently testable — animation responds to actions and steps down over time

- V2 maintains simplified interface: amount display, usage stats, animated turtle, button text, clean layout without AppBar

---

## Phase 5: User Story 3 — Support for Small Screens (800x480) (Priority: P3)

Goal: Ensure both V1 and V2 layouts fit entirely on 800x480 WVGA screens without scrolling, while maintaining iPhone 16 Pro (393x852) as the baseline with no layout changes. Create specific optimizations for the 800x480 case rather than universal responsive scaling. V2 implementation prioritized first, then V1.

Independent Test: On iPhone 16 Pro, layouts remain unchanged. On 800x480, all elements visible without scrolling with appropriately sized elements.

### Tests for User Story 3 (write first)

- [x] T013 [P] [US3] Widget tests for V2 small screen support (COMPLETED)

  - Created `/Users/sanghyunshin/fock/sabu/test/widget_test/small_screen_v2_test.dart`
  - Tests horizontal layout with proper element positioning and spacing
  - Current tests verify: iPhone 16 Pro unchanged, 800x480 fits without scroll, button text present, horizontal arrangement

- [x] T013a [P] [US3] Widget tests for V1 small screen support

  - Create `/Users/sanghyunshin/fock/sabu/test/widget_test/small_screen_v1_test.dart`
  - Pump `HomeScreen` at iPhone 16 Pro size (393x852) and verify layout unchanged from baseline
  - Pump `HomeScreen` at 800x480 and assert no scroll, all elements fit within bounds
  - Verify button text label IS present (V1 design)

- [x] T013b [US3] Update V2 small screen tests for horizontal layout (COMPLETED)
  - Edit `/Users/sanghyunshin/fock/sabu/test/widget_test/small_screen_v2_test.dart`:
    - Updated element order verification for horizontal layout
    - Test side-by-side positioning of progress display and stats card
    - Verify SafeArea applied to prevent status bar overlap
    - Verify UsageStatsCard maintains card design even in compact mode
    - Verify proper spacing and no overlap between horizontal elements

### Implementation for User Story 3

- [x] T014 [US3] Add specific 800x480 support to V2 screen (COMPLETED)
- [x] T014a [US3] Fix small screen layout with horizontal arrangement (COMPLETED)

  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart`:
    - Changed small screen layout to horizontal arrangement:
      - Top row: SimplifiedProgressDisplay (left) + UsageStatsCard (right)
      - Middle: AnimatedTurtleSprite (centered)
      - Bottom: SavingsButton + text (centered)
    - Maintain proper spacing and aspect ratios for 800x480

- [x] T014b [US3] Add SafeArea to prevent status bar overlap (COMPLETED)

  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart`:
    - Wrapped small screen layout in SafeArea to prevent status bar overlap
    - Ensured adequate top padding for device status bar

- [x] T014c [US3] Maintain UsageStatsCard design in compact mode (COMPLETED)

  - Edit `/Users/sanghyunshin/fock/sabu/lib/widgets/usage_stats_card.dart`:
    - Updated ultraCompact mode to preserve card visual design (border, background, shadow)
    - Reduced size but maintained card appearance instead of plain text
    - Ensured readability at smaller size

- [x] T015a [US3] Add specific 800x480 support to V1 screen without affecting iPhone 16 Pro baseline
  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen.dart`:
    - Keep current fixed sizes as baseline for iPhone 16 Pro (393x852) - no changes to existing layout
    - Add conditional logic to detect 800x480 screen size specifically using MediaQuery
    - For 800x480 only: implement horizontal layout similar to V2:
      - Reduce AppBar height and use SafeArea
      - Top row: Progress display (left) + Individual stat cards compacted horizontally (right)
      - Middle: Milestone celebration space (if active) or empty space
      - Bottom: SavingsButton + text (centered)
    - Maintain V1 design elements (AppBar, individual stat cards, milestone overlays, progress bars)
    - Portrait mode only (no landscape support needed)

Checkpoint: US3 independently testable — Both V1 and V2 layouts preserved on iPhone 16 Pro baseline, optimized for 800x480 small screens with horizontal arrangement of key elements, SafeArea protection, and maintained design consistency for each version

---

## Phase 6: User Story 4 — Design Version Selection (Priority: P4)

Goal: Allow users to choose between V1 and V2; persist preference; route to selected design; provide settings toggle.

Independent Test: Switch between V1 and V2 and verify data consistency and interface differences.

### Tests for User Story 4 (write first)

- [x] T016 [P] [US4] Unit tests for design version service
  - Create `/Users/sanghyunshin/fock/sabu/test/unit_test/design_version_service_test.dart`
  - Cover defaults (existing → V1, new → V2), persistence, corrupted values fallback
- [x] T017 [P] [US4] Widget tests for toggle behavior
  - Create `/Users/sanghyunshin/fock/sabu/test/widget_test/design_version_toggle_test.dart`
  - Verify UI reflects selected version and callback triggers
- [x] T018 [P] [US4] Integration test for version switching and data consistency
  - Create `/Users/sanghyunshin/fock/sabu/test/integration_test/design_version_switching_test.dart`
  - Verify router shows appropriate screen when preference changes; savings data remains consistent

### Implementation for User Story 4

- [x] T019 [P] [US4] Create design version model
  - Add `/Users/sanghyunshin/fock/sabu/lib/models/design_version_setting.dart` with `DesignVersion` enum and `DesignVersionSetting`
- [x] T020 [US4] Implement design version service per contract
  - Add `/Users/sanghyunshin/fock/sabu/lib/services/design_version_service.dart` (SharedPreferences storage; defaults: existing → V1, new → V2; intro helpers)
- [x] T021 [P] [US4] Implement design version toggle widget
  - Add `/Users/sanghyunshin/fock/sabu/lib/widgets/design_version_toggle.dart` (two radio options; calls `onVersionChanged`)
- [x] T022 [US4] Add router to choose V1/V2 at app start
  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen.dart` to add `HomeScreenRouter` that returns `HomeScreen` or `HomeScreenV2` based on `DesignVersionService().getCurrentDesignVersion()`
  - Import `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart` and `/Users/sanghyunshin/fock/sabu/lib/services/design_version_service.dart`
- [x] T023 [US4] Switch app entry to router and add settings route
  - Edit `/Users/sanghyunshin/fock/sabu/lib/main.dart`:
    - Replace `home: const HomeScreen()` with `home: const HomeScreenRouter()`
    - Add `routes['/settings']` → settings screen
- [x] T024 [P] [US4] Provide minimal settings screen to host the toggle (COMPLETED)

  - Added `/Users/sanghyunshin/fock/sabu/lib/screens/settings_screen.dart` with `DesignVersionToggle`
  - Implemented StatefulWidget with version loading, change handling, and user feedback
  - On change: calls `DesignVersionService().setDesignVersion(newVersion)` with success/error feedback

- [x] T024a [P] [US4] Add settings access to V2 home screen

  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart`:
    - Add Positioned widget in top-right corner with settings IconButton
    - Use small, subtle icon (Icons.settings, size: 20, color: Colors.grey[600])
    - Position: top: 40, right: 16 (below status bar, inside SafeArea)
    - OnPressed: `Navigator.pushNamed(context, '/settings')`
    - Maintain V2 simplified design principles
  - Test: User can easily access settings without disrupting V2 clean layout

- [x] T024b [P] [US4] Remove AppBar from V1 and add settings access

  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen.dart`:
    - Remove AppBar from Scaffold
    - Add same settings icon pattern as V2 (top-right corner positioning)
    - Adjust top padding/spacing since AppBar is removed
    - Update small screen layout to account for no AppBar
  - Test: V1 maintains functionality without AppBar, settings accessible

- [x] T024c [P] [US4] Improve settings navigation experience
  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/settings_screen.dart`:
    - After version change, show snackbar: "인터페이스가 변경되었습니다"
    - Optional: Add helper text explaining restart may be needed for full effect
  - Test: Settings changes provide clear user feedback
  - Test: Navigation between V1/V2 works seamlessly after settings change

Checkpoint: US4 완전히 구현됨 — 사용자가 V1/V2를 자유롭게 전환 가능, 설정 지속, 일관된 UI 패턴

---

## Final Phase: Polish & Cross-Cutting Concerns

Purpose: Performance, documentation, and non-functional improvements spanning multiple stories

- [x] T025 [P] Preload sprite frames and confirm RepaintBoundary usage in `/Users/sanghyunshin/fock/sabu/lib/widgets/animated_character.dart`
- [x] T026 Ensure all timers/controllers disposed; confirm <200ms response and 60fps in profile build
- [x] T027 [P] Validate quickstart.md steps; update `/Users/sanghyunshin/fock/sabu/README.md` if needed

---

## Dependencies & Execution Order

Phase Dependencies

- Setup (Phase 1): None → start immediately
- Foundational (Phase 2): Must complete before US2 and US4 (SharedPreferences)
- User Stories (Phase 3+):
  - US1 (P1) → no dependency on US2/US4; precedes US3 and US4 (provides V2 screen)
  - US2 (P2) → depends on Foundational and US1
  - US3 (P3) → depends on US1; can run parallel to US2
  - US4 (P4) → depends on Foundational and US1
- Polish: After targeted stories complete

User Story Dependency Graph

- US1 → (US2, US3) → US4

Within Each User Story

- Tests first (TDD) → Models → Services → Widgets/Screens → Integration

Parallel Opportunities

- US1: route registration (T006) can proceed while writing screen (T005)
- US2: model (T009) and widget (T011) in parallel; tests (T007, T008) in parallel
- US3: tests (T013) parallel with orientation handling (T015)
- US4: model (T019), toggle widget (T021), and tests (T016–T018) in parallel; router (T022) and main switch (T023) sequential

---

## Parallel Execution Examples

User Story 1

- Run in parallel: T004, T006
- Then: T005

User Story 2

- Run in parallel: T007, T008, T009, T011
- Then: T010 → T012

User Story 3

- Run in parallel: T013, T015
- Then: T014

User Story 4

- Run in parallel: T016, T017, T018, T019, T021
- Then: T020 → T022 → T023 → T024

---

## Implementation Strategy

MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 3: US1 (minimal V2 screen + route)
3. Stop and validate with widget test (T004)

Incremental Delivery

1. Setup + Foundational → baseline ready
2. Add US1 → test independently → demo (MVP!)
3. Add US2 (animation) → test independently
4. Add US3 (responsive) → test independently
5. Add US4 (switching) → test independently → demo

---

## Story Mapping Summary

- US1 (P1): Minimal V2 interface with simplified amount display, usage statistics, stationary turtle, button text, no AppBar
- US2 (P2): Animated turtle reacting to savings, with timed step-down, maintaining clean V2 layout
- US3 (P3): Support for 800x480 small screens while preserving iPhone 16 Pro baseline layout
- US4 (P4): Design version selection with persistence and routing

---

## Checkpoints

- After US1: V2 minimal UI ready with simplified design (amount display, usage stats, turtle, button with text - no AppBar); safe to ship as MVP
- After US2: Character adds engagement with immediate feedback
- After US3: 800x480 device support without scrolling while preserving iPhone 16 Pro baseline
- After US4: Seamless V1/V2 choice with persistent preference
