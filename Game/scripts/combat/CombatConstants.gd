class_name CombatConstants

extends RefCounted
## Shared combat constants.
##
## Every number here is part of the combat contract: the player and the AI
## read the same values, so the rules never diverge between them.

## Frames per second the simulation runs at.
const FPS := 60

## Seconds per simulation frame.
const FRAME := 1.0 / float(FPS)

## Distance the two fighters start apart.
const START_DISTANCE := 3.2

## Half-width of the fighting area; fighters are clamped inside it.
const ARENA_HALF_WIDTH := 10.0

## Fighters cannot walk through each other.
const PUSHBODY_MARGIN := 0.05

## Health at which a fighter is knocked out.
const HEALTH_MAX := 1000.0

## Guard meter points lost when the guard breaks.
const GUARD_BREAK_PENALTY := 40.0

## Frames a fighter stays broken after their guard breaks.
const GUARD_BREAK_FRAMES := 72

## Frames the guard-break warning is shown before the break lands.
const GUARD_BREAK_TELEGRAPH := 24

## Minimum frames between rounds.
const ROUND_INTRO_FRAMES := 90

## Frames the KO slow-motion lasts.
const KO_FREEZE_FRAMES := 70

## Frames between rounds.
const ROUND_END_FRAMES := 100

## Base damage of a blocked attack that still chips.
const CHIP_SCALE := 0.12

## Minimum meter needed to use a signature ability.
const ABILITY_METER_FLOOR := 50.0

## Input buffer window in frames.
const INPUT_BUFFER_FRAMES := 8

## How many frames of a move may be cancelled into the next one.
const CANCEL_WINDOW := 20

## Debug overlay colour for the AI's chosen action.
const AI_DEBUG_COLOR := Color(1.0, 0.85, 0.2)
