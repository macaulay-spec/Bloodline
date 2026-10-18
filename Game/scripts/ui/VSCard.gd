extends UIScreen
## The versus card.
##
## The two fighters face off for a moment before the match starts.

## How long the card holds, in seconds.
const HOLD_TIME := 2.0

var _elapsed: float = 0.0

var _done: bool = false

var _player_name: Label = null

var _enemy_name: Label = null

var _player_portrait: TextureRect = null

var _enemy_portrait: TextureRect = null


func _ready() -> void:
	screen_id = "vs_card"
	screen_title = ""
	super._ready()


func build() -> void:
	var player_id := String(SceneRouter.context.get("player_id", "unbound"))
	var enemy_id := String(SceneRouter.context.get("enemy_id", "dagan"))

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body().add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)

	var row := UIScreen.make_row(36)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)

	_player_portrait = _portrait(player_id)
	row.add_child(_player_portrait)

	var vs := BloodlineTheme.title("VS", 52)
	row.add_child(vs)

	_enemy_portrait = _portrait(enemy_id)
	row.add_child(_enemy_portrait)

	_player_name = BloodlineTheme.title(ContentDB.fighter_name(player_id), 28)
	_player_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_player_name)

	_enemy_name = BloodlineTheme.title(ContentDB.fighter_name(enemy_id), 28)
	_enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_enemy_name)

	var arena_label := BloodlineTheme.body(
		String(
			ContentDB.get_arena(String(SceneRouter.context.get("arena_id", "meridian_hall"))).get(
				"name", ""
			)
		),
		17
	)
	arena_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(arena_label)


func _portrait(fighter_id: String) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(220, 200)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var path := String(ContentDB.get_fighter(fighter_id).get("portrait", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		portrait.texture = load(path)
	return portrait


func _process(delta: float) -> void:
	_elapsed += delta
	# The portraits slide in from the sides.
	var t := clampf(_elapsed / 0.5, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	if _player_portrait != null:
		_player_portrait.position.x = lerpf(-220.0, 0.0, eased)
	if _enemy_portrait != null:
		_enemy_portrait.position.x = lerpf(220.0, 0.0, eased)

	if _elapsed >= HOLD_TIME and not _done:
		_done = true
		SceneRouter.go_to("match")
