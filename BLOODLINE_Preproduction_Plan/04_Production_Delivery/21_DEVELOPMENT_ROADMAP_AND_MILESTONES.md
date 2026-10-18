# Development Roadmap and Milestones

## Planning principle

Order work by dependency and risk. Build one complete vertical slice before scaling content. Dates and durations are intentionally not promised until engine choice, available tools, asset sources, and developer capacity are known.

## Milestone 0 — Design baseline
**Deliverables:** approved master plan, combat rules, roster target, engine decision criteria, asset-rights policy, performance target plan.  
**Exit:** no critical contradiction between design and technical documents; all unresolved decisions have owners and a next test.

## Milestone 1 — Engine/Android feasibility
**Deliverables:** clean project, Android build, one rigged model, one animation, touch input, simple collision, basic opponent, profiling report, reproducible build notes.  
**Exit:** passes the checklist in document 11 on an actual target device. If not, resolve or compare engine alternatives before expanding.

## Milestone 2 — Combat vertical slice
**Deliverables:** one complete fighter, one opponent, one basic arena, movement, attacks, defense, hit detection, health, match states, basic AI, results/rematch, HUD.  
**Exit:** repeated playable matches pass combat and integration tests on device; major feel/performance issues are understood.

## Milestone 3 — Content pipeline proof
**Deliverables:** second fighter produced through the documented process, shared rig/animation test, asset register, import-validation process, measured production time.  
**Exit:** pipeline is repeatable and second character introduces no fundamental architecture failure.

## Milestone 4 — Offline game systems
**Deliverables:** fighter selection, AI difficulty, practice, versus configuration, arenas, results, basic rewards, local save/load, settings.  
**Exit:** complete loop from launch to fight to rewards to relaunch works without dead ends or duplicated rewards.

## Milestone 5 — Initial content and balance
**Deliverables:** initial roster target of three to five distinct fighters (subject to production capacity), two to three arenas if quality allows, animation/VFX/audio pass, balance testing, collection and unlock paths.  
**Exit:** all content passes character, asset, combat, performance, and licence gates.

## Milestone 6 — Release candidate
**Deliverables:** content-complete build, QA report, performance report, licences/credits, build archive, release notes, known-issues list.  
**Exit:** no open blocker/critical issues; packaged Android experience passes acceptance criteria.

## Milestone 7 — Online design and implementation
**Deliverables:** networking prototype, authority model, synchronisation/latency test, account/security plan, matchmaking, disconnect handling, service-cost estimate.  
**Exit:** only after the offline release is stable and the online technical risk is demonstrated. Use a separate implementation plan.

## Milestone 8 — Story campaign expansion
**Deliverables:** campaign design, first mission, dialogue/cinematic pipeline, boss encounter, checkpoint persistence, content budget, story QA.  
**Exit:** first complete chapter can be played through without breaking core combat or saves. Scale only after this pilot succeeds.

## Dependencies

Combat timing depends on engine and animation tests. Character production depends on shared rig, export, and materials. Unlocks depend on progression/save rules. Story depends on stable combat and reusable AI/arena systems. Multiplayer depends on an explicit synchronisation and authority plan. Therefore, do not produce the full roster, cinematic scenes, or online UI before their foundations pass.

## Work tracking

Each task should have an owner, dependency, acceptance criteria, estimated effort only when justified, state, and evidence of completion. Suggested states: Backlog, Ready, In Progress, Blocked, Review, Passed. A feature moves to Passed only after acceptance tests.

## Scope control

Any proposed feature must state its player value, implementation cost, asset needs, performance impact, test burden, and whether it blocks launch. If it does not support the current milestone, place it in a later phase rather than quietly increasing launch scope.
