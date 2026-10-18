extends UIScreen
## The main menu.
##
## Five entries: Play, Fighters, Practice, Collection, Settings. There is
## no Online button, because there is no online mode. Every entry leads to
## a screen that actually works.


func _ready() -> void:
	screen_id = "main_menu"
	screen_title = "BLOODLINE"
	super._ready()


func build() -> void:
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 40)
	body().add_child(columns)

	# Left: the wordmark and a line of flavour.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 14)
	columns.add_child(left)

	var logo := BloodlineTheme.title("BLOODLINE", 72)
	left.add_child(logo)
	var tagline := BloodlineTheme.body(
		"A side-on fight against the Veil, and against whoever is already standing in the ring.", 18
	)
	tagline.custom_minimum_size = Vector2(420, 0)
	left.add_child(tagline)

	var record := BloodlineTheme.body(
		(
			"Wins %d   ·   Losses %d   ·   Matches %d"
			% [
				SaveSystem.total_wins(),
				SaveSystem.total_losses(),
				int(SaveSystem.progress.get("matches_played", 0))
			]
		),
		16
	)
	left.add_child(record)

	# Right: the menu entries.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)

	var play := BloodlineTheme.primary("Play")
	play.pressed.connect(_on_play)
	right.add_child(play)

	var fighters := BloodlineTheme.secondary("Fighters")
	fighters.pressed.connect(_on_fighters)
	right.add_child(fighters)

	var practice := BloodlineTheme.secondary("Practice")
	practice.pressed.connect(_on_practice)
	right.add_child(practice)

	var collection := BloodlineTheme.secondary("Collection")
	collection.pressed.connect(_on_collection)
	right.add_child(collection)

	var settings := BloodlineTheme.secondary("Settings")
	settings.pressed.connect(_on_settings)
	right.add_child(settings)


func _on_play() -> void:
	SceneRouter.go_to("fighter_select", {"mode": "versus"})


func _on_fighters() -> void:
	SceneRouter.go_to("fighter_select", {"mode": "roster"})


func _on_practice() -> void:
	SceneRouter.go_to("practice")


func _on_collection() -> void:
	SceneRouter.go_to("collection")


func _on_settings() -> void:
	SceneRouter.go_to("settings")
