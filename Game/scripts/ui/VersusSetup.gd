extends UIScreen
## Versus setup.
##
## The opponent, the difficulty, the arena, and the round rules. Every
## option here is real and is applied to the match that follows.

var _player_id: String = "unbound"

var _enemy_id: String = "dagan"

var _difficulty: String = "standard"

var _arena_id: String = "meridian_hall"

var _rounds: int = 2

var _seconds: int = 60

var _meter_rule: String = "gain_on_hit"

var _summary: Label = null


func _ready() -> void:
	screen_id = "versus_setup"
	screen_title = "Versus Setup"
	show_back = true
	_player_id = String(SceneRouter.context.get("player_id", "unbound"))
	_enemy_id = String(SceneRouter.context.get("enemy_id", "dagan"))
	super._ready()


func build() -> void:
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 32)
	body().add_child(columns)

	# Left: the two fighters and the options.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 16)
	columns.add_child(left)

	left.add_child(_versus_panel())
	left.add_child(_option_group("Difficulty", _difficulty_options()))
	left.add_child(_option_group("Arena", _arena_options()))
	left.add_child(_option_group("Match Rules", _rule_options()))

	# Right: a live summary of the match about to be played.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(right)

	var summary_panel := UIScreen.make_panel()
	right.add_child(summary_panel)
	var summary_column := VBoxContainer.new()
	summary_column.add_theme_constant_override("separation", 10)
	summary_panel.add_child(summary_column)

	summary_column.add_child(BloodlineTheme.heading("Match"))
	_summary = BloodlineTheme.body("", 18)
	_summary.custom_minimum_size = Vector2(320, 0)
	summary_column.add_child(_summary)

	var start := BloodlineTheme.primary("Start Match")
	start.pressed.connect(_on_start)
	right.add_child(start)

	_update_summary()


func _versus_panel() -> Control:
	var panel := UIScreen.make_panel()
	var row := UIScreen.make_row(24)
	panel.add_child(row)

	row.add_child(_fighter_block(_player_id, "You"))
	row.add_child(BloodlineTheme.title("VS", 34))
	row.add_child(_fighter_block(_enemy_id, "Opponent"))
	return panel


func _fighter_block(fighter_id: String, role: String) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.custom_minimum_size = Vector2(200, 0)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(200, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var portrait_path := String(ContentDB.get_fighter(fighter_id).get("portrait", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	column.add_child(portrait)

	var name_label := BloodlineTheme.title(ContentDB.fighter_name(fighter_id), 22)
	column.add_child(name_label)
	column.add_child(BloodlineTheme.body(role, 15))
	return column


func _option_group(title: String, entries: Array) -> Control:
	var panel := UIScreen.make_panel()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	column.add_child(BloodlineTheme.heading(title))
	var row := UIScreen.make_row(10)
	column.add_child(row)

	for entry in entries:
		var button := Button.new()
		button.text = String(entry["label"])
		button.toggle_mode = true
		button.button_pressed = bool(entry["selected"])
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(entry["on_press"])
		row.add_child(button)
	return panel


func _difficulty_options() -> Array:
	return [
		{
			"label": "Beginner",
			"selected": _difficulty == "beginner",
			"on_press": func() -> void: _set_difficulty("beginner")
		},
		{
			"label": "Standard",
			"selected": _difficulty == "standard",
			"on_press": func() -> void: _set_difficulty("standard")
		},
		{
			"label": "Advanced",
			"selected": _difficulty == "advanced",
			"on_press": func() -> void: _set_difficulty("advanced")
		},
	]


func _arena_options() -> Array:
	var entries: Array = []
	for arena_id in ContentDB.arenas_for(_player_id):
		entries.append(
			{
				"label": String(ContentDB.get_arena(arena_id).get("name", arena_id)),
				"selected": _arena_id == arena_id,
				"on_press": func() -> void: _set_arena(arena_id),
			}
		)
	return entries


func _rule_options() -> Array:
	return [
		{
			"label": "Best of 1",
			"selected": _rounds == 1,
			"on_press": func() -> void: _set_rounds(1)
		},
		{
			"label": "Best of 3",
			"selected": _rounds == 2,
			"on_press": func() -> void: _set_rounds(2)
		},
		{
			"label": "Best of 5",
			"selected": _rounds == 3,
			"on_press": func() -> void: _set_rounds(3)
		},
		{"label": "30s", "selected": _seconds == 30, "on_press": func() -> void: _set_seconds(30)},
		{"label": "60s", "selected": _seconds == 60, "on_press": func() -> void: _set_seconds(60)},
		{"label": "99s", "selected": _seconds == 99, "on_press": func() -> void: _set_seconds(99)},
		{
			"label": "Meter: gain when hit",
			"selected": _meter_rule == "gain_on_hit",
			"on_press": func() -> void: _set_meter_rule("gain_on_hit")
		},
		{
			"label": "Meter: gain always",
			"selected": _meter_rule == "gain_always",
			"on_press": func() -> void: _set_meter_rule("gain_always")
		},
	]


func _set_difficulty(value: String) -> void:
	_difficulty = value
	_rebuild()
	AudioDirector.play_sound("ui_move")


func _set_arena(value: String) -> void:
	_arena_id = value
	_rebuild()
	AudioDirector.play_sound("ui_move")


func _set_rounds(value: int) -> void:
	_rounds = value
	_rebuild()
	AudioDirector.play_sound("ui_move")


func _set_seconds(value: int) -> void:
	_seconds = value
	_rebuild()
	AudioDirector.play_sound("ui_move")


func _set_meter_rule(value: String) -> void:
	_meter_rule = value
	_rebuild()
	AudioDirector.play_sound("ui_move")


func _rebuild() -> void:
	for child in body().get_children():
		child.queue_free()
	build()
	_update_summary()


func _update_summary() -> void:
	if _summary == null:
		return
	var arena_name := String(ContentDB.get_arena(_arena_id).get("name", _arena_id))
	var meter_text := (
		"gains when you are hit" if _meter_rule == "gain_on_hit" else "gains continuously"
	)
	_summary.text = (
		(
			"%s  vs  %s\n\nDifficulty: %s\nArena: %s\n"
			+ "Rounds: best of %d\nRound length: %ds\nMeter: %s"
		)
		% [
			ContentDB.fighter_name(_player_id),
			ContentDB.fighter_name(_enemy_id),
			_difficulty.capitalize(),
			arena_name,
			_rounds,
			_seconds,
			meter_text,
		]
	)


func _on_start() -> void:
	(
		SceneRouter
		. go_to(
			"loading",
			{
				"player_id": _player_id,
				"enemy_id": _enemy_id,
				"difficulty": _difficulty,
				"arena_id": _arena_id,
				"rounds": _rounds,
				"seconds": _seconds,
			}
		)
	)


func on_back() -> void:
	SceneRouter.go_to("fighter_select", {"mode": "versus"})
