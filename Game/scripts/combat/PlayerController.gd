class_name PlayerController

extends Node
## Turns player input into fighter actions.
##
## Input is sampled on the physics tick and buffered, so a press slightly
## before a move becomes available still comes out. The controller never
## reaches past the fighter's own rules: it can only request moves the
## fighter would allow.

## The fighter this controller drives.
var fighter: Fighter = null

## On-screen buttons call these.
var request_attack_light: bool = false

var request_attack_heavy: bool = false

var request_ability: bool = false

var request_dodge: bool = false

var request_block_held: bool = false

var request_forward: bool = false

var request_back: bool = false

## Which action the last on-screen button press asked for.
var last_request: String = ""


func setup(controlled: Fighter) -> void:
	fighter = controlled


## Called once per simulation frame, before the fighter simulates.
func poll() -> void:
	if fighter == null:
		return

	if request_attack_light:
		request_attack_light = false
		last_request = "light"
		fighter.buffer_input("light_attack")
	if request_attack_heavy:
		request_attack_heavy = false
		last_request = "heavy"
		fighter.buffer_input("heavy_attack")
	if request_ability:
		request_ability = false
		last_request = "ability"
		fighter.buffer_input("ability")
	if request_dodge:
		request_dodge = false
		last_request = "dodge"
		fighter.buffer_input("dodge")

	# Holding guard keeps the fighter in the blocking state.
	fighter.guard_held = request_block_held

	# Movement: forward walks towards the opponent, back retreats.
	var wants_forward := request_forward
	var wants_back := request_back
	if fighter.is_idle() or fighter.is_walking():
		if wants_forward and not wants_back:
			if not fighter.is_walking_forward():
				fighter.start_move("walk_forward")
		elif wants_back and not wants_forward:
			if not fighter.is_walking_back():
				fighter.start_move("walk_back")
		elif not wants_forward and not wants_back:
			if fighter.is_walking():
				fighter.enter_idle()
				fighter.velocity.x = 0.0


## Reads the keyboard and gamepad. The on-screen buttons feed the same
## fields, so touch and keys behave identically.
func read_input() -> void:
	if fighter == null:
		return
	if Input.is_action_just_pressed("light_attack"):
		request_attack_light = true
	if Input.is_action_just_pressed("heavy_attack"):
		request_attack_heavy = true
	if Input.is_action_just_pressed("ability"):
		request_ability = true
	if Input.is_action_just_pressed("dodge"):
		request_dodge = true
	request_block_held = Input.is_action_pressed("block")
	request_forward = Input.is_action_pressed("move_forward")
	request_back = Input.is_action_pressed("move_back")


## Clears the movement request, used when the match ends.
func release_all() -> void:
	request_forward = false
	request_back = false
	request_block_held = false
