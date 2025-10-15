# Tasks: One-Touch Savings App

**Input**: Design documents from `/specs/001-20/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Testing tasks included following TDD approach as specified in constitution

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Flutter project initialization and basic structure

- [X] T001 Create Flutter project structure with directories lib/, test/, android/, ios/
- [X] T002 Initialize pubspec.yaml with sqflite: ^2.3.0, flutter_animate: ^4.2.0+1, intl: ^0.18.1
- [X] T003 [P] Configure flutter analyze for linting and dart fix for formatting
- [X] T004 [P] Setup integration_test package and sqflite_common_ffi for testing

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core database and services infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Setup SQLite database schema with savings_sessions and user_progress tables in lib/services/database_service.dart
- [X] T006 [P] Create SavingsSession model with validation in lib/models/savings_session.dart
- [X] T007 [P] Create UserProgress model with validation in lib/models/user_progress.dart
- [X] T008 [P] Create SavingsResult model for operation results in lib/models/savings_result.dart
- [X] T009 Configure SQLite WAL mode and performance optimizations
- [X] T010 [P] Setup MaterialApp structure and basic theming in lib/main.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Basic Savings Action (Priority: P1) 🎯 MVP

**Goal**: Users can press a button to immediately save 1000원 with visual and haptic feedback

**Independent Test**: Open app, press button once, verify 1000원 is added with appropriate feedback

### Tests for User Story 1 ⚠️

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T011 [P] [US1] Unit test for saveMoney() database operation in test/unit_test/database_service_test.dart
- [X] T012 [P] [US1] Widget test for SavingsButton press animation in test/widget_test/savings_button_test.dart
- [X] T013 [P] [US1] Integration test for complete save flow in test/integration_test/app_test.dart

### Implementation for User Story 1

- [X] T014 [US1] Implement saveMoney() method with transaction handling in lib/services/database_service.dart
- [X] T015 [US1] Implement getCurrentProgress() method in lib/services/database_service.dart
- [X] T016 [P] [US1] Create SavingsButton widget with haptic feedback in lib/widgets/savings_button.dart
- [X] T017 [P] [US1] Create basic FeedbackService for haptic/visual feedback in lib/services/feedback_service.dart
- [X] T018 [US1] Create HomeScreen connecting button to save operation in lib/screens/home_screen.dart
- [X] T019 [US1] Add error handling and logging for save operations

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Savings Progress Tracking (Priority: P2)

**Goal**: Users can view accumulated savings total and today's save count with persistence across sessions

**Independent Test**: Make multiple saves across different sessions, verify totals persist and display correctly

### Tests for User Story 2 ⚠️

- [X] T020 [P] [US2] Unit test for progress calculations and persistence in test/unit_test/savings_service_test.dart
- [X] T021 [P] [US2] Widget test for ProgressDisplay number animation in test/widget_test/progress_display_test.dart
- [X] T022 [P] [US2] Integration test for data persistence across app restarts in test/integration_test/app_test.dart

### Implementation for User Story 2

- [X] T023 [P] [US2] Create ProgressDisplay widget with animated counters in lib/widgets/progress_display.dart
- [X] T024 [US2] Implement getSavingsHistory() method for progress tracking in lib/services/database_service.dart
- [X] T025 [US2] Add progress state management to HomeScreen in lib/screens/home_screen.dart
- [X] T026 [US2] Integrate progress display with save button functionality
- [X] T027 [US2] Add Korean number formatting with thousand separators

**Checkpoint**: User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Engagement Motivation Features (Priority: P3)

**Goal**: Users receive milestone celebrations at 10,000원 increments to encourage continued saving

**Independent Test**: Reach 10,000원, 20,000원, 30,000원milestones and verify enhanced celebration feedback occurs

### Tests for User Story 3 ⚠️

- [X] T028 [P] [US3] Unit test for milestone detection logic in test/unit_test/milestone_service_test.dart
- [X] T029 [P] [US3] Widget test for milestone celebration animations in test/widget_test/milestone_celebration_test.dart
- [X] T030 [P] [US3] Integration test for complete milestone flow in test/integration_test/app_test.dart

### Implementation for User Story 3

- [X] T031 [P] [US3] Create MilestoneCelebration widget with enhanced animations in lib/widgets/milestone_celebration.dart
- [X] T032 [US3] Implement milestone detection logic in saveMoney() operation
- [X] T033 [US3] Enhance FeedbackService with milestone-specific feedback in lib/services/feedback_service.dart
- [X] T034 [US3] Add milestone tracking to UserProgress model
- [X] T035 [US3] Integrate milestone celebrations with save button workflow

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Performance optimizations and final polish affecting multiple user stories

- [X] T036 [P] Implement rapid tap handling with debouncing across all save operations
- [X] T037 [P] Add performance monitoring for <50ms database operations requirement
- [X] T038 [P] Optimize animations for 60fps performance on target devices
- [X] T039 Run flutter analyze and fix all linting issues
- [X] T040 [P] Add memory usage monitoring with 100MB limit enforcement
- [X] T041 [P] Validate quickstart.md implementation guide accuracy
- [X] T042 Comprehensive testing with flutter test --coverage for 80% target

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Integrates with US1 button but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Enhances US1 saves but independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD approach)
- Models before services
- Services before widgets
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for saveMoney() database operation in test/unit_test/database_service_test.dart"
Task: "Widget test for SavingsButton press animation in test/widget_test/savings_button_test.dart"
Task: "Integration test for complete save flow in test/integration_test/app_test.dart"

# Launch all models for User Story 1 together:
Task: "Create SavingsButton widget with haptic feedback in lib/widgets/savings_button.dart"
Task: "Create basic FeedbackService for haptic/visual feedback in lib/services/feedback_service.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Performance Requirements

- Button response: <100ms total (haptic + visual + database)
- Database operations: <50ms per save
- Animation performance: 60fps maintained
- Memory usage: <100MB with monitoring
- App launch: <3s to ready state

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests follow TDD approach - write first, verify failure, then implement
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All paths follow Flutter project structure from plan.md