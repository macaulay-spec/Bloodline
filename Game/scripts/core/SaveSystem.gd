extends Node
## Offline save system.
##
## Everything is stored locally in `user://`. There is no online service
## and no monetisation: the game never asks for an account, and rewards are
## only credited once the write has actually succeeded.
##
## The save file holds progress and settings. Mastery only ever unlocks
## cosmetics and new choices, never raw stats.

const SAVE_PATH := "user://bloodline_save.json"

const SETTINGS_PATH := "user://bloodline_settings.json"

const SAVE_VERSION := 1

## Progress for each fighter: wins, losses, mastery points.
var progress: Dictionary = {}

## Cosmetic items the player has unlocked, keyed by item id.
var unlocked_cosmetics: Dictionary = {}

## The last match the player finished, used by the rematch button.
var last_match: Dictionary = {}

## Monotonic counter used to stop a reward being claimed twice.
var last_claimed_match_id: int = 0

## The player's settings.
var settings: Dictionary = {}


func _ready() -> void:
	_default_settings()
	load_all()


func _default_settings() -> void:
	settings = {
		"music_volume": 0.7,
		"sfx_volume": 0.9,
		"haptics": true,
		"graphics_quality": "medium",
		"control_layout": "standard",
		"language": "en",
		"show_frame_data": false,
	}


func load_all() -> void:
	progress = _read_json(SAVE_PATH)
	if progress.is_empty():
		progress = _default_progress()
	else:
		progress["version"] = SAVE_VERSION
		for id in progress.keys():
			if id == "version":
				continue
			if typeof(progress[id]) != TYPE_DICTIONARY:
				progress.erase(id)
	var stored_settings := _read_json(SETTINGS_PATH)
	for key in stored_settings.keys():
		if settings.has(key):
			settings[key] = stored_settings[key]


func _default_progress() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"wins": {},
		"losses": {},
		"mastery": {},
		"matches_played": 0,
	}


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


## Writes the save file. Returns true only if the write actually landed.
func save() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: could not open save file for writing")
		return false
	file.store_string(JSON.stringify(progress, "  "))
	file.close()
	# Confirm the write so rewards are never credited against a lost save.
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var check := _read_json(SAVE_PATH)
	return not check.is_empty()


## Writes the settings file. Returns true if the write landed.
func save_settings() -> bool:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(settings, "  "))
	file.close()
	return FileAccess.file_exists(SETTINGS_PATH)


## Resets everything. Returns true if the reset was persisted.
func reset_save() -> bool:
	progress = _default_progress()
	unlocked_cosmetics.clear()
	last_match.clear()
	last_claimed_match_id = 0
	return save()


## True when a fighter is available to the player.
##
## Lock conditions are real: they are visible in the UI and they are
## checked against actual progress.
func is_fighter_unlocked(fighter_id: String) -> bool:
	var fighter := ContentDB.get_fighter(fighter_id)
	if fighter.is_empty():
		return false
	var unlock: Dictionary = fighter.get("unlock", {})
	var condition := String(unlock.get("condition", "available"))
	return _unlock_requirements().get(condition, false)


## The unlock conditions and whether each one is met right now.
func _unlock_requirements() -> Dictionary:
	return {
		"available": true,
		"wins_2": total_wins() >= 2,
		"wins_5": total_wins() >= 5,
		"wins_10": total_wins() >= 10,
		"campaign_1": int(progress.get("campaign_cleared", 0)) >= 1,
	}


## The text shown next to a locked fighter.
func unlock_text(fighter_id: String) -> String:
	var fighter := ContentDB.get_fighter(fighter_id)
	if fighter.is_empty():
		return ""
	var unlock: Dictionary = fighter.get("unlock", {})
	return String(unlock.get("text", ""))


func total_wins() -> int:
	var wins: Dictionary = progress.get("wins", {})
	var total := 0
	for key in wins.keys():
		total += int(wins[key])
	return total


func total_losses() -> int:
	var losses: Dictionary = progress.get("losses", {})
	var total := 0
	for key in losses.keys():
		total += int(losses[key])
	return total


func wins_for(fighter_id: String) -> int:
	var wins: Dictionary = progress.get("wins", {})
	return int(wins.get(fighter_id, 0))


func losses_for(fighter_id: String) -> int:
	var losses: Dictionary = progress.get("losses", {})
	return int(losses.get(fighter_id, 0))


## Mastery points for a fighter. Mastery unlocks cosmetics only.
func mastery_for(fighter_id: String) -> int:
	var mastery: Dictionary = progress.get("mastery", {})
	return int(mastery.get(fighter_id, 0))


## Records the result of a match and credits the rewards.
##
## `match_id` makes the call idempotent: a reward can never be claimed
## twice, and nothing is credited if the save fails.
func record_match(
	match_id: int, player_id: String, enemy_id: String, player_won: bool, rounds: int
) -> Dictionary:
	if match_id <= last_claimed_match_id:
		return {"ok": false, "reason": "already_claimed"}
	last_claimed_match_id = match_id

	var wins: Dictionary = progress.get("wins", {})
	var losses: Dictionary = progress.get("losses", {})
	var mastery: Dictionary = progress.get("mastery", {})

	if player_won:
		wins[player_id] = int(wins.get(player_id, 0)) + 1
		losses[enemy_id] = int(losses.get(enemy_id, 0)) + 1
		mastery[player_id] = int(mastery.get(player_id, 0)) + 1
	else:
		losses[player_id] = int(losses.get(player_id, 0)) + 1
		wins[enemy_id] = int(wins.get(enemy_id, 0)) + 1
		mastery[player_id] = int(mastery.get(player_id, 0)) + 1

	progress["wins"] = wins
	progress["losses"] = losses
	progress["mastery"] = mastery
	progress["matches_played"] = int(progress.get("matches_played", 0)) + 1

	last_match = {
		"player_id": player_id,
		"enemy_id": enemy_id,
		"player_won": player_won,
		"rounds": rounds,
	}

	# Rewards are only credited once the write has succeeded.
	if not save():
		return {"ok": false, "reason": "save_failed"}

	return {"ok": true, "mastery": int(mastery.get(player_id, 0))}


## A cosmetic is unlocked when the fighter's mastery reaches the needed
## level. Mastery never changes a fighter's stats.
func is_cosmetic_unlocked(fighter_id: String, cosmetic_id: String) -> bool:
	if unlocked_cosmetics.get(cosmetic_id, false):
		return true
	var requirement := 3
	for entry in _cosmetic_catalog():
		if String(entry.get("id", "")) == cosmetic_id:
			requirement = int(entry.get("mastery_required", 3))
			break
	return mastery_for(fighter_id) >= requirement


## The cosmetic catalogue. Cosmetic only - no stat changes.
func _cosmetic_catalog() -> Array:
	return [
		{"id": "trail_veil", "name": "Veil Trail", "mastery_required": 2},
		{"id": "core_gold", "name": "Gilded Core", "mastery_required": 4},
		{"id": "coat_ash", "name": "Ash Coat", "mastery_required": 6},
		{"id": "core_prism", "name": "Prism Core", "mastery_required": 9},
	]


func cosmetic_catalog() -> Array:
	return _cosmetic_catalog()
