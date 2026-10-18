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

## How many simulated frames the match is run for.
const MATCH_FRAMES := 600

var _queue: Array[String] = []

var _current: Node = null

var _frames: int = 0

var _failures: int = 0

var _phase: String = "screens"

var _match: Node = null

var _match_frames: int = 0

var _damage_seen: float = 0.0


func _ready() -> void:
	_queue = SCREENS.duplicate()
	print("smoke: starting")


func _process(_delta: float) -> void:
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
		return

	_match.simulate(1.0 / 60.0)
	_match_frames += 1

	if _match_frames == 120:
		_damage_seen = _match.damage_taken("dagan")
		print("smoke: match running, damage to dagan %.1f" % _damage_seen)

	if _match_frames >= MATCH_FRAMES:
		print(
			(
				"smoke: match ran %d frames, winner=%s, damage=%.1f"
				% [_match_frames, _match.round_winner, _damage_seen]
			)
		)
		_match.queue_free()
		_match = null
		_phase = "save"


# --- The save system -------------------------------------------------------


func _step_save() -> void:
	var result: Dictionary = SaveSystem.record_match(900001, "unbound", "dagan", true, 2)
	print("smoke: record_match -> %s" % result)
	if not bool(result.get("ok", false)):
		_failures += 1
		push_error("smoke: record_match failed: %s" % result)

	# The same match id must never be credited twice.
	var second: Dictionary = SaveSystem.record_match(900001, "unbound", "dagan", true, 2)
	print("smoke: record_match again -> %s" % second)
	if bool(second.get("ok", false)):
		_failures += 1
		push_error("smoke: record_match was not idempotent: %s" % second)

	_phase = "done"


func _finish() -> void:
	if _failures > 0:
		print("smoke: FAILED with %d problems" % _failures)
		get_tree().quit(1)
	else:
		print("smoke: PASSED")
		get_tree().quit(0)
