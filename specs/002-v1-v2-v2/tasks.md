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

- [X] T001 Verify turtle assets configured and present on disk
  - Check `pubspec.yaml` has:
    - `assets/images/characters/turtle/idle/`
    - `assets/images/characters/turtle/walking/`
    - `assets/images/characters/turtle/running/`
  - Verify frames exist: `/Users/sanghyunshin/fock/sabu/assets/images/characters/turtle/*/frame_*.png`
- [X] T002 [P] Install deps and validate build
  - Run: `flutter pub get`, `flutter analyze`, `flutter test -q` (sanity)

---

## Phase 2: Foundational (Blocking Prerequisites)

Purpose: Core dependency needed by later stories

⚠️ CRITICAL: Complete before starting stories that require persistence (US2, US4)

- [X] T003 Add SharedPreferences dependency (required by US2/US4)
  - Edit `/Users/sanghyunshin/fock/sabu/pubspec.yaml` → `dependencies:` add `shared_preferences: ^2.3.2`
  - Run: `flutter pub get`

Checkpoint: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Switch to Simplified V2 Interface (Priority: P1) 🎯 MVP

Goal: Provide a minimal V2 screen showing only essential elements and a stationary turtle above the savings button.

Independent Test: Navigate to the V2 screen and verify only these appear: current savings amount (no progress bar/percentage), usage statistics (today/total/streak), savings button, turtle character (stationary). No AppBar, no button text label, no milestone overlays.

### Tests for User Story 1 (write first)

- [X] T004 [P] [US1] Widget test to assert V2 minimal UI only
  - Create `/Users/sanghyunshin/fock/sabu/test/widget_test/home_screen_v2_test.dart`
  - Pump `HomeScreenV2` and assert:
    - Finds savings amount display (simplified, no progress bar/percentage)
    - Finds usage statistics card (today/total/streak counts)
    - Finds `SavingsButton`
    - Finds a turtle Image above the button
    - Does NOT find AppBar, button text label, V1-only widgets (milestone overlay, progress message)

### Implementation for User Story 1

- [X] T005 [US1] Create simplified V2 screen with stationary turtle
  - Add `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart` with a body containing:
    - Simplified savings amount display (no AppBar, no progress bar, no percentage)
    - Usage statistics card showing today/total/streak counts (from V1)
    - `Image.asset('/Users/sanghyunshin/fock/sabu/assets/images/characters/turtle/idle/frame_0.png')` above button (temporary stationary turtle)
    - `SavingsButton` with stubbed handler (no text label below button)
  - Ensure V1-only elements are absent (milestone overlays, progress bars, AppBar)
- [X] T006 [P] [US1] Register a route for V2 without changing default home
  - Edit `/Users/sanghyunshin/fock/sabu/lib/main.dart` MaterialApp:
    - Add `routes: { '/v2': (context) => const HomeScreenV2(), }`
    - Keep `home: const HomeScreen()` unchanged (V1 remains default)

Checkpoint: US1 independently testable — V2 minimal screen exists and is navigable via `/v2`
- V2 Features: Simplified savings amount (no progress bar/percentage), usage statistics, animated turtle, savings button
- V2 Removals: AppBar, button text label, milestone overlays, progress messages

---

## Phase 4: User Story 2 — Animal Character Animation Response (Priority: P2)

Goal: Animate the turtle with 5 progressive levels responding immediately to savings actions and stepping down every 2 hours of inactivity.

Independent Test: Perform savings actions and observe animation speed progression; verify step-down after simulated inactivity.

### Tests for User Story 2 (write first)

- [X] T007 [P] [US2] Unit tests for animation state transitions and timing
  - Create `/Users/sanghyunshin/fock/sabu/test/unit_test/animation_service_test.dart`
  - Cover: `onUserSavingsAction()` → runFast(5); 2hr step-downs; corrupted prefs → idle fallback; persistence keys
- [X] T008 [P] [US2] Widget tests for animated turtle frame playback
  - Create `/Users/sanghyunshin/fock/sabu/test/widget_test/animated_character_test.dart`
  - Verify frames cycle and animation duration changes per level (idle → walkSlow → walkFast → runSlow → runFast)

### Implementation for User Story 2

- [X] T009 [P] [US2] Create animation model
  - Add `/Users/sanghyunshin/fock/sabu/lib/models/animation_state.dart` with `TurtleAnimationLevel` enum and `AnimationState`
- [X] T010 [US2] Implement animation service per contract
  - Add `/Users/sanghyunshin/fock/sabu/lib/services/animation_service.dart` implementing `AnimationTimerService`
  - Methods: `getCurrentAnimationLevel`, `onUserSavingsAction`, `startPeriodicUpdates`, `dispose`
  - Persist using SharedPreferences keys (level, lastActivity, totalActivityCount)
  - Notify UI via ChangeNotifier or stream
- [X] T011 [P] [US2] Implement animated turtle sprite widget
  - Add `/Users/sanghyunshin/fock/sabu/lib/widgets/animated_character.dart` with `AnimatedTurtleSprite`
  - Preload frames from `/Users/sanghyunshin/fock/sabu/assets/images/characters/turtle/`
  - Drive frames via `AnimationController`; adjust duration per level; wrap in `RepaintBoundary`
- [X] T012 [US2] Integrate animation with V2 screen
  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart`:
    - Instantiate `AnimationTimerService`, start periodic updates on `initState`, dispose on `dispose`
    - Listen for level changes and rebuild
    - On savings button press, call `animationService.onUserSavingsAction()` before/after save flow
    - Maintain simplified layout: no AppBar, simplified amount display, usage stats, no button text

Checkpoint: US2 independently testable — animation responds to actions and steps down over time
- V2 maintains simplified interface: amount display, usage stats, animated turtle, clean layout without AppBar/button text

---

## Phase 5: User Story 3 — Responsive Layout for Different Screen Sizes (Priority: P3)

Goal: Ensure V2 layout fits entirely on 800x480 (no scrolling) and scales appropriately up to 1440x3120, adapting to orientation changes.

Independent Test: On small screens, all elements visible without scrolling; on larger screens, elements scale proportionally; orientation changes maintain good sizing.

### Tests for User Story 3 (write first)

- [ ] T013 [P] [US3] Widget tests for responsiveness
  - Create `/Users/sanghyunshin/fock/sabu/test/widget_test/responsive_v2_test.dart`
  - Pump `HomeScreenV2` at constrained sizes (800x480 and 1080x2340); assert no scroll on small screen and reasonable element sizes on large

### Implementation for User Story 3

- [ ] T014 [US3] Apply responsive layout rules to V2 screen
  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart`:
    - Use `MediaQuery`/`LayoutBuilder` to scale turtle size, paddings, and button size
    - Ensure simplified layout (amount display, usage stats, turtle, button) fits 800x480 without scroll
    - Maintain clean design without AppBar or button text label
- [ ] T015 [P] [US3] Handle orientation changes
  - Update spacing/element sizing for landscape vs portrait; keep 44px minimum touch targets

Checkpoint: US3 independently testable — V2 layout adapts without scrolling on small screens

---

## Phase 6: User Story 4 — Design Version Selection (Priority: P4)

Goal: Allow users to choose between V1 and V2; persist preference; route to selected design; provide settings toggle.

Independent Test: Switch between V1 and V2 and verify data consistency and interface differences.

### Tests for User Story 4 (write first)

- [ ] T016 [P] [US4] Unit tests for design version service
  - Create `/Users/sanghyunshin/fock/sabu/test/unit_test/design_version_service_test.dart`
  - Cover defaults (existing → V1, new → V2), persistence, corrupted values fallback
- [ ] T017 [P] [US4] Widget tests for toggle behavior
  - Create `/Users/sanghyunshin/fock/sabu/test/widget_test/design_version_toggle_test.dart`
  - Verify UI reflects selected version and callback triggers
- [ ] T018 [P] [US4] Integration test for version switching and data consistency
  - Create `/Users/sanghyunshin/fock/sabu/test/integration_test/design_version_switching_test.dart`
  - Verify router shows appropriate screen when preference changes; savings data remains consistent

### Implementation for User Story 4

- [ ] T019 [P] [US4] Create design version model
  - Add `/Users/sanghyunshin/fock/sabu/lib/models/design_version_setting.dart` with `DesignVersion` enum and `DesignVersionSetting`
- [ ] T020 [US4] Implement design version service per contract
  - Add `/Users/sanghyunshin/fock/sabu/lib/services/design_version_service.dart` (SharedPreferences storage; defaults: existing → V1, new → V2; intro helpers)
- [ ] T021 [P] [US4] Implement design version toggle widget
  - Add `/Users/sanghyunshin/fock/sabu/lib/widgets/design_version_toggle.dart` (two radio options; calls `onVersionChanged`)
- [ ] T022 [US4] Add router to choose V1/V2 at app start
  - Edit `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen.dart` to add `HomeScreenRouter` that returns `HomeScreen` or `HomeScreenV2` based on `DesignVersionService().getCurrentDesignVersion()`
  - Import `/Users/sanghyunshin/fock/sabu/lib/screens/home_screen_v2.dart` and `/Users/sanghyunshin/fock/sabu/lib/services/design_version_service.dart`
- [ ] T023 [US4] Switch app entry to router and add settings route
  - Edit `/Users/sanghyunshin/fock/sabu/lib/main.dart`:
    - Replace `home: const HomeScreen()` with `home: const HomeScreenRouter()`
    - Add `routes['/settings']` → settings screen
- [ ] T024 [P] [US4] Provide minimal settings screen to host the toggle
  - Add `/Users/sanghyunshin/fock/sabu/lib/screens/settings_screen.dart` with `DesignVersionToggle`
  - On change: call `DesignVersionService().setDesignVersion(newVersion)` and navigate to home

Checkpoint: US4 independently testable — users can switch V1/V2 with persisted preference and correct routing

---

## Final Phase: Polish & Cross-Cutting Concerns

Purpose: Performance, documentation, and non-functional improvements spanning multiple stories

- [ ] T025 [P] Preload sprite frames and confirm RepaintBoundary usage in `/Users/sanghyunshin/fock/sabu/lib/widgets/animated_character.dart`
- [ ] T026 Ensure all timers/controllers disposed; confirm <200ms response and 60fps in profile build
- [ ] T027 [P] Validate quickstart.md steps; update `/Users/sanghyunshin/fock/sabu/README.md` if needed

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

- US1 (P1): Minimal V2 interface with simplified amount display, usage statistics, stationary turtle, no AppBar/button text
- US2 (P2): Animated turtle reacting to savings, with timed step-down, maintaining clean V2 layout
- US3 (P3): Responsive layout ensuring usability on small and large screens for simplified V2 design
- US4 (P4): Design version selection with persistence and routing

---

## Checkpoints

- After US1: V2 minimal UI ready with simplified design (amount display, usage stats, turtle, button - no AppBar/button text); safe to ship as MVP
- After US2: Character adds engagement with immediate feedback
- After US3: Wide device support without scrolling on smallest screen
- After US4: Seamless V1/V2 choice with persistent preference
