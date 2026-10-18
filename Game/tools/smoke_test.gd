extends Node
## Headless smoke test.
##
## Run with:
##     godot --headless --path Game res://tools/smoke_test.tscn
##
## It builds every screen, runs a whole match between two fighters with the
## AI driving one of them, and exercises the save system. Any script error
## printed while it runs is a failure, which is what the CI workflow checks.
##
## The test never renders, so it is safe to run without a display.

## Every screen in the game, in the order the player meets them.
const SCREENS := [
	"res://scenes/Boot.tscn",
	"res://scenes/MainMenu.tscn",
	"res://scenes/FighterSelect.tscn",
	"res://scenes/VersusSetup.tscn",
	"res://scenes/Loading.tscn",
	"res://scenes/VSCard.tscn",
	"res://scenes/Match.tscn",
	"res://scenes/Results.tscn",
	"res://scenes/Practice.tscn",
	"res://scenes/Collection.tscn",
	"res://scenes/Settings.tscn",
]

## The frames each screen is left in the tree before it is torn down.
const SCREEN_FRAMES := 4

## The match id the save test uses. It is far above any timestamp the game
## can produce, so the test always starts from an unclaimed match.
const TEST_MATCH_ID := 99999999999

## How many simulated frames the match is run for.
const MATCH_FRAMES := 600

## The test must never run longer than this many frames, whatever happens.
const FRAME_BUDGET := 6000

var _queue: Array = []

var _current: Node = null

var _frames: int = 0

var _failures: int = 0

var _phase: String = "screens"

var _match: MatchManager = null

var _match_frames: int = 0

var _damage_seen: float = 0.0

var _frames_used: int = 0


func _ready() -> void:
	for path in SCREENS:
		_queue.append(path)
	print("smoke: starting")


func _process(_delta: float) -> void:
	_frames_used += 1
	if _frames_used > FRAME_BUDGET:
		_failures += 1
		push_error("smoke: the frame budget of %d was exhausted in phase %s" % [FRAME_BUDGET, _phase])
		_finish()
		return
	match _phase:
		"screens":
			_step_screens()
		"match":
			_step_match()
		"save":
			_step_save()
		_:
			_finish()


# --- Screens ---------------------------------------------------------------


func _step_screens() -> void:
	if _current != null:
		_frames += 1
		if _frames > SCREEN_FRAMES:
			_current.queue_free()
			_current = null
		return

	if _queue.is_empty():
		print("smoke: every screen built")
		_phase = "match"
		return

	var path: String = _queue.pop_front()
	var packed: PackedScene = load(path)
	if packed == null:
		_failures += 1
		push_error("smoke: cannot load %s" % path)
		return

	_current = packed.instantiate()
	add_child(_current)
	_frames = 0
	print("smoke: built %s" % path)


# --- A whole match ---------------------------------------------------------


func _step_match() -> void:
	if _match == null:
		_match = MatchManager.new()
		_match.setup("unbound", "dagan", "circuit_pit", "standard", 2, 60)
		add_child(_match)
		_match_frames = 0
		print("smoke: match started")
		return

	_match.simulate(1.0 / 60.0)
	_match_frames += 1

	if _match_frames >= MATCH_FRAMES:
		_damage_seen = _match.damage_taken("dagan")
		var damage_to_player := _match.damage_taken("unbound")
		var combos := _match.combo_count("dagan")
		print(
			(
				"smoke: match ran %d frames, winner='%s', damage to dagan %.1f, to the player %.1f, combo %d"
				% [_match_frames, _match.round_winner, _damage_seen, damage_to_player, combos]
			)
		)
		print("smoke: the ai says: %s" % _match.ai_debug())
		# The player never presses a button, so the AI has to close the
		# distance and land the first hits on its own.
		if damage_to_player <= 0.0:
			_failures += 1
			push_error("smoke: the ai did not land a single hit in %d frames" % MATCH_FRAMES)
		_match.queue_free()
		_match = null
		_phase = "save"


# --- The save system -------------------------------------------------------


func _step_save() -> void:
	var result: Dictionary = SaveSystem.record_match(TEST_MATCH_ID, "unbound", "dagan", true, 2)
	print("smoke: record_match -> %s" % result)
	if not bool(result.get("ok", false)):
		_failures += 1
		push_error("smoke: record_match failed: %s" % result)

	# The same match id must never be credited twice.
	var second: Dictionary = SaveSystem.record_match(TEST_MATCH_ID, "unbound", "dagan", true, 2)
	print("smoke: record_match again -> %s" % second)
	if bool(second.get("ok", false)):
		_failures += 1
		push_error("smoke: record_match was not idempotent: %s" % second)
	elif String(second.get("reason", "")) != "already_claimed":
		_failures += 1
		push_error("smoke: the second claim failed for the wrong reason: %s" % second)

	_phase = "done"


func _finish() -> void:
	if _failures > 0:
		print("smoke: FAILED with %d problems" % _failures)
		get_tree().quit(1)
	else:
		print("smoke: PASSED")
		get_tree().quit(0)
