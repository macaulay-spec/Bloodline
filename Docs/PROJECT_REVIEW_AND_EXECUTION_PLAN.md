# BLOODLINE — Project Review and Execution Plan

**Prepared:** 2026-10-17
**Baseline reviewed:** `BLOODLINE_Preproduction_Plan` v1.0 — 24 documents + README + manifest.
**Integrity check:** all 25 manifest entries match by SHA-256 and byte size. No mismatches.

This document is a *working overlay* on the baseline, not a replacement for it. Where it
disagrees with the baseline, the baseline documents govern until a decision is recorded in the
technical-decision log (document 23).

---

## 1. What BLOODLINE is — one page

**Product.** An original, stylized-realistic, **side-on 3D fighting game** for **Android first**.
Fighters are predefined, authored characters (not custom avatars). The world mixes ancient
traditions, modern cities, advanced organisations, and a constrained supernatural force called
**the Veil**. Combat is one-on-one, offline, against AI at launch, with touch controls.

**Experience loop.** Launch → mode → fighter/opponent/arena → fight → result → reward and
progression → unlock or improve → fight again. Fast rematch is a design requirement.

**Release ladder.** Offline versus vs AI → practice → optional challenge/tournament → *later*
online multiplayer → *later still* cinematic story campaign. No online or story dependency at
launch.

**Content target.** Vertical slice: 1 fighter, 1 opponent, 1 training arena. First real release:
**3–5 genuinely distinct fighters, 2–3 arenas**, quality over quantity.

**What "done" means.** Implemented, wired to real game state, tested in a packaged Android build,
documented, licensed, and evidenced. No fake buttons, no reward screens that grant nothing, no
debug systems dressed as features.

---

## 2. The rules the baseline establishes (and I will work by)

1. **Source-of-truth order:** Master Plan (scope) → Combat Spec (combat rules) → Roster Bible
   (identity) → Asset Pipeline (content) → Data Schema (representation) → Acceptance Plan (pass/fail).
2. **Gates, not opinions.** Phase 0 (engine feasibility) must pass before content multiplication.
   Phase 1 (vertical slice) must pass before roster growth. Each gate needs evidence: build ID,
   device, test checklist, defects.
3. **Content is a unit, not a file.** A fighter is only complete with model, materials, rig,
   animations, move data, VFX, audio, portrait, provenance record, and a device test — not because
   an `.fbx` exists.
4. **One pipeline, proven twice.** Build fighter #1 end-to-end, then #2 through the same process.
   If #2 needs rework of the architecture, fix the pipeline before scaling.
5. **Change control.** Every consequential decision gets an ID, date, options, evidence, status
   (Proposed / Accepted / Superseded / Rejected), and affected documents.

---

## 3. Baseline status at a glance

| Area | State in package | What that means |
| --- | --- | --- |
| Scope, pillars, phases, gates | **Decided** (Master Plan) | Can be treated as binding |
| World, tone, factions | Provisional draft (doc 02) | Names and lore are placeholders pending approval |
| Roster archetypes (6 candidates) | Provisional (doc 03) | No fighter is locked; identities need originality checks |
| Combat *rules and structure* | **Specified** (doc 04) | Move-data fields, states, hit-window rules, feedback requirements |
| Combat *numbers* (frame data) | **Not defined** | Must be authored and tuned in a prototype; docs deliberately defer |
| Engine | **Proposed only** — Unity (TD-006), Godot alternate | Not final until an Android spike passes |
| Art direction | **Decided** in principle (stylized-realism) | No concept sheets, palettes, or character designs exist |
| 3D assets, rigs, animations | **None** | Pipeline documents only; zero content |
| Data schema | Conceptual + one illustrative JSON | Real schema depends on engine choice |
| UI/UX | Screen list and flow specified (doc 15) | No wireframes, no layout system, no visual design |
| Persistence | Principles specified (doc 16) | No schema, no migration samples, no save tests |
| AI | Architecture specified (doc 14) | No decision system implemented, no difficulty tuning |
| Build/release | Process specified (doc 19) | No engine project, no CI, no APK, no signing setup |
| Performance targets | Method specified (doc 17) | **No numeric budgets** — deliberately, pending profiling |
| Licences | Register *fields* specified (doc 18) | Register is empty; no third-party assets cleared |
| Monetisation | Explicitly **not approved** (TD-007) | Design abstract currency only; no real-money systems |
| Code | **None** | Repository is documentation only |

**Honest summary:** this is a strong, disciplined *plan*, and it contains zero implementation.
That is exactly what the package says it is — and the next work is the expensive part.

---

## 4. Open decisions — what blocks what

The Master Plan lists 12 open decisions. They are not equally urgent. This is the dependency view:

### Blocking now (needed before meaningful build work)

| # | Decision | Options | Consequence if deferred |
| --- | --- | --- | --- |
| D1 | **Engine** | Unity (candidate) · Godot (alternate) · decide via spike | Blocks import formats, data schema, animation controller design, CI |
| D2 | **First fighter** | The Unbound (onboarding, balanced) · Nyra (agile, harder to teach) | Blocks art pipeline start and combat tuning target |
| D3 | **Combat ruleset depth** | Minimal (move/light/heavy/guard/dodge, rounds) · + throws/guard-break · + crouch/jump | Blocks frame data authoring and AI behaviour scope |
| D4 | **Target device profile** | One specific low/mid Android phone as the reference | Blocks performance budgets, quality tiers, and every "it runs" claim |
| D5 | **Starter rules** | Fixed starter + early unlock choice · curated random starter | Blocks onboarding flow and progression data |

**My recommendation:**
- **D1 — do not pick by preference.** Run the doc-11 spike, but treat Unity as the working
  assumption so tooling and schema can proceed; record the spike result as TD-006 closure.
- **D2 — The Unbound.** It is explicitly the onboarding fighter and the simplest to teach; use it
  as the pipeline proof. Nyra second.
- **D3 — minimal set first**: walk, light, heavy, guard, dodge, one signature ability, rounds.
  Throws/crouch/jump only after the core loop feels right. This matches doc 04 §Defense and
  doc 04 "Initial implementation order".
- **D5 — fixed starter + early unlock choice** (doc 05 already calls this the safer alternative).

### Deferrable (can be decided at the milestone that needs them)
Title/branding clearance · roster names and final designs · weapon exclusivity model · local-only vs
account progression · presence/absence of monetisation · violence/finisher rating target · asset
budget for third-party or AI-assisted content.

---

## 5. Gaps the baseline correctly leaves open (and that we must fill)

Not criticism — these are the natural next artifacts, and each maps to a milestone:

1. **Numeric combat data.** A concrete move list for fighter #1 with startup/active/recovery,
   damage, hit/hurt volume sizes, pushback, and cancel windows. Docs 04/13 define the *fields*;
   the values do not exist. → Needed for Milestone 2.
2. **Executable test harness.** Doc 20 defines acceptance criteria in prose. They must become
   runnable checks (move legality, one-hit-per-window, round reset, reward idempotency, save
   validation) so "passed" is not a judgement call. → Needed for Milestones 2–4.
3. **UI wireframes and a layout system.** Doc 15 names the screens and rules; there is no visual
   layout, type scale, safe-area handling, or touch-control arrangement. → Needed for Milestone 4.
4. **Concrete save schema + migration samples.** Doc 16 gives principles; we need a versioned
   file format and an old-save fixture to test migrations against. → Milestone 4.
5. **Populated asset register.** Doc 18 defines fields; no asset or licence is recorded.
   → Starts with the first concept/model.
6. **Performance budget table.** Set only *after* the first profiled character — but the table
   itself (geometry/bones/textures/materials/lights/VFX) should exist from day one so numbers
   get filled in, not invented later. → Milestone 1–2.
7. **Decision log entries.** Only TD-001…TD-007 exist. The engine result, combat ruleset scope,
   and starter rule all need entries when decided.

### Contradictions / points to resolve explicitly
- Doc 05 warns against random starters while the Master Plan leaves it as an open option — resolved
  by recommendation D5 above, but must be recorded, not left ambiguous.
- Doc 05 describes "in-game currency" while TD-007 says no monetisation is approved. These are
  compatible (soft, earned-only currency) but the docs should state that explicitly to prevent a
  real-money economy being assumed later.
- Doc 04 prefers deterministic fixed-step simulation "where supported"; this must be restated as a
  hard requirement or a soft preference once the engine is known, because AI timing and hit
  detection tests depend on it.

---

## 6. What can be built here vs. on your side

This workspace has Node.js 22, npm, and Python 3.11. It does **not** have Unity, Godot, Blender,
the Android SDK, or a physical Android device, and those cannot be installed from the network
access available here.

| Work | Where | Why |
| --- | --- | --- |
| Combat rules prototype (browser, Three.js) | **Here** | Proves input buffering, timing, hit windows, guard, rounds, AI — the highest-risk area (R1) |
| Move-data schema + validator + automated combat tests | **Here** | Engine-agnostic, portable, becomes the content contract for Unity/Godot |
| UI flow wireframes, screen specs, HUD layout | **Here** | Deterministic design work, no device needed |
| Save schema, migration fixtures, reward-idempotency tests | **Here** | Pure logic, testable |
| Concept art, character sheets, palette exploration | **Here** (as references) | Feeds the art bible; still needs human art direction sign-off |
| Unity/Godot project setup, Android build, device profiling | **Your side** | Requires the engine licence, SDK, and a real phone |
| Rigging, animation authoring, model production | **Your side** (Blender) | Requires the art tools and an artist |
| APK testing, thermal/perf measurement | **Your side** | Doc 17 is explicit that an emulator is not a substitute |

This split matters: nothing built here can *pass* Milestone 1, but it can make Milestone 1 short
and can de-risk the two risks most likely to kill the project — **R1 (combat feel)** and
**R2 (pipeline repeatability)**.

---

## 7. Recommended execution order

### Step A — Combat rules prototype *(start here, this workspace)*
A browser-based, data-driven duel between placeholder fighters that implements doc 04 literally:
fixed-step combat tick, input buffering, startup/active/recovery, hit/hurt volumes, one-hit-per-
window, guard/hitstun/blockstun, pushboxes and arena bounds, round state machine, results, and a
utility AI that only uses legal actions. All move values live in JSON that is validated at load.
Automated tests cover the doc-04 §Test cases list.

**Why first:** every other system (animation, AI, UI, rewards, balance) depends on combat timing
being real. It also produces the actual frame data the engine slice will reuse, and a schema that
survives the engine decision.

### Step B — Engine feasibility on your device *(parallel, your side)*
Doc 11 checklist: clean project → Android build → rigged humanoid → touch input → hit volume →
one AI action → repeated match → measured performance → reproducible second build. Record as TD.

### Step C — First fighter pipeline proof *(Milestone 3)*
Concept sheet → blockout → game-ready mesh → shared rig → baseline clip set → export → integration
→ device test → asset register entry. Measure every step's time; that number sets the real roster
size.

### Step D — Offline release systems *(Milestone 4)*
Fighter select, versus setup, practice, difficulty, arenas, results, rewards, settings, versioned
local save with migration tests, complete UI flow.

### Step E — Content and balance *(Milestone 5)*
Fighters 2–5 through the now-proven pipeline, arenas 2–3, VFX/audio pass, balance playtests,
acceptance evidence.

Online (Milestone 7) and story (Milestone 8) remain out of scope until the offline release passes —
as the roadmap already states.

---

## 8. Proposed immediate next step

Build **Step A** and nothing else yet. Concretely:

1. Author the **canonical move-data set** for The Unbound (light, heavy, guard, dodge, ability) and
   a placeholder opponent, with every field from doc 13.
2. Build the **fixed-step combat core + data validator + tests** — engine-agnostic TypeScript.
3. Wrap it in a **playable browser prototype** with touch/keyboard input and debug hitboxes, so
   timing can be felt and tuned rather than argued about.
4. Produce the **UI flow wireframes** and a first-pass save schema while the prototype is playable.
5. Record the resulting numbers, schema, and tuning notes in `Docs/` so the Unity/Godot slice
   starts from measured data instead of guesses.

What this deliberately does *not* do: commit to an engine, commission roster art, build menus for
modes that do not exist, or claim Android readiness.

---

## 9. Working agreement

- I read the governing documents before changing behaviour, and I update the affected documents and
  the decision log when a decision changes.
- I do not present placeholders as features; anything unfinished is labelled in the build and in
  writing.
- Every milestone claim comes with evidence (test result, build, device, or measurement).
- Content stays original or licence-cleared; the asset register is populated as assets appear, not
  afterwards.
- Scope additions go to a later phase unless they are required by the current gate.
