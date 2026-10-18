class_name Fighter

extends Node3D
## A single combatant: the player or the AI.
##
## The fighter owns its own state machine and runs on the fixed simulation
## tick, so frame data means the same thing for both the player and the AI.
## Health, cooldowns, hit detection and meter are all identical between
## the two; only the decision-making differs.

## Emitted when this fighter lands a hit on `target`.
signal hit_landed(target: Fighter, move: Dictionary, blocked: bool)

## Emitted when this fighter takes a hit.
signal hit_taken(source: Fighter, move: Dictionary, blocked: bool, damage: float)

## Emitted when the fighter's guard breaks.
signal guard_broken

## Emitted when the fighter is knocked out.
signal knocked_out

## Emitted when the fighter's meter changes.
signal meter_changed(value: float, maximum: float)

enum State {
	IDLE,
	WALK_FORWARD,
	WALK_BACK,
	STARTUP,
	ACTIVE,
	RECOVERY,
	BLOCKING,
	HITSTUN,
	BLOCKSTUN,
	GUARD_BREKEN,
	KNOCKDOWN,
	KNOCKED_OUT,
	INTRO,
	VICTORY,
	DEFEAT,
}

## The fighter's data id.
var fighter_id: String = ""

## The fighter's data block.
var data: Dictionary = {}

## True when this fighter is driven by the AI.
var is_ai: bool = false

## Which side of the screen the fighter starts on.
var facing: int = 1

## Current health.
var health: float = 1000.0

## Current guard meter.
var guard: float = 100.0

## Current Veil meter.
var meter: float = 0.0

## The current state.
var state: int = State.IDLE

## The move currently being executed, as a data dictionary.
var current_move: Dictionary = {}

## The id of the move currently being executed.
var current_move_id: String = ""

## Frames elapsed inside the current move.
var move_frame: int = 0

## Frames remaining in the current state.
var state_frames: int = 0

## True while the fighter is guarding.
var guard_held: bool = false

## True while the fighter is invulnerable.
var invulnerable: bool = false

## True once the current move has connected this frame.
var move_has_hit: bool = false

## True when the current move may be cancelled into another.
var can_cancel: bool = false

## Frames until this fighter may act again.
var action_cooldown: int = 0

## Cooldowns per move id, in frames.
var cooldowns: Dictionary = {}

## Queued inputs, so a press slightly early still comes out.
var buffered_input: String = ""

var buffered_input_frames: int = 0

## The opponent this fighter is fighting.
var opponent: Fighter = null

## The arena this fighter is standing in.
var arena: Arena = null

## The visual rig.
var model: Node3D = null

## Body position on the arena plane.
var body_position: Vector3 = Vector3.ZERO

## Velocity along the arena plane.
var velocity: Vector3 = Vector3.ZERO

## Debug: the action the AI decided on this frame.
var ai_thought: String = ""

var _anim_player: AnimationPlayer = null

var _anim_tree: AnimationTree = null

var _current_anim: String = ""

var _hurtbox: Area3D = null

var _hitbox: Area3D = null

var _hitbox_mesh: MeshInstance3D = null

var _facing_smoothed: float = 1.0


func setup(id: String, facing_side: int) -> void:
	fighter_id = id
	facing = facing_side
	data = ContentDB.get_fighter(id)
	if data.is_empty():
		push_error("Fighter: unknown fighter id %s" % id)
		return

	health = float(data.get("health", CombatConstants.HEALTH_MAX))
	guard = float(data.get("guard_max", 100.0))
	meter = 0.0
	cooldowns.clear()

	_build_model()
	_build_boxes()


func _build_model() -> void:
	var model_path := String(data.get("model", ""))
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		push_error("Fighter: missing model for %s (%s)" % [fighter_id, model_path])
		return
	var packed: PackedScene = load(model_path)
	if packed == null:
		push_error("Fighter: could not load model %s" % model_path)
		return
	model = packed.instantiate()
	add_child(model)
	_anim_player = _find_animation_player(model)
	if _anim_player != null:
		_anim_player.play("idle")
		_current_anim = "idle"
		# Loop every clip; the state machine decides when to switch.
		for clip_name in _anim_player.get_animation_list():
			var anim := _anim_player.get_animation(clip_name)
			if anim != null and not anim.loop_mode == Animation.LOOP_LINEAR:
				anim.loop_mode = Animation.LOOP_LINEAR


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _build_boxes() -> void:
	_hurtbox = Area3D.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.monitoring = false
	_hurtbox.monitorable = false
	add_child(_hurtbox)

	var hurt_data: Dictionary = data.get("hurtbox", {})
	var hurt_size := Vector3(
		float(hurt_data.get("size", [0.75, 0.65, 1.75])[0]),
		float(hurt_data.get("size", [0.75, 0.65, 1.75])[1]),
		float(hurt_data.get("size", [0.75, 0.65, 1.75])[2])
	)
	var hurt_offset := Vector3(
		float(hurt_data.get("offset", [0.0, 0.0, 0.9])[0]),
		float(hurt_data.get("offset", [0.0, 0.0, 0.9])[1]),
		float(hurt_data.get("offset", [0.0, 0.0, 0.9])[2])
	)
	var hurt_shape := CollisionShape3D.new()
	var hurt_box := BoxShape3D.new()
	hurt_box.size = hurt_size
	hurt_shape.shape = hurt_box
	hurt_shape.position = hurt_offset
	_hurtbox.add_child(hurt_shape)

	_hitbox = Area3D.new()
	_hitbox.name = "Hitbox"
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	add_child(_hitbox)

	var hit_shape := CollisionShape3D.new()
	var hit_box := BoxShape3D.new()
	hit_box.size = Vector3(0.6, 0.6, 0.6)
	hit_shape.shape = hit_box
	_hitbox.add_child(hit_shape)

	_hitbox_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.6, 0.6)
	_hitbox_mesh.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.35, 0.3, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	_hitbox_mesh.material_override = mat
	_hitbox_mesh.visible = false
	_hitbox.add_child(_hitbox_mesh)


## The world-space hurt volume of this fighter.
func hurt_bounds() -> AABB:
	var hurt_data: Dictionary = data.get("hurtbox", {})
	var size_array: Array = hurt_data.get("size", [0.75, 0.65, 1.75])
	var offset_array: Array = hurt_data.get("offset", [0.0, 0.0, 0.9])
	var center := (
		body_position
		+ Vector3(float(offset_array[0]) * facing, float(offset_array[1]), float(offset_array[2]))
	)
	var size := Vector3(float(size_array[0]), float(size_array[1]), float(size_array[2]))
	return AABB(center - size * 0.5, size)


## The world-space attack volume of the move currently active.
func hit_bounds() -> AABB:
	var hitbox: Variant = current_move.get("hitbox", null)
	if typeof(hitbox) != TYPE_DICTIONARY:
		return AABB()
	var hb: Dictionary = hitbox
	var size_array: Array = hb.get("size", [0.6, 0.6, 0.6])
	var offset_array: Array = hb.get("offset", [0.0, 0.0, 0.9])
	var center := (
		body_position
		+ Vector3(float(offset_array[0]) * facing, float(offset_array[1]), float(offset_array[2]))
	)
	var size := Vector3(float(size_array[0]), float(size_array[1]), float(size_array[2]))
	return AABB(center - size * 0.5, size)


## Starts a move by id. Returns false if the move cannot be started.
func start_move(move_id: String) -> bool:
	var move := ContentDB.get_move_for(fighter_id, move_id)
	if move.is_empty():
		return false
	if not can_start_move(move_id):
		return false

	current_move = move
	current_move_id = move_id
	move_frame = 0
	move_has_hit = false
	can_cancel = false

	match String(move.get("kind", "normal")):
		"movement":
			state = State.WALK_FORWARD if move_id == "walk_forward" else State.WALK_BACK
			_play_animation(String(move.get("animation", "idle")))
		"defense":
			state = State.BLOCKING
			_play_animation(String(move.get("animation", "guard")))
		_:
			state = State.STARTUP
			_play_animation(String(move.get("animation", "idle")))
	return true


## Whether the fighter is allowed to start the given move right now.
func can_start_move(move_id: String) -> bool:
	if (
		state
		in [
			State.STARTUP,
			State.ACTIVE,
			State.RECOVERY,
			State.HITSTUN,
			State.BLOCKSTUN,
			State.GUARD_BROKEN,
			State.KNOCKDOWN,
			State.KNOCKED_OUT,
			State.INTRO,
			State.VICTORY,
			State.DEFEAT
		]
	):
		return false
	var remaining: int = int(cooldowns.get(move_id, 0))
	if remaining > 0:
		return false
	var move := ContentDB.get_move_for(fighter_id, move_id)
	if move.is_empty():
		return false
	var cost := float(move.get("meter_cost", 0))
	if cost > meter:
		return false
	return true


## Queues an input so a press just before the fighter is free still lands.
func buffer_input(action: String) -> void:
	buffered_input = action
	buffered_input_frames = CombatConstants.INPUT_BUFFER_FRAMES


## Consumes the buffered input, if it is still fresh.
func take_buffered_input() -> String:
	if buffered_input.is_empty() or buffered_input_frames <= 0:
		buffered_input = ""
		return ""
	var action := buffered_input
	buffered_input = ""
	buffered_input_frames = 0
	return action


## Advances the fighter by one simulation frame.
func simulate(delta: float) -> void:
	if data.is_empty():
		return

	_tick_timers()
	_tick_meter(delta)
	_tick_state(delta)
	_update_transform(delta)


func _tick_timers() -> void:
	if action_cooldown > 0:
		action_cooldown -= 1
	for key in cooldowns.keys():
		var remaining: int = int(cooldowns[key]) - 1
		if remaining <= 0:
			cooldowns.erase(key)
		else:
			cooldowns[key] = remaining
	if buffered_input_frames > 0:
		buffered_input_frames -= 1
		if buffered_input_frames <= 0:
			buffered_input = ""


func _tick_meter(delta: float) -> void:
	var max_meter := float(data.get("meter_max", 100.0))
	meter = clampf(meter + float(data.get("meter_gain_per_second", 0.0)) * delta, 0.0, max_meter)
	meter_changed.emit(meter, max_meter)


func _tick_state(delta: float) -> void:
	match state:
		State.IDLE:
			_advance_from_idle()
		State.WALK_FORWARD, State.WALK_BACK:
			_tick_walk(delta)
		State.STARTUP:
			_tick_startup()
		State.ACTIVE:
			_tick_active(delta)
		State.RECOVERY:
			_tick_recovery()
		State.BLOCKING:
			_tick_blocking(delta)
		State.HITSTUN:
			state_frames -= 1
			if state_frames <= 0:
				_set_idle()
		State.BLOCKSTUN:
			state_frames -= 1
			if state_frames <= 0:
				_set_idle()
		State.GUARD_BROKEN:
			state_frames -= 1
			if state_frames <= 0:
				_set_idle()
		State.KNOCKDOWN:
			state_frames -= 1
			if state_frames <= 0:
				_set_idle()
		State.KNOCKED_OUT, State.VICTORY, State.DEFEAT, State.INTRO:
			pass


func _advance_from_idle() -> void:
	var action := take_buffered_input()
	if action.is_empty():
		return
	if action == "forward" and start_move("walk_forward"):
		return
	if action == "back" and start_move("walk_back"):
		return
	if action == "block":
		guard_held = true
		state = State.BLOCKING
		_play_animation("guard")
		return
	if start_move(action):
		return
	# The move was not available; keep the input alive for a few more frames.
	buffered_input = action
	buffered_input_frames = CombatConstants.INPUT_BUFFER_FRAMES


func _tick_walk(_delta: float) -> void:
	var speed := float(current_move.get("speed", 2.5))
	velocity.x = speed * facing
	# Walking can be interrupted by a new input.
	if not guard_held and _has_buffered_action():
		var action := take_buffered_input()
		if action == "forward" or action == "back":
			if start_move("walk_forward" if action == "forward" else "walk_back"):
				return
		elif action == "block":
			guard_held = true
			state = State.BLOCKING
			_play_animation("guard")
			return
		elif start_move(action):
			return
		buffered_input = action
		buffered_input_frames = CombatConstants.INPUT_BUFFER_FRAMES


func _has_buffered_action() -> bool:
	return not buffered_input.is_empty() and buffered_input_frames > 0


func _tick_startup() -> void:
	move_frame += 1
	var startup := int(current_move.get("startup", 6))
	if move_frame >= startup:
		move_frame = 0
		state = State.ACTIVE
		_begin_active_window()


func _begin_active_window() -> void:
	move_has_hit = false
	var active := int(current_move.get("active", 3))
	state_frames = active
	invulnerable = _frames_in_range(move_frame, current_move.get("invulnerable_frames", []))
	_update_hitbox_visual()


func _tick_active(_delta: float) -> void:
	move_frame += 1
	state_frames -= 1
	invulnerable = _frames_in_range(move_frame, current_move.get("invulnerable_frames", []))
	_update_hitbox_visual()
	if state_frames <= 0:
		state = State.RECOVERY
		state_frames = int(current_move.get("recovery", 12))
		invulnerable = false
		_update_hitbox_visual()


func _tick_recovery() -> void:
	move_frame += 1
	state_frames -= 1
	var window: Array = current_move.get("cancel_window", [])
	can_cancel = (
		not window.is_empty() and move_frame >= int(window[0]) and move_frame <= int(window[1])
	)
	if state_frames <= 0:
		_finish_move()


func _tick_blocking(delta: float) -> void:
	var max_guard := float(data.get("guard_max", 100.0))
	var recharge := float(data.get("guard_recharge_per_second", 12.0))
	guard = minf(max_guard, guard + recharge * delta)
	if not guard_held:
		state = State.IDLE
		_play_animation("idle")
		return
	# A blocked attack is resolved by the match; the fighter stays up.
	if _has_buffered_action() and take_buffered_input() != "":
		pass


func _finish_move() -> void:
	var cost := float(current_move.get("meter_cost", 0))
	if cost > 0.0:
		meter = maxf(0.0, meter - cost)
	var cooldown := int(current_move.get("cooldown", 0))
	if cooldown > 0:
		cooldowns[current_move_id] = cooldown
	current_move = {}
	current_move_id = ""
	can_cancel = false
	invulnerable = false
	_update_hitbox_visual()
	_set_idle()


func _set_idle() -> void:
	state = State.IDLE
	current_move = {}
	current_move_id = ""
	move_frame = 0
	can_cancel = false
	invulnerable = false
	_update_hitbox_visual()
	_play_animation("idle")


## Applies a hit from `source` using `move`. Returns the damage dealt.
func receive_hit(source: Fighter, move: Dictionary, blocked: bool) -> float:
	if state == State.KNOCKED_OUT or state == State.VICTORY or state == State.DEFEAT:
		return 0.0
	if invulnerable:
		return 0.0

	var damage := float(move.get("damage", 0.0))
	if blocked:
		damage = float(move.get("chip_damage", 0.0))
		guard = maxf(0.0, guard - float(move.get("guard_damage", 0.0)))
		state = State.BLOCKSTUN
		state_frames = int(move.get("blockstun", 9))
		_play_animation("block")
		if guard <= 0.0:
			_break_guard()
	else:
		health = maxf(0.0, health - damage)
		state = State.HITSTUN
		state_frames = int(move.get("hitstun", 16))
		_play_animation("hit")
		# Meter fills from taking damage, so being hit is a resource.
		meter = minf(
			float(data.get("meter_max", 100.0)), meter + float(move.get("meter_gain_on_hit", 6.0))
		)
		if health <= 0.0:
			_knock_out()

	hit_taken.emit(source, move, blocked, damage)
	return damage


func _break_guard() -> void:
	state = State.GUARD_BROKEN
	state_frames = CombatConstants.GUARD_BREAK_FRAMES
	guard = CombatConstants.GUARD_BREAK_PENALTY
	_play_animation("hit")
	guard_broken.emit()


func _knock_out() -> void:
	state = State.KNOCKED_OUT
	health = 0.0
	_play_animation("knockdown")
	knocked_out.emit()


## Pushes this fighter away from `from` by `amount` units.
func apply_pushback(from: Vector3, amount: float) -> void:
	if amount <= 0.0:
		return
	var away := body_position - from
	away.y = 0.0
	if away.length() < 0.001:
		away = Vector3(float(facing), 0.0, 0.0)
	away = away.normalized()
	body_position += away * amount
	_clamp_to_arena()


func _clamp_to_arena() -> void:
	body_position.x = clampf(
		body_position.x, -CombatConstants.ARENA_HALF_WIDTH, CombatConstants.ARENA_HALF_WIDTH
	)
	body_position.z = 0.0


## Moves the fighter towards the opponent, respecting pushboxes.
func move_towards(target: Vector3, speed: float, delta: float) -> void:
	var to_target := target - body_position
	to_target.z = 0.0
	var distance := to_target.length()
	if distance < 0.0001:
		return
	var step := speed * delta
	if distance - step < _pushbody_distance():
		step = maxf(0.0, distance - _pushbody_distance())
	body_position += (to_target / distance) * step
	_clamp_to_arena()


## The gap that must remain between the two fighters.
func _pushbody_distance() -> float:
	if opponent == null:
		return 0.0
	return (
		float(data.get("pushbox_radius", 0.45))
		+ float(opponent.data.get("pushbox_radius", 0.45))
		+ CombatConstants.PUSHBODY_MARGIN
	)


func _update_transform(delta: float) -> void:
	# Always face the opponent, with a short smoothing so side switches read.
	if opponent != null:
		var to_opponent := opponent.body_position - body_position
		if absf(to_opponent.x) > 0.01:
			facing = 1 if to_opponent.x > 0.0 else -1
	_facing_smoothed = lerpf(_facing_smoothed, float(facing), clampf(delta * 12.0, 0.0, 1.0))
	body_position += velocity * delta
	_clamp_to_arena()
	position = body_position
	rotation.y = 0.0 if _facing_smoothed >= 0.0 else PI


func _play_animation(clip: String) -> void:
	if _anim_player == null or clip.is_empty():
		return
	if clip == _current_anim:
		return
	if not _anim_player.has_animation(clip):
		return
	_anim_player.play(clip)
	_current_anim = clip


func _frames_in_range(frame: int, range_array: Variant) -> bool:
	if typeof(range_array) != TYPE_ARRAY:
		return false
	var arr: Array = range_array
	if arr.size() < 2:
		return false
	return frame >= int(arr[0]) and frame <= int(arr[1])


func _update_hitbox_visual() -> void:
	if _hitbox_mesh == null:
		return
	var active := state == State.ACTIVE
	_hitbox_mesh.visible = active
	if not active:
		return
	var bounds := hit_bounds()
	var size := bounds.size
	_hitbox_mesh.mesh = _make_quad(size.x, size.z)
	var center := bounds.get_center()
	_hitbox_mesh.position = center - body_position
	_hitbox_mesh.rotation = Vector3(0.0, 0.0, 0.0)


func _make_quad(width: float, height: float) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(maxf(width, 0.05), maxf(height, 0.05))
	return quad


## Debug helper: a one-line description of what the fighter is doing.
func debug_state() -> String:
	return (
		"%s: state=%d move=%s frame=%d hp=%.0f meter=%.0f"
		% [fighter_id, state, current_move_id, move_frame, health, meter]
	)

## --- The state, as the rest of the game sees it -----------------------------
##
## Other scripts never read the enum directly: they ask the fighter, so the
## state machine stays in one place.


## True while the fighter is standing still.
func is_idle() -> bool:
	return state == State.IDLE


## True while the fighter is walking in either direction.
func is_walking() -> bool:
	return state == State.WALK_FORWARD or state == State.WALK_BACK


## True while the fighter walks towards the opponent.
func is_walking_forward() -> bool:
	return state == State.WALK_FORWARD


## True while the fighter walks away from the opponent.
func is_walking_back() -> bool:
	return state == State.WALK_BACK


## True while the fighter winds up an attack.
func is_startup() -> bool:
	return state == State.STARTUP


## True while the attack of the fighter is live.
func is_active() -> bool:
	return state == State.ACTIVE


## True while the fighter recovers from an attack.
func is_recovery() -> bool:
	return state == State.RECOVERY


## True while the fighter holds the guard.
func is_blocking() -> bool:
	return state == State.BLOCKING


## True while the guard of the fighter is broken.
func is_guard_broken() -> bool:
	return state == State.GUARD_BROKEN


## True while the fighter is on the floor.
func is_knocked_down() -> bool:
	return state == State.KNOCKDOWN


## True while the fighter is out of the round.
func is_knocked_out() -> bool:
	return state == State.KNOCKED_OUT


## True while the round intro is still playing.
func is_intro() -> bool:
	return state == State.INTRO


## True once the match is over for the fighter.
func is_finished() -> bool:
	return state == State.VICTORY or state == State.DEFEAT


## True when the fighter won the match.
func is_victory() -> bool:
	return state == State.VICTORY


## True when the fighter lost the match.
func is_defeat() -> bool:
	return state == State.DEFEAT


## Puts the fighter into the round intro.
func enter_intro() -> void:
	state = State.INTRO


## Puts the fighter back to a neutral stance.
func enter_idle() -> void:
	state = State.IDLE


## Ends the match for the fighter.
func enter_result(won: bool) -> void:
	state = State.VICTORY if won else State.DEFEAT

