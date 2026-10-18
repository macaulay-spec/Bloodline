extends UIScreen
## The settings screen.
##
## Audio, haptics, graphics quality, control layout, language, and a
## reset of the save file. Every control here does something real.

var _status: Label = null


func _ready() -> void:
	screen_id = "settings"
	screen_title = "Settings"
	show_back = true
	super._ready()


func build() -> void:
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 28)
	body().add_child(columns)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	columns.add_child(left)

	left.add_child(BloodlineTheme.heading("Audio"))
	left.add_child(_slider_row("Music", "music_volume"))
	left.add_child(_slider_row("Sound Effects", "sfx_volume"))

	left.add_child(BloodlineTheme.heading("Feedback"))
	left.add_child(_toggle_row("Haptics", "haptics"))

	left.add_child(BloodlineTheme.heading("Graphics"))
	left.add_child(_choice_row("Quality", "graphics_quality", ["low", "medium", "high"]))

	left.add_child(BloodlineTheme.heading("Controls"))
	left.add_child(_choice_row("Layout", "control_layout", ["standard", "left_handed"]))
	left.add_child(_toggle_row("Show Frame Data", "show_frame_data"))

	left.add_child(BloodlineTheme.heading("Language"))
	left.add_child(_choice_row("Language", "language", ["en", "fr", "es", "pt"]))

	# Right: the save data and the reset.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(right)

	var panel := UIScreen.make_panel()
	right.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	column.add_child(BloodlineTheme.heading("Save Data"))
	column.add_child(
		BloodlineTheme.body(
			(
				"Matches played: %d\nWins: %d\nLosses: %d"
				% [
					int(SaveSystem.progress.get("matches_played", 0)),
					SaveSystem.total_wins(),
					SaveSystem.total_losses()
				]
			),
			16
		)
	)

	_status = BloodlineTheme.body("", 16)
	column.add_child(_status)

	var reset := BloodlineTheme.secondary("Reset Save Data")
	reset.pressed.connect(_on_reset)
	column.add_child(reset)

	var note := BloodlineTheme.body(
		"Resetting removes all progress on this device. It cannot be undone.", 14
	)
	note.add_theme_color_override("font_color", BloodlineTheme.WARN)
	column.add_child(note)


func _slider_row(label_text: String, key: String) -> Control:
	var row := UIScreen.make_row(12)
	var label := BloodlineTheme.body(label_text, 17)
	label.custom_minimum_size = Vector2(190, 0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(SaveSystem.settings.get(key, 0.8))
	slider.custom_minimum_size = Vector2(240, 30)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(
		func(value: float) -> void:
			SaveSystem.settings[key] = value
			SaveSystem.save_settings()
			AudioDirector.apply_settings()
	)
	row.add_child(slider)
	return row


func _toggle_row(label_text: String, key: String) -> Control:
	var row := UIScreen.make_row(12)
	var label := BloodlineTheme.body(label_text, 17)
	label.custom_minimum_size = Vector2(190, 0)
	row.add_child(label)

	var check := CheckBox.new()
	check.button_pressed = bool(SaveSystem.settings.get(key, false))
	check.toggled.connect(
		func(value: bool) -> void:
			SaveSystem.settings[key] = value
			SaveSystem.save_settings()
			AudioDirector.apply_settings()
	)
	row.add_child(check)
	return row


func _choice_row(label_text: String, key: String, options: Array) -> Control:
	var row := UIScreen.make_row(12)
	var label := BloodlineTheme.body(label_text, 17)
	label.custom_minimum_size = Vector2(190, 0)
	row.add_child(label)

	var option := OptionButton.new()
	for value in options:
		option.add_item(String(value).capitalize())
	option.selected = maxi(0, options.find(SaveSystem.settings.get(key, options[0])))
	option.item_selected.connect(
		func(index: int) -> void:
			SaveSystem.settings[key] = options[index]
			SaveSystem.save_settings()
			AudioDirector.play_sound("ui_move")
	)
	row.add_child(option)
	return row


func _on_reset() -> void:
	var ok := SaveSystem.reset_save()
	if ok:
		_status.text = "Save data reset."
		_status.add_theme_color_override("font_color", BloodlineTheme.TEXT)
		for child in body().get_children():
			child.queue_free()
		build()
	else:
		_status.text = "Could not reset the save file."
		_status.add_theme_color_override("font_color", BloodlineTheme.DANGER)


func on_back() -> void:
	SaveSystem.save_settings()
	AudioDirector.apply_settings()
	SceneRouter.go_to("main_menu")
