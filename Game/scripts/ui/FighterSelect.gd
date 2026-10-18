extends UIScreen
## Fighter select.
##
## Shows the roster with the real in-game model portrait, and the real
## unlock condition for anyone still locked. In versus mode the player
## picks their fighter and then their opponent.

## "versus" or "roster".
var mode: String = "versus"

## The fighter the player has chosen.
var selected_id: String = ""

## The opponent the player has chosen.
var opponent_id: String = ""

## Which side the player is picking for.
var picking_opponent: bool = false

var _grid: GridContainer = null

var _cards: Dictionary = {}

var _confirm: Button = null

var _status: Label = null


func _ready() -> void:
	screen_id = "fighter_select"
	screen_title = "Fighters"
	show_back = true
	mode = String(SceneRouter.context.get("mode", "versus"))
	super._ready()


func build() -> void:
	if mode == "versus":
		_status = BloodlineTheme.body("Choose your fighter.", 18)
	else:
		_status = BloodlineTheme.body("The roster. Everyone here fights the same rules.", 18)
	body().add_child(_status)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body().add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(_grid)

	_populate()

	_confirm = BloodlineTheme.primary("Confirm")
	_confirm.pressed.connect(_on_confirm)
	_confirm.disabled = true
	var row := UIScreen.make_row()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_confirm)
	body().add_child(row)


func _populate() -> void:
	_cards.clear()
	for fighter_id in ContentDB.roster_order:
		var card := _make_card(fighter_id)
		_grid.add_child(card)
		_cards[fighter_id] = card


## A fighter card: portrait, name, title, and the unlock state.
func _make_card(fighter_id: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 250)
	panel.add_theme_stylebox_override(
		"panel",
		BloodlineTheme._panel_box(BloodlineTheme.PANEL, BloodlineTheme.ACCENT.darkened(0.6))
	)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(272, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var portrait_path := String(ContentDB.get_fighter(fighter_id).get("portrait", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	column.add_child(portrait)

	var name_label := BloodlineTheme.title(ContentDB.fighter_name(fighter_id), 22)
	column.add_child(name_label)

	var title_label := BloodlineTheme.body(
		String(ContentDB.get_fighter(fighter_id).get("title", "")), 15
	)
	column.add_child(title_label)

	var unlocked := SaveSystem.is_fighter_unlocked(fighter_id)
	if not unlocked:
		var lock := BloodlineTheme.body("Locked — " + SaveSystem.unlock_text(fighter_id), 15)
		lock.add_theme_color_override("font_color", BloodlineTheme.WARN)
		column.add_child(lock)
		panel.modulate = Color(0.6, 0.6, 0.65, 1.0)
	else:
		var stats := BloodlineTheme.body(_stat_line(fighter_id), 14)
		column.add_child(stats)

		var button := Button.new()
		button.text = "Select"
		button.custom_minimum_size = Vector2(0, 40)
		button.disabled = not unlocked
		button.pressed.connect(_on_select.bind(fighter_id))
		column.add_child(button)

	return panel


func _stat_line(fighter_id: String) -> String:
	var data := ContentDB.get_fighter(fighter_id)
	return (
		"HP %d   ·   Style %s"
		% [int(data.get("health", 1000)), String(data.get("style", "")).capitalize()]
	)


func _on_select(fighter_id: String) -> void:
	AudioDirector.play_sound("ui_move")
	if mode == "roster":
		_status.text = (
			"%s — %s"
			% [
				ContentDB.fighter_name(fighter_id),
				String(ContentDB.get_fighter(fighter_id).get("description", ""))
			]
		)
		return

	if not picking_opponent:
		selected_id = fighter_id
		picking_opponent = true
		_status.text = "Now choose your opponent."
		_confirm.disabled = true
	else:
		if fighter_id == selected_id:
			_status.text = "Pick a different opponent."
			return
		opponent_id = fighter_id
		_confirm.disabled = false
		_status.text = (
			"%s versus %s"
			% [ContentDB.fighter_name(selected_id), ContentDB.fighter_name(opponent_id)]
		)


func _on_confirm() -> void:
	if selected_id.is_empty() or opponent_id.is_empty():
		return
	(
		SceneRouter
		. go_to(
			"versus_setup",
			{
				"player_id": selected_id,
				"enemy_id": opponent_id,
			}
		)
	)


func on_back() -> void:
	if picking_opponent:
		picking_opponent = false
		_status.text = "Choose your fighter."
		return
	SceneRouter.go_to("main_menu")
