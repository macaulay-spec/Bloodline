# Risk Register and Technical Decisions

## Risk register

### R1 — Combat does not feel responsive
**Impact:** critical; players abandon the game even if visuals are good.  
**Mitigation:** prototype input, attack timing, hit reactions, and touch layout before roster expansion; use playtests and frame-time evidence.

### R2 — Character pipeline is not repeatable
**Impact:** roster delivery becomes too slow or inconsistent.  
**Mitigation:** complete one fighter end-to-end, then a second; standardise rig, names, export, animation mapping, and acceptance checks.

### R3 — Asset licences are unclear
**Impact:** rework, takedown, or inability to distribute.  
**Mitigation:** maintain a provenance register and reject assets with unresolved rights before integration.

### R4 — Android performance is poor
**Impact:** low-end devices stutter, overheat, or crash.  
**Mitigation:** choose measured budgets, limit effects/materials/textures, profile packaged builds, and maintain scalable settings.

### R5 — Scope becomes too large
**Impact:** core game remains unfinished.  
**Mitigation:** enforce milestone gates, postpone cinematic story and online systems, and limit initial roster/arena count.

### R6 — AI feels unfair or trivial
**Impact:** versus mode lacks longevity.  
**Mitigation:** build an explainable decision system, use common combat rules, test difficulty tiers, and avoid hidden cheating.

### R7 — Engine/build workflow is unsuitable
**Impact:** wasted content work or inability to make an APK.  
**Mitigation:** time-box feasibility work, verify Android packaging and CI early, and document a fallback route.

### R8 — Save/progression exploit or corruption
**Impact:** lost progress or duplicated rewards.  
**Mitigation:** versioned saves, safe writes, validation, idempotent reward handling, and interruption tests.

### R9 — Art direction becomes inconsistent
**Impact:** game looks like unrelated free asset packs.  
**Mitigation:** visual bible, common shader/material standards, curated palettes, in-engine review, and one art owner.

### R10 — Multiplayer costs and complexity underestimated
**Impact:** security, latency, and ongoing service problems.  
**Mitigation:** treat it as a separate project phase with cost model, authority design, monitoring, and online prototype.

## Decision log template

For every consequential decision, record: ID, date, status, problem, options considered, evidence/test, chosen option, trade-offs, consequences, owner, and documents affected. Decisions are Proposed, Accepted, Superseded, or Rejected. Do not silently change an accepted decision.

## Initial technical decisions

### TD-001: Android first
**Status:** Accepted.  
**Reason:** user-set launch priority.  
**Consequence:** touch layout, landscape camera testing, mobile performance, packaging, and physical device tests are early requirements.

### TD-002: Side-on 3D combat
**Status:** Accepted.  
**Reason:** user-set direction combining side-on fighting readability with 3D characters/environments.  
**Consequence:** stable fighting plane, camera framing, pushboxes, boundaries, and attack reach must be designed early.

### TD-003: Stylized-realistic art
**Status:** Accepted.  
**Reason:** user-set art direction.  
**Consequence:** common art bible and performance budgets required; neither photo-realism nor cartoon art should be the default.

### TD-004: Offline AI combat before campaign and online
**Status:** Accepted.  
**Reason:** lower initial content/networking burden; establish real gameplay first.  
**Consequence:** first release prioritises versus, AI, fighters, progression, and arenas.

### TD-005: Predefined fighter collection
**Status:** Accepted.  
**Reason:** user chose a roster of authored characters.  
**Consequence:** no full custom-avatar editor in initial scope; character identity and moveset quality are priorities.

### TD-006: Unity as feasibility candidate
**Status:** Proposed, not final.  
**Reason:** candidate tooling fits a 3D animation-heavy Android game.  
**Evidence required:** build/animation/input/performance spike on target device. Godot remains an alternative; do not start mass production until validated.

### TD-007: No monetisation commitment
**Status:** Accepted by omission until decided.  
**Reason:** the user has mentioned purchasing/collecting fighters as a concept, but price and payment model are not decided.  
**Consequence:** design unlocks and currency abstractly; do not add real-money transactions without explicit approval.

## Review cadence

Review risks at each milestone and whenever scope, engine, asset source, target device, or online plans change. Add newly observed risks instead of pretending the initial list is complete.
