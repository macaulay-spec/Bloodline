class_name MatchManager

extends Node3D
## Runs a match: rounds, the timer, hit resolution and the camera.
##
## Both the player and the AI are `Fighter` nodes driven by this manager,
## so they obey identical health, frame data, cooldowns and hit detection.
## Difficulty changes only how good the AI's decisions are.

## Emitted when the match finishes. `winner_id` is empty for a draw.
signal match_finished(winner_id: String, rounds_won: Dictionary)

## Emitted every frame with the current timer value in seconds.
signal timer_changed(seconds: int)

## Emitted when the round timer runs out.
signal time_expired

## Emitted when a fighter's guard breaks.
signal guard_break(fighter_id: String)

## Emitted when a fighter is knocked out.
signal knockout(fighter_id: String)

enum Phase {
	INTRO,
	FIGHT,
	ROUND_END,
	MATCH_END,
}

## The player's fighter.
var player: Fighter = null

## The AI fighter.
var enemy: Fighter = null

## The arena definition id.
var arena_id: String = "meridian_hall"

## Rounds needed to win the match.
var rounds_to_win: int = 2

## Length of a round in seconds.
var round_seconds: int = 60

## Current round number, starting at 1.
var round_number: int = 1

## The current phase of the match.
var phase: int = Phase.INTRO

## Seconds left in the current round.
var time_left: float = 60.0

## Rounds won, keyed by fighter id.
var rounds_won: Dictionary = {}

## Set true once the match is over.
var finished: bool = false

## The fighter that won the last round.
var round_winner: String = ""

## True when the player is being controlled by a human.
var player_is_human: bool = true

var _frames_to_ko_freeze: int = 0

var _hitstop_frames: int = 0

var _pending_hitstop: int = 0

var _arena: Arena = null

var _camera: CameraRig = null

var _ai: AIController = null

var _round_end_frames: int = 0

var _intro_frames: int = 0

var _damage_this_round: Dictionary = {}

var _combo_count: Dictionary = {}

var _last_hit_frame: Dictionary = {}


func setup(
	player_id: String,
	enemy_id: String,
	arena: String,
	difficulty: String,
	rounds: int,
	seconds: int
) -> void:
	arena_id = arena
	rounds_to_win = rounds
	round_seconds = seconds
	time_left = float(seconds)
	rounds_won = {player_id: 0, enemy_id: 0}

	_arena = Arena.new()
	_arena.name = "Arena"
	_arena.build(arena_id)
	add_child(_arena)

	player = _make_fighter(player_id, 1)
	enemy = _make_fighter(enemy_id, -1)
	add_child(player)
	add_child(enemy)

	player.opponent = enemy
	enemy.opponent = player
	player.arena = _arena
	enemy.arena = _arena

	_ai = AIController.new()
	_ai.setup(enemy, difficulty)
	add_child(_ai)

	_camera = CameraRig.new()
	_camera.name = "CameraRig"
	_camera.setup(player, enemy)
	add_child(_camera)

	_place_fighters()
	_begin_round()


func _make_fighter(id: String, facing_side: int) -> Fighter:
	var fighter := Fighter.new()
	fighter.name = "Fighter_" + id
	fighter.setup(id, facing_side)
	return fighter


func _place_fighters() -> void:
	var half := CombatConstants.START_DISTANCE * 0.5
	player.body_position = Vector3(-half, 0.0, 0.0)
	enemy.body_position = Vector3(half, 0.0, 0.0)


func _begin_round() -> void:
	phase = Phase.INTRO
	_intro_frames = CombatConstants.ROUND_INTRO_FRAMES
	time_left = float(round_seconds)
	_damage_this_round = {player.fighter_id: 0.0, enemy.fighter_id: 0.0}
	_combo_count = {player.fighter_id: 0, enemy.fighter_id: 0}
	_last_hit_frame = {player.fighter_id: -999, enemy.fighter_id: -999}
	player.state = Fighter.State.INTRO
	enemy.state = Fighter.State.INTRO
	player.health = float(player.data.get("health", CombatConstants.HEALTH_MAX))
	enemy.health = float(enemy.data.get("health", CombatConstants.HEALTH_MAX))
	player.guard = float(player.data.get("guard_max", 100.0))
	enemy.guard = float(enemy.data.get("guard_max", 100.0))
	player.meter = 0.0
	enemy.meter = 0.0


## Advances the match by one simulation frame.
func simulate(delta: float) -> void:
	if finished:
		return

	if _hitstop_frames > 0:
		_hitstop_frames -= 1
		return

	match phase:
		Phase.INTRO:
			_intro_frames -= 1
			if _intro_frames <= 0:
				phase = Phase.FIGHT
				player.state = Fighter.State.IDLE
				enemy.state = Fighter.State.IDLE
		Phase.FIGHT:
			_simulate_fight(delta)
		Phase.ROUND_END:
			_round_end_frames -= 1
			if _round_end_frames <= 0:
				_advance_after_round()
		Phase.MATCH_END:
			pass


func _simulate_fight(delta: float) -> void:
	if _ai != null:
		_ai.think(delta)

	player.simulate(delta)
	enemy.simulate(delta)

	_resolve_hits()
	_resolve_pushboxes()
	_update_timer(delta)
	_check_round_end()


func _update_timer(delta: float) -> void:
	time_left = maxf(0.0, time_left - delta)
	timer_changed.emit(int(ceil(time_left)))
	if time_left <= 0.0:
		_end_round("")


## Checks the attack volume of each fighter against the other's hurt volume.
func _resolve_hits() -> void:
	_try_hit(player, enemy)
	_try_hit(enemy, player)


func _try_hit(attacker: Fighter, defender: Fighter) -> void:
	if attacker.state != Fighter.State.ACTIVE or attacker.move_has_hit:
		return
	if defender.state == Fighter.State.KNOCKED_OUT:
		return
	var move := attacker.current_move
	if move.is_empty():
		return
	if typeof(move.get("hitbox", null)) != TYPE_DICTIONARY:
		return

	var bounds := attacker.hit_bounds()
	var hurt := defender.hurt_bounds()
	if not bounds.intersects(hurt):
		return

	attacker.move_has_hit = true
	var blocked := defender.state == Fighter.State.BLOCKING and defender.guard_held
	var damage := defender.receive_hit(attacker, move, blocked)
	attacker.hit_landed.emit(defender, move, blocked)

	# Hit-stop: both fighters freeze for a few frames on contact.
	_hitstop_frames = int(move.get("hitstop", 3))

	# Pushback, in the direction the attacker is facing.
	var pushback := float(move.get("pushback", 0.0))
	if blocked:
		pushback = float(move.get("pushback_blocked", pushback))
	defender.apply_pushback(attacker.body_position, pushback)

	# Combo tracking for the practice screen.
	var key := defender.fighter_id
	_damage_this_round[key] = float(_damage_this_round.get(key, 0.0)) + damage
	_combo_count[key] = int(_combo_count.get(key, 0)) + 1
	_last_hit_frame[key] = Engine.get_physics_frames()

	if defender.state == Fighter.State.GUARD_BROKEN:
		guard_break.emit(defender.fighter_id)
	if defender.state == Fighter.State.KNOCKED_OUT:
		knockout.emit(defender.fighter_id)


## Keeps the two fighters from overlapping.
func _resolve_pushboxes() -> void:
	if player == null or enemy == null:
		return
	var gap := player.body_position - enemy.body_position
	gap.z = 0.0
	var distance := gap.length()
	var min_gap := (
		float(player.data.get("pushbox_radius", 0.45))
		+ float(enemy.data.get("pushbox_radius", 0.45))
	)
	if distance >= min_gap:
		return
	var push := Vector3.ZERO
	if distance < 0.0001:
		push = Vector3(0.5, 0.0, 0.0)
	else:
		push = (gap / distance) * (min_gap - distance) * 0.5
	player.body_position += push
	enemy.body_position -= push


func _check_round_end() -> void:
	if player.state == Fighter.State.KNOCKED_OUT or enemy.state == Fighter.State.KNOCKED_OUT:
		var winner := ""
		if player.state == Fighter.State.KNOCKED_OUT and enemy.state == Fighter.State.KNOCKED_OUT:
			winner = ""
		elif player.state == Fighter.State.KNOCKED_OUT:
			winner = enemy.fighter_id
		else:
			winner = player.fighter_id
		_end_round(winner)


func _end_round(winner_id: String) -> void:
	if phase != Phase.FIGHT:
		return
	phase = Phase.ROUND_END
	round_winner = winner_id
	_round_end_frames = CombatConstants.ROUND_END_FRAMES
	if winner_id != "":
		rounds_won[winner_id] = int(rounds_won.get(winner_id, 0)) + 1
	player.state = Fighter.State.VICTORY if winner_id == player.fighter_id else Fighter.State.DEFEAT
	enemy.state = Fighter.State.VICTORY if winner_id == enemy.fighter_id else Fighter.State.DEFEAT
	if winner_id == "":
		time_expired.emit()


func _advance_after_round() -> void:
	var player_wins := int(rounds_won.get(player.fighter_id, 0))
	var enemy_wins := int(rounds_won.get(enemy.fighter_id, 0))
	if player_wins >= rounds_to_win or enemy_wins >= rounds_to_win:
		phase = Phase.MATCH_END
		finished = true
		var winner := ""
		if player_wins > enemy_wins:
			winner = player.fighter_id
		elif enemy_wins > player_wins:
			winner = enemy.fighter_id
		match_finished.emit(winner, rounds_won.duplicate())
		return
	round_number += 1
	_place_fighters()
	_begin_round()


## Damage dealt to `fighter_id` in the current round.
func damage_taken(fighter_id: String) -> float:
	return float(_damage_this_round.get(fighter_id, 0.0))


## Current combo count against `fighter_id`.
func combo_count(fighter_id: String) -> int:
	return int(_combo_count.get(fighter_id, 0))


## A short description of the AI's current decision, for the debug overlay.
func ai_debug() -> String:
	if _ai == null:
		return ""
	return _ai.debug_line()
