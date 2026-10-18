extends UIScreen
## The results screen.
##
## Rewards are only shown after the save has actually succeeded, so the
## player is never shown a reward that did not stick. A rematch is one tap.

var _status: Label = null

var _rewards: Label = null

var _winner_id: String = ""

var _player_id: String = ""

var _enemy_id: String = ""

var _rounds: Dictionary = {}

var _credited: bool = false


func _ready() -> void:
	screen_id = "results"
	screen_title = "Result"
	_winner_id = String(SceneRouter.context.get("winner_id", ""))
	_player_id = String(SceneRouter.context.get("player_id", "unbound"))
	_enemy_id = String(SceneRouter.context.get("enemy_id", "dagan"))
	_rounds = SceneRouter.context.get("rounds", {})
	super._ready()


func build() -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body().add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)

	var headline := BloodlineTheme.title(_headline(), 54)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(headline)

	_status = BloodlineTheme.body("", 18)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status)

	_rewards = BloodlineTheme.body("", 17)
	_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_rewards)

	var row := UIScreen.make_row(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)

	var rematch := BloodlineTheme.primary("Rematch")
	rematch.pressed.connect(_on_rematch)
	row.add_child(rematch)

	var menu := BloodlineTheme.secondary("Main Menu")
	menu.pressed.connect(func() -> void: SceneRouter.go_to("main_menu"))
	row.add_child(menu)

	_credit_rewards()


func _headline() -> String:
	if _winner_id.is_empty():
		return "DRAW"
	if _winner_id == _player_id:
		return "VICTORY"
	return "DEFEAT"


func _credit_rewards() -> void:
	# The match id makes the credit idempotent, so a reward can never be
	# claimed twice, and the reward is only shown once the save succeeded.
	var match_id := int(Time.get_unix_time_from_system())
	var won := _winner_id == _player_id
	var result: Dictionary = SaveSystem.record_match(
		match_id, _player_id, _enemy_id, won, int(_rounds.size())
	)
	if bool(result.get("ok", false)):
		_credited = true
		_status.text = "Progress saved."
		_rewards.text = (
			"%s mastery: %d" % [ContentDB.fighter_name(_player_id), int(result.get("mastery", 0))]
		)
	else:
		var reason := String(result.get("reason", "unknown"))
		if reason == "already_claimed":
			_status.text = "This result has already been recorded."
		else:
			_status.text = "Progress could not be saved on this device."
		_rewards.text = "No rewards were credited."


func _on_rematch() -> void:
	(
		SceneRouter
		. go_to(
			"loading",
			{
				"player_id": _player_id,
				"enemy_id": _enemy_id,
				"difficulty": String(SceneRouter.context.get("difficulty", "standard")),
				"arena_id": String(SceneRouter.context.get("arena_id", "meridian_hall")),
				"rounds": 2,
				"seconds": 60,
			}
		)
	)


func on_back() -> void:
	SceneRouter.go_to("main_menu")
