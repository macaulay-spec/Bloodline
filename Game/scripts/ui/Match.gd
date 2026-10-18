extends Node3D
## The match screen.
##
## Owns the match manager, the camera, the HUD and the on-screen controls,
## and drives the fixed-step simulation.

var match_manager: MatchManager = null

var _hud: MatchHUD = null

var _controls: TouchControls = null

var _player_controller: PlayerController = null

var _practise: bool = false

var _pause_menu: Control = null

var _show_debug: bool = false

var _finished: bool = false


func _ready() -> void:
	_practise = SceneRouter.context.get("mode", "") == "practice"
	_build_world()
	_build_ui()
	_start_match()


func _build_world() -> void:
	match_manager = MatchManager.new()
	match_manager.name = "MatchManager"
	var player_id := String(SceneRouter.context.get("player_id", "unbound"))
	var enemy_id := String(SceneRouter.context.get("enemy_id", "dagan"))
	match_manager.setup(
		player_id,
		enemy_id,
		String(SceneRouter.context.get("arena_id", "meridian_hall")),
		String(SceneRouter.context.get("difficulty", "standard")),
		int(SceneRouter.context.get("rounds", 2)),
		int(SceneRouter.context.get("seconds", 60))
	)
	add_child(match_manager)

	match_manager.match_finished.connect(_on_match_finished)
	match_manager.guard_break.connect(_on_guard_break)
	match_manager.knockout.connect(_on_knockout)

	_player_controller = PlayerController.new()
	_player_controller.setup(match_manager.player)
	add_child(_player_controller)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)

	_hud = MatchHUD.new()
	_hud.name = "HUD"
	layer.add_child(_hud)

	_controls = TouchControls.new()
	_controls.name = "Controls"
	layer.add_child(_controls)
	_controls.light_pressed.connect(func() -> void: _player_controller.request_attack_light = true)
	_controls.heavy_pressed.connect(func() -> void: _player_controller.request_attack_heavy = true)
	_controls.ability_pressed.connect(func() -> void: _player_controller.request_ability = true)
	_controls.dodge_pressed.connect(func() -> void: _player_controller.request_dodge = true)
	_controls.guard_changed.connect(
		func(down: bool) -> void: _player_controller.request_block_held = down
	)
	_controls.move_changed.connect(_on_move_changed)

	_build_pause_menu(layer)


func _build_pause_menu(layer: CanvasLayer) -> void:
	_pause_menu = Control.new()
	_pause_menu.name = "PauseMenu"
	_pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.visible = false
	layer.add_child(_pause_menu)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.add_child(center)

	var panel := UIScreen.make_panel()
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	column.add_child(BloodlineTheme.heading("Paused"))

	var resume := BloodlineTheme.primary("Resume")
	resume.pressed.connect(func() -> void: _pause_menu.visible = false)
	column.add_child(resume)

	var debug_button := BloodlineTheme.secondary("Toggle Frame Data")
	debug_button.pressed.connect(func() -> void: _show_debug = not _show_debug)
	column.add_child(debug_button)

	var quit := BloodlineTheme.secondary("Quit Match")
	quit.pressed.connect(func() -> void: SceneRouter.go_to("main_menu"))
	column.add_child(quit)


func _start_match() -> void:
	if _hud != null:
		_hud.show_banner("Round 1", 1.0)


func _on_move_changed(direction: int) -> void:
	_player_controller.request_forward = direction > 0
	_player_controller.request_back = direction < 0


func _physics_process(delta: float) -> void:
	if match_manager == null or _finished:
		return
	_player_controller.read_input()
	_player_controller.poll()
	match_manager.simulate(delta)
	_update_hud()


func _update_hud() -> void:
	if _hud == null or match_manager.player == null or match_manager.enemy == null:
		return
	var combo := match_manager.combo_count(match_manager.enemy.fighter_id)
	var damage := match_manager.damage_taken(match_manager.enemy.fighter_id)
	var debug_text := ""
	if _show_debug:
		debug_text = "%s\n%s" % [match_manager.player.debug_state(), match_manager.ai_debug()]
	_hud.update_match(
		match_manager.player,
		match_manager.enemy,
		int(ceil(match_manager.time_left)),
		match_manager.round_number,
		match_manager.rounds_to_win,
		int(match_manager.rounds_won.get(match_manager.player.fighter_id, 0)),
		int(match_manager.rounds_won.get(match_manager.enemy.fighter_id, 0)),
		combo,
		damage,
		debug_text
	)


func _on_guard_break(_fighter_id: String) -> void:
	AudioDirector.play_sound("guard_break")
	AudioDirector.haptic(0.6, 120)
	if _hud != null:
		_hud.show_banner("GUARD BREAK", 0.9)


func _on_knockout(_fighter_id: String) -> void:
	AudioDirector.play_sound("ko")
	AudioDirector.haptic(0.8, 180)
	if _hud != null:
		_hud.show_banner("K.O.", 1.4)


func _on_match_finished(winner_id: String, rounds: Dictionary) -> void:
	if _finished:
		return
	_finished = true
	_player_controller.release_all()
	if _practise:
		# The practice screen stays open so the player can keep training.
		return
	(
		SceneRouter
		. go_to(
			"results",
			{
				"winner_id": winner_id,
				"player_id": match_manager.player.fighter_id,
				"enemy_id": match_manager.enemy.fighter_id,
				"rounds": rounds,
				"difficulty": String(SceneRouter.context.get("difficulty", "standard")),
				"arena_id": match_manager.arena_id,
			}
		)
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _pause_menu != null:
			_pause_menu.visible = not _pause_menu.visible
		get_viewport().set_input_as_handled()
