# Gameplay Systems Architecture

## Overview

The runtime should separate player input, AI decisions, combat simulation, animation presentation, visual/audio feedback, UI, match flow, and persistence. This separation permits the same fighter to work in versus, practice, tournament, and later story encounters.

## Main systems

### Input adapter
Converts touch/control events into high-level actions (move left, light attack, guard, ability). It does not directly set damage or bypass combat validation. It supports input buffering and safely handles menu/fight state changes.

### Fighter controller
Owns movement intent, facing, boundaries, pushbox response, and animation-facing parameters. It does not invent attack damage. Position updates must have a documented owner to prevent conflict between gameplay movement and animation root motion.

### Combat state machine
Tracks legal states and transitions, action startup/active/recovery, hitstun/blockstun, knockdown, and cancellation rules. One source of truth governs whether a move can start or interrupt another move.

### Move resolver
Reads move data, opens hit volumes during active frames, validates target and attack rules, applies damage/reaction/pushback, and emits combat events. Ensure attacks cannot unintentionally hit repeatedly every tick.

### Health and resource component
Tracks health, meter, cooldowns, status effects if any, and defeat conditions. Resource modification occurs only through allowed gameplay events. UI reads state; it must not be the authority for it.

### Animation driver
Maps combat state and move IDs to animation clips and blends. It sends phase information where needed but should not create a second conflicting combat state machine. Missing animation references should be caught during validation.

### AI controller
Selects legal action intents based on opponent distance/state, fighter archetype, difficulty, cooldowns, and recent behavior. AI requests pass through the same input/action validation as human input.

### Match director
Owns round setup, spawn/reset, timers, pause handling, win conditions, round transitions, results, and rematch. It coordinates fighter systems without duplicating their internal logic.

### Presentation event bus
Communicates events such as AttackStarted, HitConfirmed, Blocked, FighterDefeated, RoundEnded, and AbilityUsed to VFX, audio, camera, HUD, and analytics/debug tools. Presentation listeners must not silently alter combat results.

### Progression and persistence
Receives validated match results, applies eligible rewards once, updates ownership/mastery, and safely persists data. Practice rules may suppress rewards. A unique match/result identifier can prevent duplicate local reward application.

## Suggested data flow

Touch/AI intent → action validator → combat state machine → move resolver and movement → authoritative fighter state → combat events → animation/VFX/audio/HUD → match director → result reward processing → persistence.

## Update order

Document the chosen engine's fixed/update/animation order. Prefer a stable combat tick independent of rendering frame rate. Test variable frame rates, slow frames, pause/resume, and device thermal throttling. Avoid timing logic spread across unrelated components.

## Data-driven content

Moves, stats, abilities, unlock conditions, AI tags, and allowed equipment should be structured records. Code implements reusable behavior; data configures each character. Unique powers can use small, well-defined behavior modules rather than a massive set of hard-coded character conditionals.

## Defensive programming

Validate references at startup/editor/build time. Handle missing content, scene unload, app suspension, simultaneous hit events, invalid save data, and unexpected state changes. Keep debug visualization for hitboxes, combat state, frame timers, AI intent, and resource values.

## Testing seams

Combat rules should be testable without rendering where practical. Add test scenarios for valid/invalid move initiation, cooldowns, hit resolution, match resets, reward idempotency, and save/load. In-engine playtests remain necessary for feel and animation alignment.
