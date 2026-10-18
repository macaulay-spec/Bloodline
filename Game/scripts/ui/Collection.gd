extends UIScreen
## The collection screen.
##
## Mastery and cosmetics only. Mastery never inflates a fighter's stats:
## it unlocks cosmetic items and, eventually, new choices. Nothing here
## can be bought.

var _selected_id: String = "unbound"

var _detail: VBoxContainer = null

var _roster_list: VBoxContainer = null


func _ready() -> void:
	screen_id = "collection"
	screen_title = "Collection"
	show_back = true
	super._ready()


func build() -> void:
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 28)
	body().add_child(columns)

	# Left: the roster, with each fighter's record.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)

	left.add_child(BloodlineTheme.heading("Roster"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)

	_roster_list = VBoxContainer.new()
	_roster_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_roster_list)

	_populate_roster()

	# Right: the selected fighter and their cosmetics.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)

	_detail = VBoxContainer.new()
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 10)
	right.add_child(_detail)

	_populate_detail()


func _populate_roster() -> void:
	for child in _roster_list.get_children():
		child.queue_free()
	for fighter_id in ContentDB.roster_order:
		var button := Button.new()
		var wins := SaveSystem.wins_for(fighter_id)
		var losses := SaveSystem.losses_for(fighter_id)
		var mastery := SaveSystem.mastery_for(fighter_id)
		button.text = (
			"%-14s  %dW %dL   mastery %d"
			% [ContentDB.fighter_name(fighter_id), wins, losses, mastery]
		)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 46)
		button.pressed.connect(_on_select.bind(fighter_id))
		_roster_list.add_child(button)


func _on_select(fighter_id: String) -> void:
	_selected_id = fighter_id
	AudioDirector.play_sound("ui_move")
	_populate_detail()


func _populate_detail() -> void:
	for child in _detail.get_children():
		child.queue_free()

	var fighter := ContentDB.get_fighter(_selected_id)
	if fighter.is_empty():
		return

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(220, 240)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var path := String(fighter.get("portrait", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		portrait.texture = load(path)
	_detail.add_child(portrait)

	_detail.add_child(BloodlineTheme.title(ContentDB.fighter_name(_selected_id), 28))
	_detail.add_child(BloodlineTheme.body(String(fighter.get("title", "")), 16))
	_detail.add_child(BloodlineTheme.body(String(fighter.get("description", "")), 16))

	var record := BloodlineTheme.body(
		(
			"Wins %d   ·   Losses %d   ·   Mastery %d"
			% [
				SaveSystem.wins_for(_selected_id),
				SaveSystem.losses_for(_selected_id),
				SaveSystem.mastery_for(_selected_id)
			]
		),
		16
	)
	_detail.add_child(record)

	_detail.add_child(BloodlineTheme.heading("Cosmetics"))
	var note := BloodlineTheme.body(
		"Cosmetics only. Mastery never changes a fighter's strength.", 15
	)
	_detail.add_child(note)

	for entry in SaveSystem.cosmetic_catalog():
		var unlocked := SaveSystem.is_cosmetic_unlocked(_selected_id, String(entry["id"]))
		var line := BloodlineTheme.body(
			(
				"%s  —  %s"
				% [
					String(entry["name"]),
					(
						"Unlocked"
						if unlocked
						else "Mastery %d required" % int(entry["mastery_required"])
					)
				]
			),
			15
		)
		if not unlocked:
			line.add_theme_color_override("font_color", BloodlineTheme.WARN)
		_detail.add_child(line)


func on_back() -> void:
	SceneRouter.go_to("main_menu")
