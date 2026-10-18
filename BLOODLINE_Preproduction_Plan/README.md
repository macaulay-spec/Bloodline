# BLOODLINE Pre-production Package

**Status:** Pre-production planning baseline v1.0  
**Working title:** BLOODLINE  
**Launch priority:** Android-first, offline AI fighting  
**Includes:** 24 coordinated planning documents plus this index.

## Confirmed direction

Original stylized-realistic 3D side-on fighting game; fictional world mixing ancient, modern, and supernatural themes; predefined fighter collection; AI versus first; online multiplayer later; cinematic story campaign later still.

## Navigation

### `01_Project_Design/`
- `00_PROJECT_MASTER_PLAN.md` — source of truth, scope and phases.
- `01_GAME_DESIGN_DOCUMENT.md` — player loop, modes and experience.
- `02_WORLD_AND_LORE_BIBLE.md` — world, factions and lore rules.
- `03_CHARACTER_ROSTER_BIBLE.md` — fighter archetypes and roster rules.
- `04_COMBAT_SYSTEM_SPECIFICATION.md` — move timing, hit detection, defense and combat rules.
- `05_GAME_MODES_AND_PROGRESSION.md` — versus, AI, collection, rewards and future modes.

### `02_Art_Assets/`
- `06_CHARACTER_ART_AND_DESIGN_GUIDE.md` — visual identity and concept-sheet requirements.
- `07_3D_CHARACTER_ASSET_PIPELINE.md` — full model-to-playable-fighter production pipeline.
- `08_ANIMATION_AND_RIGGING_SPEC.md` — shared skeleton and animation standards.
- `09_WEAPONS_AND_EQUIPMENT_PIPELINE.md` — models, attachment, movesets and equipment.
- `10_ENVIRONMENT_AND_ARENA_ASSET_PIPELINE.md` — arenas, collision and optimization.

### `03_Technical_Architecture/`
- `11_ENGINE_AND_PLATFORM_ARCHITECTURE.md` — engine selection and Android feasibility gate.
- `12_GAMEPLAY_SYSTEMS_ARCHITECTURE.md` — runtime systems and event/data flow.
- `13_CHARACTER_DATA_AND_CONTENT_SCHEMA.md` — fighter/move/item data and validation.
- `14_AI_AND_OPPONENT_ARCHITECTURE.md` — fair AI behavior and difficulty.
- `15_UI_UX_AND_GAME_FLOW_SPEC.md` — screens, navigation and HUD.
- `16_SAVE_DATA_AND_FUTURE_MULTIPLAYER.md` — offline persistence and online prerequisites.

### `04_Production_Delivery/`
- `17_ANDROID_PERFORMANCE_AND_OPTIMIZATION.md` — budgets and device testing.
- `18_ASSET_LICENSES_AND_SOURCE_REGISTER.md` — asset rights and attribution.
- `19_BUILD_AND_RELEASE_PIPELINE.md` — repository, APK and build validation.
- `20_TESTING_AND_ACCEPTANCE_CRITERIA.md` — measurable pass/fail criteria.
- `21_DEVELOPMENT_ROADMAP_AND_MILESTONES.md` — dependency-ordered milestones.
- `22_CONTENT_EXPANSION_AND_LIVE_UPDATES.md` — later fighters, events and campaign.
- `23_RISK_REGISTER_AND_TECHNICAL_DECISIONS.md` — risks and decisions.

## Recommended reading order

1. Master Plan
2. Game Design Document
3. Combat System Specification
4. Character Roster Bible
5. 3D Character Asset Pipeline
6. Engine and Platform Architecture
7. Gameplay Systems Architecture
8. Roadmap and Acceptance Criteria
9. Read the remaining documents as their dependencies are discussed.

## What this package is and is not

This is the written plan for pre-production. It does not contain a finished engine project, game code, licensed models, animation files, an APK, or implementation evidence. Names, story elements, engine selection, precise specs, roster size, economy, and monetisation remain provisional where the documents say so. The next step is to discuss and validate the asset-creation/acquisition pipeline before mass asset production.

## Change control

When a design decision changes, update the Master Plan and the affected document(s), record the decision in the technical-decision log, and revise this index if paths change. Keep one authoritative current package to avoid conflicting plans.
