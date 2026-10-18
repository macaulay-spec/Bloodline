extends UIScreen
## The practice screen.
##
## A training dummy with selectable behaviour, live combo and damage
## counters, and the fighter's move list with its frame data. A reset
## button puts everything back to the start.

var _dummy_behaviour: String = "stand"

var _player_id: String = "unbound"

var _match: MatchManager = null

var _player_controller: PlayerController = null

var _hud: MatchHUD = null

var _counters: Label = null

var _move_list: VBoxContainer = null

var _world: Node3D = null

var _finished: bool = false


func _ready() -> void:
	screen_id = "practice"
	screen_title = "Practice"
	show_back = true
	_player_id = String(SceneRouter.context.get("player_id", "unbound"))
	super._ready()


func build() -> void:
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	body().add_child(columns)

	# Left: the dummy behaviour and the counters.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)

	left.add_child(BloodlineTheme.heading("Dummy"))
	var behaviour_row := UIScreen.make_row(8)
	left.add_child(behaviour_row)
	for entry in [
		{"label": "Stand", "id": "stand"},
		{"label": "Block", "id": "block"},
		{"label": "Approach", "id": "approach"},
		{"label": "Retreat", "id": "retreat"},
	]:
		var button := Button.new()
		button.text = String(entry["label"])
		button.toggle_mode = true
		button.button_pressed = _dummy_behaviour == String(entry["id"])
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(_on_behaviour.bind(String(entry["id"])))
		behaviour_row.add_child(button)

	left.add_child(BloodlineTheme.heading("Counters"))
	_counters = BloodlineTheme.body("", 17)
	left.add_child(_counters)

	var reset := BloodlineTheme.secondary("Reset")
	reset.pressed.connect(_on_reset)
	left.add_child(reset)

	# Right: the move list with frame data.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	columns.add_child(right)

	right.add_child(BloodlineTheme.heading("Move List"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)

	_move_list = VBoxContainer.new()
	_move_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_move_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_move_list)

	_populate_move_list()
	_start_dummy()


func _populate_move_list() -> void:
	for child in _move_list.get_children():
		child.queue_free()
	var fighter := ContentDB.get_fighter(_player_id)
	for move_id in fighter.get("moves", []):
		var move := ContentDB.get_move_for(_player_id, String(move_id))
		if move.is_empty():
			continue
		var line := BloodlineTheme.body(
			(
				"%-16s  startup %2d   active %2d   recovery %2d   damage %3d   meter %2d"
				% [
					String(move.get("name", move_id)),
					int(move.get("startup", 0)),
					int(move.get("active", 0)),
					int(move.get("recovery", 0)),
					int(move.get("damage", 0)),
					int(move.get("meter_cost", 0))
				]
			),
			15
		)
		_move_list.add_child(line)


func _start_dummy() -> void:
	_finished = false
	_world = Node3D.new()
	_world.name = "PracticeWorld"
	add_child(_world)

	_match = MatchManager.new()
	_match.name = "PracticeMatch"
	# The dummy never fights back, so the practice match has no opponent
	# scoring; the player is free to experiment.
	_match.setup(_player_id, _player_id, "meridian_hall", "standard", 99, 9999)
	_world.add_child(_match)

	_player_controller = PlayerController.new()
	_player_controller.setup(_match.player)
	_world.add_child(_player_controller)

	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = MatchHUD.new()
	layer.add_child(_hud)

	var controls := TouchControls.new()
	layer.add_child(controls)
	controls.light_pressed.connect(func() -> void: _player_controller.request_attack_light = true)
	controls.heavy_pressed.connect(func() -> void: _player_controller.request_attack_heavy = true)
	controls.ability_pressed.connect(func() -> void: _player_controller.request_ability = true)
	controls.dodge_pressed.connect(func() -> void: _player_controller.request_dodge = true)
	controls.guard_changed.connect(
		func(down: bool) -> void: _player_controller.request_block_held = down
	)
	controls.move_changed.connect(
		func(direction: int) -> void:
			_player_controller.request_forward = direction > 0
			_player_controller.request_back = direction < 0
	)


func _on_behaviour(behaviour: String) -> void:
	_dummy_behaviour = behaviour
	AudioDirector.play_sound("ui_move")
	# Rebuild so the toggle states update.
	for child in body().get_children():
		child.queue_free()
	build()


func _on_reset() -> void:
	if _world != null:
		_world.queue_free()
		_world = null
	_start_dummy()
	AudioDirector.play_sound("ui_select")


func _physics_process(delta: float) -> void:
	if _match == null or _finished:
		return
	_player_controller.read_input()
	_player_controller.poll()
	_match.simulate(delta)
	_apply_dummy_behaviour()

	if _hud != null and _match.player != null:
		_hud.update_match(_match.player, _match.player, 0, 1, 1, 0, 0, 0, 0.0, "")
	if _counters != null:
		_counters.text = (
			"Damage dealt: %d\nCombo: %d\nMeter: %d / %d\nHealth: %d"
			% [
				int(_match.damage_taken(_match.player.fighter_id)),
				_match.combo_count(_match.player.fighter_id),
				int(_match.player.meter),
				int(_match.player.data.get("meter_max", 100)),
				int(_match.player.health),
			]
		)


## The dummy's behaviour. It never attacks: it only moves and guards.
func _apply_dummy_behaviour() -> void:
	if _match == null or _match.enemy == null:
		return
	var dummy := _match.enemy
	match _dummy_behaviour:
		"block":
			dummy.guard_held = true
		"approach":
			dummy.guard_held = false
			dummy.move_towards(_match.player.body_position, 1.6, 1.0 / 60.0)
		"retreat":
			dummy.guard_held = false
			var away := dummy.body_position - _match.player.body_position
			away.z = 0.0
			if away.length() > 0.01:
				dummy.move_towards(dummy.body_position + away.normalized() * 4.0, 1.4, 1.0 / 60.0)
		_:
			dummy.guard_held = false


func on_back() -> void:
	_finished = true
	if _world != null:
		_world.queue_free()
		_world = null
	SceneRouter.go_to("main_menu")
