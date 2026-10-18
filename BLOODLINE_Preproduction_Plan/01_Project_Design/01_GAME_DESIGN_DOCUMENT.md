# Game Design Document

## High concept

A stylized-realistic, side-on 3D fighting game set in an original ancient-modern-supernatural universe. Players collect predefined fighters, master distinct move sets, earn unlocks through AI battles, and later compete online. A deeper cinematic story is planned as a future expansion.

## Target audience and session shape

Primary audience: players who enjoy character-driven fighting games, action combat, collecting fighters, and improving through repeat matches. Design for short mobile sessions, but allow longer practice and tournament sessions. The first experience should get a player from launch to a fight with minimal friction.

## Player fantasy

“I own a growing roster of visually distinct warriors. I understand what makes each one dangerous, choose the right fighter for my style, and earn my progress through combat.” The game should reward learning and mastery, not only grinding.

## Core loop

Launch → choose a mode → select fighter/arena/opponent → fight → review result → earn appropriate reward/progression → improve or unlock content → fight again.

## Pillars translated into features

- Immediate play: a clear Play/Versus path and quick rematch.
- Character identity: distinct silhouettes, idle poses, move cadence, unique signature mechanics, and well-tuned voice/audio cues if supported.
- Readable combat: attack wind-up and impact are legible even on a small screen; VFX must not hide the opponent.
- Fair progression: new fighters broaden choice; paid or rare content, if introduced, must not create unavoidable pay-to-win advantages.
- Expansion readiness: data-driven fighter definitions and reusable content pipelines.

## Modes and launch priorities

### Versus (offline)
Player selects a fighter and AI-controlled opponent, arena, rounds, and difficulty. Results include winner, round outcome, and earned rewards if the mode is reward-enabled. A rematch returns to combat quickly. Avoid making every match require multiple unnecessary menus.

### Practice
The opponent can remain idle, guard, or perform a selected behavior. Display training feedback such as damage, combo count, and move input where feasible. Practice is a learning environment, not a source of easily farmed currency.

### Challenge/tournament
An optional structured chain of opponents, with clear rules and rewards. Implement only after ordinary versus, results, AI, and persistence are reliable.

### Story campaign (future)
Mission chapters, cinematic transitions, dialogue, boss encounters, and character-specific plot lines. Design hooks now, but do not make launch dependent on this content.

### Online multiplayer (future)
Player-vs-player matches, private rooms, matchmaking, and later ranked modes. Not represented as available until real networking, security, matchmaking, and connection-loss handling are implemented and tested.

## Match structure

Use configurable round count, round timer if appropriate, starting health, and victory conditions. For the first implementation, choose straightforward one-on-one matches with a clear reset between rounds. Define whether special meters reset between rounds and whether damage carries between rounds; consistency matters more than complexity.

## Meta progression

Players can earn experience and in-game currency from defined activities. Fighters may have unlock conditions and mastery progression. Keep character unlock, fighter mastery, account/player progression, cosmetics, and equipment as distinct concepts so their rules do not become tangled. Avoid adding daily chores or online-only rewards to an offline-first game unless the product direction changes.

## Economy principles

- Rewards are communicated before the activity where practical.
- No reward is displayed as granted until it is actually persisted.
- A player should be able to understand why they earned a reward.
- Combat strength and cosmetic appearance should be separated where possible.
- If random rewards are ever introduced, display odds and follow relevant platform rules and applicable law.
- Real-money monetisation is not currently approved scope.

## UX principles

A new player should be able to start a first fight quickly. Use readable text, high-contrast interactive states, safe touch targets, clear focus states, and concise descriptions of special abilities. During combat, avoid covering fighters with HUD elements. Permit control sensitivity and audio adjustment where feasible. Support varied aspect ratios and screen cut-outs.

## Accessibility and usability

Use distinct icons plus labels for important functions; do not rely on colour alone. Allow buttons to be repositioned or scaled if implementation budget permits. Provide clear audio/visual cues for major attacks. Make motion effects adjustable where possible. Ensure combat feedback remains readable without loud audio.

## Art direction

Characters should use believable anatomy and materials with a deliberate stylized treatment: controlled proportions, expressive faces, strong shape language, readable costume details, and restrained supernatural effects. Avoid a mix of unrelated free assets. Arenas need strong silhouettes and controlled contrast so the fighters remain the focal point.

## Audio direction

Every attack class needs distinct impact, movement, block, hit, ability, menu, and result feedback. Sound should reinforce weight without becoming repetitive or painfully loud. Use only original or properly licensed audio and maintain a source register.

## Content cadence

Prioritise quality fighter releases over frequent low-quality drops. New fighters should pass the same art, rig, animation, gameplay, balance, performance, and licensing gates as the initial roster.

## Success metrics

During development, measure: successful first fight, combat action reliability, rematch rate in test sessions, AI behavior variety, save integrity, crash-free match sessions, sustained frame rate, load time, memory use, and percentage of features passing acceptance tests. Player analytics require a separate privacy and consent review if added later.

## Risks

The largest risks are combat that feels weak, asset inconsistency, animation mismatch, scope creep, poor Android performance, and an over-large roster before the production pipeline is validated. The answer is a small complete vertical slice and measurable gates.
