# Implementation Plan: Savings App V2 Design with Animated Characters

**Branch**: `002-v1-v2-v2` | **Date**: October 16, 2025 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-v1-v2-v2/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Create a simplified V2 interface alongside existing V1 that displays only essential elements (current savings, cumulative records, savings button) with an animated turtle character that responds to user savings activity. The turtle progresses through 5 animation states (idle → slow walk → fast walk → slow run → fast run) based on savings frequency and gradually steps down during inactivity periods.

## Technical Context

**Language/Version**: Dart 3.x with Flutter 3.16+  
**Primary Dependencies**: flutter/material.dart, sqflite, shared_preferences, path, intl  
**Storage**: SQLite (existing database) + SharedPreferences for settings  
**Testing**: flutter test with widget_test, integration_test, unit_test  
**Target Platform**: Mobile (iOS/Android) with responsive design for 800x480 to 1440x3120  
**Project Type**: Mobile app - Flutter cross-platform  
**Performance Goals**: <200ms animation response, 60fps character animations, <40% load time vs V1  
**Constraints**: 5 animation states, 2-hour step-down intervals, backwards compatibility with V1  
**Scale/Scope**: Single-user app, 3 sprite files, 2 design versions, responsive layouts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Code Quality Standards**: ✅ PASS  
- Flutter code will follow existing linting rules (analysis_options.yaml)
- Animation logic will use established state management patterns
- Sprite handling will follow Flutter image asset conventions

**II. Testing First (NON-NEGOTIABLE)**: ✅ PASS  
- Widget tests for V2 interface components required
- Unit tests for animation state machine logic required  
- Integration tests for V1/V2 switching behavior required
- Animation timing tests with mock timers required

**III. User Experience Consistency**: ✅ PASS  
- V2 maintains identical savings functionality as V1
- Consistent navigation patterns preserved
- Settings toggle follows existing UI patterns

**IV. Performance Requirements**: ✅ PASS  
- Animation response <200ms meets constitutional <200ms requirement
- 60fps character animation exceeds mobile performance standards
- V2 load time improvement supports performance goals

**V. Documentation Driven**: ✅ PASS  
- Complete specification provided before implementation
- API contracts for animation services will be documented
- Quickstart guide for V2 implementation will be created

## Constitution Check - Post Design

*GATE: Re-evaluation after Phase 1 design completion*

**I. Code Quality Standards**: ✅ PASS  
- Design follows established Flutter patterns from research.md
- Service layer contracts maintain separation of concerns
- Widget implementations use proper lifecycle management
- All new code will follow existing analysis_options.yaml rules

**II. Testing First (NON-NEGOTIABLE)**: ✅ PASS  
- Test structure defined in quickstart.md covers all new components
- Unit tests specified for animation service logic
- Widget tests specified for V2 interface components  
- Integration tests specified for V1/V2 switching behavior
- TDD approach outlined in quickstart implementation phases

**III. User Experience Consistency**: ✅ PASS  
- V2 maintains identical savings functionality as V1 (verified in contracts)
- Design version toggle follows existing settings patterns
- Navigation patterns preserved with router implementation
- Korean localization maintained in turtle feedback messages

**IV. Performance Requirements**: ✅ PASS  
- Animation response <200ms guaranteed through preloaded assets
- 60fps performance assured through RepaintBoundary optimization
- Timer efficiency with 30-minute intervals (not continuous polling)
- Memory footprint <1KB additional as specified in contracts

**V. Documentation Driven**: ✅ PASS  
- Complete API contracts provided for both services
- Data model specifications define all new entities
- Implementation quickstart provides step-by-step guidance
- All documentation updated including agent context

**Final Gate Status**: ✅ APPROVED - All constitutional principles satisfied after design phase

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/
├── models/
│   ├── animation_state.dart          # NEW: Animation level and timing state
│   ├── design_version_setting.dart   # NEW: V1/V2 preference storage
│   └── [existing models unchanged]
├── screens/
│   ├── home_screen.dart             # MODIFIED: Add V1/V2 routing logic
│   └── home_screen_v2.dart          # NEW: Simplified V2 interface
├── services/
│   ├── animation_service.dart       # NEW: Animation state management
│   ├── design_version_service.dart  # NEW: V1/V2 preference handling
│   └── [existing services unchanged]
├── widgets/
│   ├── animated_character.dart      # NEW: Turtle sprite animation widget
│   ├── design_version_toggle.dart   # NEW: Settings screen toggle
│   └── [existing widgets unchanged]
└── assets/
    └── images/
        ├── turtle_idle.png          # MOVED from tmp_img/
        ├── turtle_walking.png       # MOVED from tmp_img/
        └── turtle_running.png       # MOVED from tmp_img/

test/
├── unit_test/
│   ├── animation_service_test.dart   # NEW: Animation logic tests
│   ├── design_version_service_test.dart # NEW: Settings persistence tests
│   └── animation_state_test.dart     # NEW: State model tests
├── widget_test/
│   ├── animated_character_test.dart  # NEW: Animation widget tests
│   ├── home_screen_v2_test.dart     # NEW: V2 interface tests
│   └── design_version_toggle_test.dart # NEW: Toggle widget tests
└── integration_test/
    └── design_version_switching_test.dart # NEW: V1/V2 switching tests
```

**Structure Decision**: Mobile app structure using existing Flutter layout. New files follow established naming conventions (snake_case). Sprite assets moved from tmp_img/ to proper assets/images/ directory with pubspec.yaml registration.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
