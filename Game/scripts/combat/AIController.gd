class_name AIController

extends Node
## The AI opponent.
##
## The AI drives a `Fighter` through the same public API the player uses:
## it can only start moves that the fighter is allowed to start, and it
## suffers the same cooldowns, meter costs, frame data and hurt volumes.
## Difficulty changes decision quality only - reaction delay, spacing
## preference, how often it punishes and how well it manages meter.

enum Skill {
	BEGINNER,
	STANDARD,
	ADVANCED,
}

const BEGINNER := {
	"reaction": 22,
	"decision_interval": 26,
	"aggression": 0.28,
	"punish_rate": 0.20,
	"spacing": 2.6,
	"block_rate": 0.35,
	"combo_length": 1,
	"meter_hoard": 0.75,
}

const STANDARD := {
	"reaction": 13,
	"decision_interval": 15,
	"aggression": 0.52,
	"punish_rate": 0.48,
	"spacing": 2.1,
	"block_rate": 0.55,
	"combo_length": 2,
	"meter_hoard": 0.55,
}

const ADVANCED := {
	"reaction": 7,
	"decision_interval": 9,
	"aggression": 0.72,
	"punish_rate": 0.74,
	"spacing": 1.8,
	"block_rate": 0.72,
	"combo_length": 3,
	"meter_hoard": 0.35,
}

## The fighter this controller drives.
var fighter: Fighter = null

## The opponent.
var opponent: Fighter = null

## The current skill tier.
var skill: int = Skill.STANDARD

var _reaction_frames: int = 0

var _pending_action: String = ""

var _decision_timer: int = 0

var _last_thought: String = ""

var _combo_timer: int = 0

var _combo_plan: Array[String] = []

var _frustration: int = 0


func setup(controlled: Fighter, difficulty: String) -> void:
	fighter = controlled
	opponent = controlled.opponent
	match difficulty.to_lower():
		"beginner":
			skill = Skill.BEGINNER
		"advanced":
			skill = Skill.ADVANCED
		_:
			skill = Skill.STANDARD
	_reaction_frames = _profile()["reaction"]
	_decision_timer = _profile()["decision_interval"]


func _profile() -> Dictionary:
	match skill:
		Skill.BEGINNER:
			return BEGINNER
		Skill.ADVANCED:
			return ADVANCED
		_:
			return STANDARD


## Called once per simulation frame.
func think(_delta: float) -> void:
	if fighter == null or opponent == null:
		return
	if fighter.is_knocked_out() or fighter.is_finished() or fighter.is_intro():
		return

	_update_combo_plan()

	# React to what the opponent is doing.
	var threat := _opponent_threat()
	match threat:
		"attack":
			_maybe_block()
			_maybe_dodge()
		"recover":
			_maybe_punish()
		_:
			pass

	_decision_timer -= 1
	if _decision_timer <= 0:
		_decision_timer = int(_profile()["decision_interval"])
		_decide()


## The current decision, shown in the debug overlay.
func debug_line() -> String:
	return "AI[%s]: %s" % [_skill_name(), _last_thought]


func _skill_name() -> String:
	match skill:
		Skill.BEGINNER:
			return "Beginner"
		Skill.ADVANCED:
			return "Advanced"
		_:
			return "Standard"


## How dangerous the opponent's current action looks.
func _opponent_threat() -> String:
	if opponent.is_startup():
		return "attack"
	if opponent.is_active():
		return "attack"
	if opponent.is_recovery():
		return "recover"
	return "neutral"


func _distance() -> float:
	return fighter.body_position.distance_to(opponent.body_position)


func _decide() -> void:
	var profile := _profile()
	var distance := _distance()

	# A combo in progress takes priority.
	if _combo_plan.size() > 0 and _combo_timer > 0:
		var next_move := _combo_plan.pop_front()
		_combo_timer -= 1
		if _start(next_move):
			_last_thought = "combo -> %s" % next_move
			return

	# Use the signature when it is worth it.
	if _should_use_ability(distance, profile):
		_last_thought = "ability"
		if _start("ability"):
			return

	if distance > float(profile["spacing"]) + 0.9:
		_decide_approach(profile)
	elif distance < 1.6:
		_decide_point_blank(profile)
	else:
		_decide_mid_range(profile)


## Long range: close the gap or keep the spacing.
func _decide_approach(profile: Dictionary) -> void:
	if randf() < float(profile["aggression"]) + 0.2:
		_last_thought = "approach"
		fighter.buffer_input("forward")
	else:
		_last_thought = "spacing"
		fighter.buffer_input("back")


## Point blank: light and heavy attacks, or guard.
func _decide_point_blank(profile: Dictionary) -> void:
	var aggression := float(profile["aggression"])
	var roll := randf()
	if roll < aggression:
		_last_thought = "light"
		if _start("light_attack"):
			return
	elif roll < aggression + 0.25:
		_last_thought = "heavy"
		if _start("heavy_attack"):
			return
	_last_thought = "guard"
	fighter.guard_held = true


## Mid range: poke or wait.
func _decide_mid_range(profile: Dictionary) -> void:
	if randf() < float(profile["aggression"]) * 0.7:
		_last_thought = "poke"
		if _start("light_attack"):
			return
	_last_thought = "wait"


func _should_use_ability(distance: float, profile: Dictionary) -> bool:
	var move := ContentDB.get_move_for(fighter.fighter_id, "ability")
	if move.is_empty():
		return false
	var cost := float(move.get("meter_cost", 0))
	if fighter.meter < cost:
		return false
	# Advanced AI holds the ability for a better window.
	if fighter.meter < float(profile["meter_hoard"]) * 100.0:
		return false
	return distance < 3.0


func _maybe_block() -> void:
	var profile := _profile()
	if randf() > float(profile["block_rate"]):
		return
	fighter.guard_held = true
	_last_thought = "block"


func _maybe_dodge() -> void:
	var profile := _profile()
	if randf() > float(profile["punish_rate"]) * 0.35:
		return
	if not fighter.can_start_move("dodge"):
		return
	if _start("dodge"):
		_last_thought = "dodge"


func _maybe_punish() -> void:
	var profile := _profile()
	if randf() > float(profile["punish_rate"]):
		return
	if _distance() > 2.6:
		return
	_last_thought = "punish"
	_start("light_attack")


## Plans a short combo when the AI is confident.
func _update_combo_plan() -> void:
	if _combo_timer > 0:
		return
	var profile := _profile()
	if randf() > float(profile["aggression"]):
		return
	var length := int(profile["combo_length"])
	if length <= 0:
		return
	_combo_plan.clear()
	for i in range(length):
		if i == length - 1 and randf() < 0.4:
			_combo_plan.append("heavy_attack")
		else:
			_combo_plan.append("light_attack")
	_combo_timer = 40


## Starts a move if the fighter is allowed to, honouring the same rules the
## player is bound by.
func _start(move_id: String) -> bool:
	if not fighter.can_start_move(move_id):
		return false
	return fighter.start_move(move_id)
