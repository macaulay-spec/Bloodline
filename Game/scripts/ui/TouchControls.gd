extends Control
## The on-screen controls.
##
## Six buttons: light, heavy, ability, dodge, guard, and a movement pad.
## The buttons drive the same `PlayerController` fields the keyboard does,
## so touch and keys behave identically.

signal light_pressed

signal heavy_pressed

signal ability_pressed

signal dodge_pressed

signal guard_changed(down: bool)

signal move_changed(direction: int)

var _move_direction: int = 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	# Right side: the action buttons.
	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right.position = Vector2(-300, -260)
	right.custom_minimum_size = Vector2(280, 240)
	right.add_theme_constant_override("separation", 10)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)

	var top_row := UIScreen.make_row(10)
	top_row.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(top_row)

	top_row.add_child(
		_make_button("Guard", BloodlineTheme.GUARD, Vector2(130, 62), _on_guard_down, _on_guard_up)
	)
	top_row.add_child(_make_button("Dodge", BloodlineTheme.ACCENT, Vector2(130, 62), _on_dodge))

	var bottom_row := UIScreen.make_row(10)
	bottom_row.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(bottom_row)

	bottom_row.add_child(
		_make_button("Ability", BloodlineTheme.ACCENT.darkened(0.1), Vector2(130, 78), _on_ability)
	)
	bottom_row.add_child(_make_button("Heavy", BloodlineTheme.DANGER, Vector2(130, 78), _on_heavy))
	bottom_row.add_child(_make_button("Light", BloodlineTheme.TEXT, Vector2(130, 78), _on_light))

	# Left side: the movement pad.
	var left := VBoxContainer.new()
	left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left.position = Vector2(24, -160)
	left.custom_minimum_size = Vector2(200, 140)
	left.add_theme_constant_override("separation", 10)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left)

	var back_button := _make_button(
		"◀ Back", BloodlineTheme.TEXT_DIM, Vector2(92, 60), func() -> void: _on_move(-1)
	)
	left.add_child(back_button)

	var forward_button := _make_button(
		"Forward ▶", BloodlineTheme.TEXT_DIM, Vector2(92, 60), func() -> void: _on_move(1)
	)
	left.add_child(forward_button)


func _make_button(
	text: String, color: Color, size: Vector2, on_press: Callable, on_release: Callable = Callable()
) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", color)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_press)
	if on_release.is_valid():
		button.button_up.connect(on_release)
	return button


func _on_light() -> void:
	light_pressed.emit()


func _on_heavy() -> void:
	heavy_pressed.emit()


func _on_ability() -> void:
	ability_pressed.emit()


func _on_dodge() -> void:
	dodge_pressed.emit()


func _on_guard_down() -> void:
	guard_changed.emit(true)


func _on_guard_up() -> void:
	guard_changed.emit(false)


func _on_move(direction: int) -> void:
	_move_direction = direction
	move_changed.emit(direction)
