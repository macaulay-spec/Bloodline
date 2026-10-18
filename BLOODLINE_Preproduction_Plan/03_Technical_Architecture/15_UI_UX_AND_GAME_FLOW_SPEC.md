# UI/UX and Game Flow Specification

## UX goal

A player should understand the next action quickly and reach a fight with minimal menu friction. The presentation should match the stylized-realistic world: strong character portraits, restrained effects, clear hierarchy, readable typography, and purposeful animation. No generic blank screens or nonfunctional buttons.

## Main flow

Boot → profile/local save initialization → main menu → mode selection → fighter selection → opponent/difficulty selection → arena/rules selection → match loading → intro/ready state → match → results → rematch or menu.

## Required screens

### Boot/loading
Initialise settings and content. Show actual loading status only where measurable; handle missing data with a useful error rather than hanging indefinitely.

### Main menu
Primary actions: Play/Versus, Fighters, Practice, Collection/Equipment, Settings. Hide unfinished modes or label them clearly as unavailable. Avoid putting online multiplayer in the primary navigation before it exists.

### Fighter selection
Show owned/locked status, portrait, name, archetype, short ability explanation, and action to select or inspect. A locked fighter should have a real unlock condition, not a dead button. Show enough visual scale and animation to distinguish fighters.

### Versus setup
Select AI opponent, difficulty, arena, and match rules. Persist sensible defaults. Make random selection optional and understandable.

### Combat HUD
Health, round/time state if applicable, ability resource/cooldown, pause, and clear fighter identity. Keep controls away from important visual action. Adapt to portrait/landscape decision and safe areas; landscape is the recommended default for side-on fighting, pending device testing.

### Results
Clearly show winner, match outcome, and rewards when granted. Provide rematch and exit. Do not show currency changes before persistence succeeds. Handle draw/quit outcomes explicitly.

### Collection/equipment
Filter owned and locked content. Present fighter/weapon compatibility, cosmetic/combat effect, unlock progress, and equip state. Use a confirmation step for irreversible actions only if any exist.

### Settings
Audio levels, haptics if supported, graphics quality, control layout/scale where feasible, language if supported, privacy/legal/about, and reset-save safeguards. Do not expose developer/debug options in release builds.

## Navigation rules

Every visible interactive element must have a defined action, disabled state, loading/error state where relevant, and test. Back navigation should preserve reasonable setup state without interrupting a live match accidentally. Pausing must have clear resume/restart/quit behavior.

## Visual hierarchy

Use a clear primary action per screen. Maintain text contrast, readable type at common mobile sizes, adequate touch targets, consistent icon meaning, and consistent spacing. Use character art intentionally; do not fill every area with cards, glow, or motion. Reserve high-intensity effects for significant actions.

## Landscape and device adaptation

Side-on combat is best tested in landscape. Validate notches, gesture areas, unusual aspect ratios, small resolutions, button overlap, text truncation, and safe areas. If portrait menus are considered, preserve consistent transitions and test the resulting interaction model before committing.

## State handling

Disable inputs while required transitions are loading. Protect against double taps, repeated match-start events, multiple reward claims, and input bleed from the menu into gameplay. Display clear error feedback for recoverable failures.

## UX acceptance

A test user should be able to launch, start a match, understand core controls, finish a match, identify rewards, rematch, and return to the menu without guidance or dead ends. Repeat this flow on a packaged Android build, not only inside the editor.
