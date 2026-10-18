# Combat System Specification

## Combat goal

Deliver responsive, readable side-on 3D duels on touch devices. Player intention, animation timing, hit detection, and visual feedback must agree. Use a stable fighting plane for ordinary matches; limited depth movement is optional only if it improves gameplay without destroying readable spacing.

## Match states

At minimum: Loading, Intro, RoundReady, Fighting, HitPause, RoundEnd, MatchEnd, Results, and Rematch/Exit. State changes must be explicit. Inputs that are invalid in a state are safely ignored or queued according to a documented buffer rule. Pause and app lifecycle interruptions must not leave a match stuck.

## Fighter states

Neutral/Idle, WalkForward, WalkBackward, Crouch, Jump/airborne, Startup, ActiveAttack, Recovery, Guard, Hitstun, Blockstun, Knockdown, Wakeup, Throw/Thrown, Dodge, Ability, Ultimate, Victory, Defeat. Avoid uncontrolled animation transitions. Define legal transitions and interruption rules.

## Input actions

Movement left/right; optional crouch/jump; light attack; heavy attack; guard; dodge or a defensive directional action; signature ability; ultimate/finisher if included. Map actions to touch buttons in a manner that works on small screens. Controller support can be added later but should not complicate launch scope.

## Attack data

Each move must define:
- Stable move ID and display/localisation key.
- Valid start states, input mapping, and buffer window.
- Startup, active, and recovery durations in a consistent time/frame convention.
- Hitbox shape, local transform, active windows, and collision category.
- Damage, chip damage if any, hit reaction, block reaction, pushback, launch/knockdown, and cancel/chain windows.
- Range assumptions, resource cost, cooldown, and whether the move can be interrupted.
- Animation/VFX/audio references and training display name.
- AI tags and balance notes.

Avoid scattering unexplained timing constants through code. Move data should be inspectable and validated.

## Hit detection and collision

Use explicit attack hit volumes active only during defined move windows. Separate hurt volumes from arena collision. Ensure a single attack cannot repeatedly damage the same target every simulation tick unless the move is explicitly multi-hit. Define priority and trade rules for simultaneous strikes. Add debug rendering for hit/hurt volumes in development builds only. Test at variable frame rates and on device.

## Combat timing and input buffering

Prefer deterministic, fixed-step combat simulation where supported by the chosen engine. Rendering may vary, but move timers and hit checks should use a consistent timing source. Input buffering should make touch controls forgiving without allowing arbitrary action spam. Document buffer duration and cancel windows; test on real touchscreen latency.

## Movement, range, and facing

Fighters automatically face opponents in ordinary duels, subject to carefully defined behavior during knockbacks and throws. Walking acceleration and turning should not feel slippery. Define pushbox behavior to prevent fighters from overlapping. Arena bounds should prevent escaping the playable area. Side switching must update controls and facing consistently.

## Defense

Guard direction may be simplified for mobile. Decide whether high/low guard, crouching defense, parries, throws, and guard breaks are in the initial ruleset. Do not implement every fighting-game mechanic at once. Baseline recommendation: standard guard, dodge/evade, punishable attack recovery, and limited throw or guard-break mechanics added only after core combat feels reliable.

## Combos and cancel rules

Specify valid links/cancels per move. Prevent infinite loops through recovery, juggle limits, hitstun decay, resource constraints, or move-specific restrictions. Combo tracking should be reliable and reset under defined circumstances. Every character must be tested for accidental infinite combos and mobile input ambiguity.

## Special abilities and ultimate attacks

Each fighter has a signature ability whose effect reinforces their archetype. The ability must have readable startup, a fair range, clear visual tell, defined damage/status effect, cost/cooldown, recovery, and counterplay. Cinematic presentation must not make the player lose control unexpectedly for too long. Finishing moves are optional and may be added once the standard combat is stable.

## Health, rounds, and results

Define base health, damage scaling, match length, timer behavior, tie rules, round reset rules, special-meter reset rules, and result evaluation. Keep the initial rules simple. Save rewards only after a match resolves validly. Quitting, app termination, or corrupted state must not duplicate rewards.

## AI interaction

AI uses the same legal moves, cooldowns, hit detection, and resource rules. It may have controlled reaction delay and strategy differences by difficulty, but it must not input impossible attacks or ignore all recovery. See the AI specification.

## Combat feedback

Required feedback: attack anticipation, clear contact, hit reaction, block reaction, hit-stop or equivalent impact emphasis, moderate camera response when suitable, audio cues, health change, ability state, and round outcome. Effects must not conceal the opponent or reduce readability.

## Initial implementation order

1. Movement, facing, boundaries, and pushboxes.
2. Light/heavy attacks and reliable hit detection.
3. Hit/block reactions and health.
4. Guard, recovery, round logic, and result/restart.
5. Basic AI.
6. Combo and ability framework.
7. Character-specific mechanics, polish, and balance.

## Test cases

Test edge collisions, simultaneous attacks, blocked and unblocked hits, one-hit-per-window behavior, round resets, side swaps, ability cooldown, interruption rules, touch input buffering, low frame rate, pause/resume, repeated matches, and every character matchup. Combat is not approved based on a single successful demonstration.
