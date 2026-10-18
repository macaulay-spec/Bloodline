# AI and Opponent Architecture

## Goal

Create AI opponents that feel like fighters with styles and readable decisions. AI must use the same health, move legality, cooldown, hit detection, and resource rules as the player. Difficulty must not secretly depend on impossible reaction speed or arbitrary damage bonuses.

## Decision inputs

AI evaluates: distance and relative position, current fighter states, opponent startup/recovery if observable, health and meter, cooldowns, arena boundaries, available legal actions, recent action history, archetype preferences, and difficulty parameters. Decisions should be explainable in debug output.

## Baseline behavior

1. Maintain useful range for the selected archetype.
2. Approach or retreat when appropriate.
3. Attack only when a legal move is available and the situation makes sense.
4. Defend or evade under defined conditions.
5. Punish obvious unsafe recovery with a probability appropriate to difficulty.
6. Use the signature ability under its intended conditions.
7. Avoid getting trapped indefinitely at arena boundaries.
8. Recover correctly from hitstun, knockdown, and round reset.

## Archetype policies

- **Aggressive:** pursues and applies pressure, with punishable patterns.
- **Defensive:** guards, retreats, and counters, but can be opened through throws or pressure if supported.
- **Technical:** varies range, selects moves based on spacing, and uses more intentional punish windows.
- **Boss:** uses a distinct but telegraphed sequence of moves or phases. Boss rules remain fair and visible.

## Difficulty parameters

Beginner: fewer action choices, slower decision cadence, high telegraph clarity, limited combos, and generous errors.  
Standard: mixes attacks and defense, recognises some punish opportunities, uses the core kit.  
Advanced: improved spacing, adaptation to repeated patterns, better resource use, and more reliable punish attempts. It still obeys the same move timings and legal-state rules.

## Avoiding cheating

No reading unobservable input from the player, no attacks during invalid states, no ignored cooldowns, no impossible guard changes, and no unannounced damage multipliers. Reaction timing can vary by difficulty but must stay within the documented range. If the AI has access to attack startup information, it should be because the game rules make that information observable, not because it can read hidden future input.

## Decision architecture

A lightweight utility/priority system is sufficient for the first release. For each decision tick, filter illegal actions, score remaining actions according to situation and archetype, add controlled variation, and select the best candidate. Use cooldowns and history to prevent repetitive behavior. A behavior tree or other approach may be chosen later if it offers clear benefits.

## Training and debugging

Expose current intent, target distance, selected action, score, and reason in development builds. Add deterministic or reproducible test scenarios where possible. Test AI against every fighter, at boundaries, while knocked down, near round end, after ability use, and following repeated player actions.

## Balance tests

- Is Beginner beatable by a new player without being inert?
- Does Standard use a meaningful range of actions?
- Can Advanced be beaten through learning rather than exploit or luck?
- Does any AI get stuck endlessly guarding, moving away, or spamming one move?
- Are special abilities used at sensible distances and timings?
- Does AI match reset cleanly?
- Can the player exploit the same loop to gain unlimited rewards?
