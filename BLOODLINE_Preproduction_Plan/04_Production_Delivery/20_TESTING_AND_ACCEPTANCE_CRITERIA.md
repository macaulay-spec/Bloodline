# Testing and Acceptance Criteria

## Test philosophy

Test the actual player experience and the underlying rules. Each feature must have a stated pass condition. Do not accept screenshots, a successful editor session, or a single demonstration as proof of a complete feature.

## Test layers

### Content validation
Check missing references, duplicate IDs, invalid combat values, absent animation clips, incompatible equipment, missing portraits, and missing licence records.

### Unit/system tests
Where supported, test move legality, health changes, cooldowns, round outcomes, reward application, save validation, and progression conditions in isolation.

### Integration tests
Test the chain from input through combat state and hit resolution to animation feedback, match end, reward handling, saving, and reloading.

### Playtesting
Human testing is required for responsiveness, clarity, perceived impact, AI fairness, balance, readability, difficulty, and fun. These cannot be established solely by automated tests.

### Device tests
Install packaged APKs on the supported Android set and test input, visuals, sound, performance, interruption, memory, repeated fights, and controls at real screen sizes.

## Combat acceptance

- Every configured attack produces the expected hit/block/miss behavior.
- Attack hit volumes open and close according to move data.
- No unintended repeated hits occur from a single hit window.
- Invalid moves cannot execute from prohibited states.
- Guard, hitstun, knockdown, wake-up, and round reset transitions recover correctly.
- Fighter facing, pushboxes, and arena boundaries work on both sides.
- Ability costs and cooldowns are enforced.
- No known infinite combo or reliable unintended exploit remains without an explicit design decision.

## AI acceptance

- AI moves only through legal action pathways.
- All difficulty levels are meaningfully different and playable.
- AI does not become permanently stuck or spam a single action indefinitely without a design reason.
- AI handles boundaries, knockdowns, cooldowns, and round resets.
- AI has no hidden damage or timing advantage beyond documented settings.

## UX acceptance

A tester can launch, start a match, identify their fighter, understand controls, finish a fight, see the correct result/reward, rematch, and return to the menu without dead ends. Every button performs its stated action or is visibly disabled with an explanation.

## Progression/save acceptance

- Rewards apply once per eligible match.
- Practice rules are enforced.
- Fighter ownership and equipment compatibility are respected.
- Save survives app close/relaunch and expected interruption scenarios.
- Corrupt/old save data fails safely or migrates correctly.
- Unlock conditions are visible and cannot be bypassed by a simple repeat event.

## Art/asset acceptance

- Character silhouette and materials match the approved direction.
- Rigging and deformation are acceptable in all required animations.
- Weapons remain attached and visibly align with attacks.
- No severe clipping or broken pose in core combat.
- Effects support readability.
- Frame time and memory stay within measured budgets.
- All assets have traceable usage rights.

## Android/performance acceptance

Use a real packaged APK. Record device, OS, build, graphics preset, and test duration. Test cold start, match loading, long fight, rematch cycles, background/resume, low-memory behavior, and ability-heavy moments. Pass against the target set and threshold established in the engine/performance documents. Do not claim “works on all devices.”

## Defect severity

- **Blocker:** app cannot launch/play, data loss, core combat broken, severe exploit, or release/legal blocker.
- **Critical:** frequent crashes, incorrect match resolution/rewards, or a major feature unusable.
- **Major:** significant character, AI, UI, or performance defect with a workaround only.
- **Minor:** visual/audio/layout issues with limited impact.
- **Polish:** low-impact refinement.

Release is blocked by open blockers and critical defects. Remaining known defects must be documented and consciously accepted.

## Evidence

For each gate, retain build identifier, test checklist, device details, logs/screenshots or short recordings where useful, defects found, and approval outcome. Store these as project evidence, not as a substitute for the actual build.
