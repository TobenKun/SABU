<!--
Sync Impact Report - Constitution v1.0.0 (Initial Creation)
Generated: 2025-10-13

Version Change: none → 1.0.0 (MAJOR - Initial constitution establishment)

Added Principles:
- Code Quality Standards (Principle 1)
- Testing First (Principle 2)
- User Experience Consistency (Principle 3)
- Performance Requirements (Principle 4)
- Documentation Driven (Principle 5)

Added Sections:
- Quality Gates (Section 2)
- Development Workflow (Section 3)
- Governance

Templates Status:
✅ .specify/templates/plan-template.md - Constitution Check section aligns
✅ .specify/templates/spec-template.md - Requirements alignment confirmed
✅ .specify/templates/tasks-template.md - Task categorization supports all principles
✅ .opencode/command/*.md - No agent-specific references need updating

Follow-up TODOs: None - all placeholders resolved
-->

# Sabu Constitution

## Core Principles

### I. Code Quality Standards
All code MUST pass automated quality checks before merge. This includes linting, 
formatting, type checking, and complexity analysis. Code reviews MUST verify 
adherence to established patterns and maintainability standards. No exceptions 
permitted for "quick fixes" or urgent releases.

### II. Testing First (NON-NEGOTIABLE)
TDD mandatory: Tests written → User approved → Tests fail → Then implement. 
Red-Green-Refactor cycle strictly enforced. Minimum 80% code coverage required. 
All user stories MUST have corresponding integration tests that verify end-to-end 
functionality.

### III. User Experience Consistency
All user interfaces MUST follow established patterns and workflows. CLI commands 
MUST use consistent argument patterns and output formats. Documentation MUST 
maintain uniform structure and terminology. No feature ships without UX review 
against existing patterns.

### IV. Performance Requirements
All endpoints MUST respond within 200ms for 95th percentile. Database queries 
MUST be optimized and indexed appropriately. Memory usage MUST be profiled and 
bounded. Performance tests MUST be included for all user-facing features with 
measurable criteria.

### V. Documentation Driven
Specifications MUST be complete and approved before implementation begins. All 
APIs MUST have contract documentation. User-facing features MUST include 
quickstart guides. Code changes MUST update relevant documentation in the same PR.

## Quality Gates

All features MUST pass these gates before deployment:

- Constitution compliance verification
- Automated test suite passing (unit, integration, contract)
- Code quality metrics within thresholds
- Performance benchmarks meeting requirements
- Documentation completeness review
- UX consistency audit

## Development Workflow

### Feature Development Process
1. Specification creation and approval (`/speckit.specify`)
2. Implementation planning with constitution check (`/speckit.plan`)
3. Task breakdown with testing requirements (`/speckit.tasks`)
4. TDD implementation cycle
5. Quality gate validation
6. Review and merge

### Review Requirements
- All PRs MUST verify constitution compliance
- Performance impact MUST be assessed
- UX consistency MUST be validated
- Documentation MUST be updated
- Tests MUST demonstrate feature completeness

## Governance

This constitution supersedes all other development practices and guidelines. 
Amendments require documentation, stakeholder approval, and migration plan for 
existing code. All development decisions MUST reference constitutional principles 
when trade-offs arise.

Complexity and exceptions MUST be justified against constitutional principles. 
Use `.specify/templates/` guidance for runtime development workflows.

**Version**: 1.0.0 | **Ratified**: 2025-10-13 | **Last Amended**: 2025-10-13