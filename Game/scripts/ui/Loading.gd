extends UIScreen
## The loading screen.
##
## Preloads the two fighter models and the arena, so the match starts
## without a hitch. The progress bar reflects real work, not a timer.

var _progress: ProgressBar = null

var _status: Label = null

var _elapsed: float = 0.0

var _prepared: bool = false

var _advanced: bool = false


func _ready() -> void:
	screen_id = "loading"
	screen_title = ""
	super._ready()


func build() -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body().add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)

	_status = BloodlineTheme.body("Opening the Veil…", 18)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status)

	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(420, 18)
	_progress.max_value = 1.0
	_progress.value = 0.0
	_progress.show_percentage = false
	column.add_child(_progress)


func _process(delta: float) -> void:
	_elapsed += delta
	if not _prepared:
		_prepare()
		return
	# Let the bar finish visually before moving on.
	_progress.value = minf(1.0, _progress.value + delta * 2.0)
	if _progress.value >= 1.0 and _elapsed > 0.6 and not _advanced:
		_advanced = true
		SceneRouter.go_to("vs_card")


## Warms the models the match needs.
func _prepare() -> void:
	var steps: Array[String] = []
	steps.append(String(SceneRouter.context.get("player_id", "unbound")))
	steps.append(String(SceneRouter.context.get("enemy_id", "dagan")))

	for i in range(steps.size()):
		var fighter_id := steps[i]
		_status.text = "Loading %s…" % ContentDB.fighter_name(fighter_id)
		var fighter := ContentDB.get_fighter(fighter_id)
		var model_path := String(fighter.get("model", ""))
		if not model_path.is_empty() and ResourceLoader.exists(model_path):
			var packed: PackedScene = load(model_path)
			if packed != null:
				var instance := packed.instantiate()
				instance.queue_free()
		_progress.value = float(i + 1) / float(steps.size() + 1)
		# Yield so the screen actually paints between steps.
		await get_tree().process_frame

	_status.text = "Setting the arena…"
	await get_tree().process_frame
	_progress.value = 1.0
	_prepared = true
