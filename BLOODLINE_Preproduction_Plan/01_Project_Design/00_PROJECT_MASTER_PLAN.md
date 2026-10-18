# BLOODLINE — Project Master Plan

**Document status:** Pre-production baseline v1.0  
**Project title:** BLOODLINE (working title; not trademark- or store-name-cleared)  
**Target:** Android first  
**Genre:** 3D side-on fighting game with supernatural action, character collection, and progression  
**Visual direction:** Stylized-realistic, cinematic but performance-conscious  
**Planning rule:** This document and the linked specifications are the source of truth until formally revised.

## 1. Executive vision

BLOODLINE is an original character-collection fighting game set in a fictional world where ancient combat traditions, contemporary cities, advanced organisations, and supernatural forces coexist. Players collect a roster of predefined fighters, learn each fighter's distinct fighting style, equip permitted weapons and cosmetics, battle AI opponents, earn rewards, and progressively unlock more content. Online multiplayer is a planned later phase. A cinematic story campaign is also planned for a later phase, after the combat and content-production foundation has proven itself.

The launch should not depend on a large cinematic story. The first complete release should stand on its own as a polished offline fighting game with meaningful progression.

## 2. Product pillars

1. **Combat first:** inputs feel responsive; attacks have readable startup, impact, and recovery; defense matters; victories are earned.
2. **Distinct fighters:** each fighter has a clear silhouette, personality, range, rhythm, signature ability, and gameplay trade-offs.
3. **Collection with purpose:** unlocking a character adds a new play style, not merely a stronger number.
4. **Stylized realism:** detailed, believable 3D fighters and arenas with a consistent art direction that can run on modest Android hardware.
5. **Expandable architecture:** additions such as fighters, weapons, arenas, events, story chapters, and online matches should use defined systems rather than require rewrites.
6. **Honest delivery:** menus, buttons, rewards, and game modes must do what they say. No placeholder flows presented as finished features.

## 3. Confirmed creative direction

- The world is fictional and mixes ancient, modern, and supernatural elements. It is not a historical reconstruction and not exclusively modern.
- Combat uses a side-on 3D camera. The characters and arenas are fully 3D, while standard duels primarily keep fighters on a controlled fighting plane.
- The visual style is stylized-realistic rather than photorealistic or cartoonish.
- Android is the first target platform.
- The core roster is made of predefined characters with authored identities and move sets.
- New players receive a starter fighter. Random starter assignment is an option to test, not a mandatory rule; onboarding must not leave a player stuck with an unusable or disliked fighter.
- Initial gameplay centres on offline fighting against AI, fighter selection, arenas, and progression.
- Online multiplayer comes later. The cinematic story campaign comes later than the initial core fighting release.
- Character collection, unlocks, weapons, equipment, and future content expansion are planned. Their exact economy and monetisation are not yet locked.

## 4. Scope and non-goals

### Initial release scope
- Android app with a reliable boot/menu/settings flow.
- Fighter selection and a small but genuinely distinct roster.
- One complete training/test arena, followed by a small set of production arenas.
- Side-on combat, touch controls, health, attacks, blocking, movement, hit reactions, special abilities, round resolution, and results.
- AI opponents with at least basic attack, defense, spacing, and difficulty tuning.
- Offline versus, practice/training, and a limited challenge or tournament structure if time and quality allow.
- Basic progression and local persistence; a small, internally consistent unlock/reward loop.
- Settings for audio and graphics where applicable; performance profiling and tested Android builds.

### Explicitly out of initial scope
- Online matchmaking, ranked servers, clans, live service infrastructure, or real-money transactions.
- A large open world or free-roam action-adventure campaign.
- A full cinematic campaign with many cutscenes, voice performances, and elaborate scripted missions.
- A huge launch roster. Do not inflate character count before the asset and combat pipeline works.
- Unlicensed copies of Mortal Kombat, Shadow Fight, or other games' characters, names, animations, music, UI, story, or signature designs.

## 5. Product phases and gates

### Phase 0 — Design and feasibility
Approve the design baseline; compare candidate engines; prove that a small 3D scene, touch input, a rigged character, animation playback, hit detection, and Android packaging work on target hardware. No content multiplication before this gate.

**Exit gate:** one documented engine choice, repeatable Android build, measured performance, verified asset import pipeline, and an agreed target-device profile.

### Phase 1 — Combat vertical slice
Create one polished-enough fighter, one opponent, one arena, a working combat loop, elementary AI, touch controls, round results, and restart/rematch. This is a playable development slice, not a separate product promise.

**Exit gate:** all core actions work, no fake controls, animation and hit detection agree, and repeated matches are stable on target hardware.

### Phase 2 — Offline fighting release
Expand to a modest, balanced roster and multiple arenas; implement fighter selection, AI difficulty, practice, versus rules, local progression, unlocks, settings, and complete UI flow.

**Exit gate:** content, saving, performance, accessibility of controls, and release builds meet the acceptance criteria in document 20.

### Phase 3 — Online multiplayer
Design and implement authoritative match flow, networking, latency handling, service/security boundaries, account and progression rules, and anti-cheat measures. This requires a separate design and risk review; offline success does not automatically prove online readiness.

### Phase 4 — Cinematic story expansion
Add a campaign chapter structure, mission scripting, enemy encounters, bosses, story scenes, dialogue, save checkpoints, and cinematic assets using the already proven combat and character pipeline.

## 6. Initial content targets

These are planning targets, not promises that content already exists:
- Vertical slice: 1 playable fighter, 1 opponent, 1 arena.
- First meaningful offline release: target 3–5 distinct fighters and 2–3 arenas, with quality taking priority over quantity.
- Expand only when models, rigs, animations, VFX, combat data, and performance all meet the content gate.
- A roster target beyond the initial release should be set after measuring actual character-production time and cost.

## 7. Technology posture

Unity is the current candidate for the feasibility test because the project needs a mature 3D animation pipeline, Android delivery, touch input, profiling, and content tooling. This is a provisional recommendation, not a final engine commitment. Godot should be evaluated as an alternative. Unreal should only be selected if a target-device test demonstrates that its rendering and production costs are appropriate for the project. The engine decision must be evidence-based; a pretty desktop screenshot is insufficient.

Blender is the default candidate for original modelling, cleanup, rig checks, UV work, and asset preparation. External character/animation tools and asset libraries may be used only after checking licensing, compatibility, editability, and export rights.

## 8. Performance and device baseline

Design for a range of Android devices, including low-memory and lower-power phones. Choose a realistic frame-rate target after profiling a representative device; aim for stable play over peak visual complexity. Establish budgets for texture memory, mesh complexity, bone count, material count, VFX, arena draw calls, and concurrent effects. Use scalable quality settings, compressed textures, pooled effects, limited overdraw, and efficient asset loading. Do not assume a low-end phone can run desktop-quality assets simply because they import successfully.

## 9. Content production principle

Every character is a complete content unit consisting of a model, materials, shared or compatible rig, animations, combat data, ability VFX, audio cues, UI portrait/icon, attribution/licensing record, and validation report. An asset is not complete because a model file exists. It is complete when it imports, animates, responds to combat, performs on target hardware, and has clear provenance.

## 10. Definition of done

A feature is done only when it is implemented, connected to the actual game state, tested on a packaged Android build, and documented. No fake matchmaking, nonfunctional inventory buttons, reward screens that grant nothing, or temporary debug systems disguised as release features. Every milestone must have a tested build and a known list of remaining defects.

## 11. Source-of-truth rules

- This plan defines scope and priorities.
- The combat specification governs combat rules.
- The roster bible governs character identity and intended differences.
- The asset pipeline governs content creation and validation.
- The data schema governs how content is represented.
- The acceptance plan governs whether work passes.
- When documents conflict, record the conflict in the technical-decision log, resolve it explicitly, then update all affected documents.

## 12. Open decisions to resolve during pre-production

1. Final title and branding.
2. Engine choice after an Android feasibility test.
3. Exact minimum Android OS, memory class, GPU class, and frame-rate target.
4. Initial roster and final character names/designs.
5. Exact starter-fighter selection rules.
6. Weapon rules: exclusive signature weapons versus interchangeable combat weapons.
7. Whether progression is entirely offline/local at first or uses an account later.
8. Whether monetisation exists at all; no monetisation is assumed by this plan.
9. Whether finishers include graphic violence, and the intended age-rating target.
10. Budget and acceptable use of third-party, paid, open-source, or AI-assisted assets.

## 13. Immediate next step

Do not begin mass character production. First finalise the combat and character targets, evaluate the engine on a real Android device, and prove the full model-to-rig-to-animation-to-game pipeline with one fighter. Then repeat the process only when the pipeline is documented and reproducible.
