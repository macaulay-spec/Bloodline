# Game Modes and Progression

## Launch mode priority

1. Offline versus against AI.
2. Practice/training.
3. A modest challenge/tournament mode, only after versus and saving are reliable.
4. Story campaign later.
5. Online multiplayer later.

The interface must clearly label modes that are planned but unavailable; preferably omit them from the first release instead of presenting fake buttons.

## Versus setup

Flow: select mode → select owned fighter → choose AI fighter or random eligible opponent → choose arena → select difficulty and rules → load match → play → results → rematch or exit. Minimise taps between matches. Provide a random selection option only where the rules make its result clear.

## AI difficulty

Suggested levels: Beginner, Standard, Advanced. Difficulty changes decision quality, guard tendency, reaction delay within plausible limits, spacing decisions, combo selection, and resource use. It should not secretly alter the player's damage or give the AI impossible input speed. Every difficulty level must be playtested for frustration and exploitability.

## Practice mode

Potential options: dummy idle, guard, attack on cue, or use one chosen behavior. Display combo count, damage, and optional move input feedback. Training should not give progression rewards that can be farmed indefinitely. A reset button must restore both fighters to a known state.

## Challenge and tournament mode

A sequence of configured opponents with a finish condition and a reward. Use fixed or well-defined opponent sets. Handle loss, retry, exit, and save continuity. Introduce this only after standard versus is polished.

## Fighter collection

Each character has an ownership state, unlock condition, mastery progression (if enabled), and content dependencies. The default is predefined fighters, not a free-form avatar editor. New fighters must be identifiable by portrait, name, archetype, and signature ability before unlock.

## Equipment and weapons

Keep character identity and equipment compatibility explicit. A weapon may be a fighter's signature weapon, an alternate moveset, or cosmetic-only equipment. The initial release should prefer a small number of well-tested equipment rules over a sprawling inventory. Every combat-affecting item must have measurable trade-offs and matchup tests. Cosmetics should not affect combat balance.

## Currency and rewards

A small economy is preferable at launch. Define each currency, its sources, sinks, caps, save representation, and anti-duplication rules. Rewards can come from first-time milestones, match completion, challenge completion, or progression. Reward amounts must be data-driven and tuned from playtests. Do not invent numbers until time-to-unlock has been tested.

## Starter fighter

A random starter can create excitement, but it also risks giving two new players uneven onboarding experiences. If randomised, draw only from a curated beginner pool, guarantee comparable usability, explain the result, and provide an eventual alternate-fighter path. A fixed starter plus an early unlock choice is a safer alternative. This remains an open product decision.

## Progression layers

Keep these independent in data design:
- Player/account progression: global milestones.
- Fighter ownership: which characters are available.
- Fighter mastery: optional play-based growth or cosmetics for a particular fighter.
- Equipment ownership and loadout: items the player can equip.
- Story progression: future campaign chapter/checkpoint state.

Avoid permanent stat progression that makes old content trivial or makes competitive balance impossible. Prefer new choices, cosmetics, and controlled improvements over unbounded power inflation.

## Offline-first persistence

The first release should function without an account or network if feasible. Save player settings, ownership, currency, mastery, and unlocked content locally using the chosen engine's supported persistence approach. Add versioning, migration strategy, safe writes, and corruption recovery. Clearly document that local data may not transfer between devices until an account/cloud-save feature exists.

## Future online mode

Online multiplayer needs a separate scope, threat model, networking design, service costs, moderation/abuse policy, disconnect behavior, and server-side validation. Do not treat local versus as proof of online readiness. Never let the client be the sole authority for valuable progression or competitive results in an online release.

## Future story campaign

Campaign missions can reuse fighter combat, AI, arenas, boss logic, dialogue, and save systems. Keep story triggers and mission rules modular, but postpone cinematic production until the roster and combat foundation are reliable.
