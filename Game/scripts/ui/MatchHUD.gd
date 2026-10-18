class_name MatchHUD

extends Control
## The in-match heads-up display.
##
## Health, guard, meter, the round timer, the round pips and the combo
## counters. The health bar has a ghost: a second bar that lags behind,
## so the player can see how much a hit took.

var _player_health: ProgressBar = null

var _player_ghost: ProgressBar = null

var _player_guard: ProgressBar = null

var _player_meter: ProgressBar = null

var _enemy_health: ProgressBar = null

var _enemy_ghost: ProgressBar = null

var _enemy_guard: ProgressBar = null

var _enemy_meter: ProgressBar = null

var _timer_label: Label = null

var _round_label: Label = null

var _player_pips: HBoxContainer = null

var _enemy_pips: HBoxContainer = null

var _banner: Label = null

var _combo_label: Label = null

var _debug_label: Label = null

var _ghost_player: float = 1.0

var _ghost_enemy: float = 1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	# Top row: the two fighter bars, with the timer between them.
	var top := UIScreen.make_row(16)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)

	var player_block := VBoxContainer.new()
	player_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(player_block)

	_player_ghost = _make_bar(BloodlineTheme.DANGER.darkened(0.3), 22)
	player_block.add_child(_player_ghost)
	_player_health = _make_bar(BloodlineTheme.HEALTH, 18)
	player_block.add_child(_player_health)
	_player_guard = _make_bar(BloodlineTheme.GUARD, 6)
	player_block.add_child(_player_guard)
	_player_meter = _make_bar(BloodlineTheme.METER, 8)
	player_block.add_child(_player_meter)
	_player_pips = UIScreen.make_row(4)
	player_block.add_child(_player_pips)

	var timer_block := VBoxContainer.new()
	timer_block.custom_minimum_size = Vector2(120, 0)
	timer_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(timer_block)

	_timer_label = BloodlineTheme.title("60", 44)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_block.add_child(_timer_label)

	_round_label = BloodlineTheme.body("Round 1", 15)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_block.add_child(_round_label)

	var enemy_block := VBoxContainer.new()
	enemy_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(enemy_block)

	_enemy_ghost = _make_bar(BloodlineTheme.DANGER.darkened(0.3), 22)
	enemy_block.add_child(_enemy_ghost)
	_enemy_health = _make_bar(BloodlineTheme.HEALTH, 18)
	enemy_block.add_child(_enemy_health)
	_enemy_guard = _make_bar(BloodlineTheme.GUARD, 6)
	enemy_block.add_child(_enemy_guard)
	_enemy_meter = _make_bar(BloodlineTheme.METER, 8)
	enemy_block.add_child(_enemy_meter)
	_enemy_pips = UIScreen.make_row(4)
	enemy_block.add_child(_enemy_pips)

	# Centre banner for round announcements.
	_banner = BloodlineTheme.title("", 46)
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.modulate = Color(1, 1, 1, 0)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)

	# Bottom left: the combo and damage counters.
	_combo_label = BloodlineTheme.body("", 18)
	_combo_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_combo_label.position = Vector2(24, -70)
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_combo_label)

	_debug_label = BloodlineTheme.body("", 13)
	_debug_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_debug_label.position = Vector2(24, -44)
	_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_debug_label)


func _make_bar(color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, height)
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.04, 0.05, 0.07, 0.85)
	background.corner_radius_top_left = 2
	background.corner_radius_top_right = 2
	background.corner_radius_bottom_left = 2
	background.corner_radius_bottom_right = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## Updates the HUD from the match state.
func update_match(
	player: Fighter,
	enemy: Fighter,
	seconds: int,
	round_number: int,
	rounds_to_win: int,
	player_wins: int,
	enemy_wins: int,
	combo: int,
	damage: float,
	debug_text: String
) -> void:
	if player == null or enemy == null:
		return

	var player_max := maxf(1.0, float(player.data.get("health", 1000.0)))
	var enemy_max := maxf(1.0, float(enemy.data.get("health", 1000.0)))
	var player_ratio := clampf(player.health / player_max, 0.0, 1.0)
	var enemy_ratio := clampf(enemy.health / enemy_max, 0.0, 1.0)

	# The ghost bar trails the real bar.
	_ghost_player = lerpf(_ghost_player, player_ratio, 0.06)
	_ghost_enemy = lerpf(_ghost_enemy, enemy_ratio, 0.06)

	_player_health.value = player_ratio
	_enemy_health.value = enemy_ratio
	_player_ghost.value = _ghost_player
	_enemy_ghost.value = _ghost_enemy

	_player_guard.value = clampf(
		player.guard / maxf(1.0, float(player.data.get("guard_max", 100.0))), 0.0, 1.0
	)
	_enemy_guard.value = clampf(
		enemy.guard / maxf(1.0, float(enemy.data.get("guard_max", 100.0))), 0.0, 1.0
	)
	_player_meter.value = clampf(
		player.meter / maxf(1.0, float(player.data.get("meter_max", 100.0))), 0.0, 1.0
	)
	_enemy_meter.value = clampf(
		enemy.meter / maxf(1.0, float(enemy.data.get("meter_max", 100.0))), 0.0, 1.0
	)

	_timer_label.text = str(seconds)
	if seconds <= 10:
		_timer_label.add_theme_color_override("font_color", BloodlineTheme.DANGER)
	else:
		_timer_label.add_theme_color_override("font_color", BloodlineTheme.TEXT)

	_round_label.text = "Round %d" % round_number
	_update_pips(_player_pips, player_wins, rounds_to_win)
	_update_pips(_enemy_pips, enemy_wins, rounds_to_win)

	if combo > 1:
		_combo_label.text = "%d hit combo   ·   %d damage" % [combo, int(damage)]
		_combo_label.add_theme_color_override("font_color", BloodlineTheme.ACCENT)
	else:
		_combo_label.text = ""

	_debug_label.text = debug_text
	_debug_label.visible = not debug_text.is_empty()


func _update_pips(container: HBoxContainer, wins: int, needed: int) -> void:
	while container.get_child_count() < needed:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		pip.color = BloodlineTheme.ACCENT.darkened(0.6)
		container.add_child(pip)
	for i in range(container.get_child_count()):
		var pip := container.get_child(i) as ColorRect
		if pip == null:
			continue
		pip.color = BloodlineTheme.ACCENT if i < wins else BloodlineTheme.ACCENT.darkened(0.6)


## Shows a centred banner for a moment.
func show_banner(text: String, duration: float = 1.2) -> void:
	_banner.text = text
	_banner.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.4)
