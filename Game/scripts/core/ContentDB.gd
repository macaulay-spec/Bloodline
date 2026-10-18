extends Node
## Content database.
##
## Loads the data-driven game content: the fighter roster, the move tables
## and the arena list. Everything the game knows about combat lives in the
## JSON files under res://data, so balance changes never require touching
## code.
##
## The database is an autoload, registered as `ContentDB`.

const FIGHTERS_PATH := "res://data/fighters.json"

const MOVES_PATH := "res://data/moves.json"

const ARENAS_PATH := "res://data/arenas.json"

## Every fighter definition, keyed by fighter id.
var fighters: Dictionary = {}

## Every move definition, keyed by move id.
var moves: Dictionary = {}

## Every arena definition, keyed by arena id.
var arenas: Dictionary = {}

## Ordered list of fighter ids, as they appear in the roster.
var roster_order: Array[String] = []

## Ordered list of arena ids.
var arena_order: Array[String] = []


func _ready() -> void:
	reload()


func reload() -> void:
	fighters = _load_json(FIGHTERS_PATH)
	moves = _load_json(MOVES_PATH)
	arenas = _load_json(ARENAS_PATH)

	roster_order.clear()
	for id in fighters.keys():
		var entry: Dictionary = fighters[id]
		if bool(entry.get("in_roster", true)):
			roster_order.append(String(id))

	arena_order.clear()
	for id in arenas.keys():
		arena_order.append(String(id))

	roster_order.sort()
	arena_order.sort()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("ContentDB: missing content file %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("ContentDB: empty content file %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ContentDB: malformed content file %s" % path)
		return {}
	return parsed


## Returns the fighter definition for `fighter_id`, or an empty dictionary.
func get_fighter(fighter_id: String) -> Dictionary:
	return fighters.get(fighter_id, {})


## Returns the move definition for `move_id`, or an empty dictionary.
func get_move(move_id: String) -> Dictionary:
	return moves.get(move_id, {})


## Returns the arena definition for `arena_id`, or an empty dictionary.
func get_arena(arena_id: String) -> Dictionary:
	return arenas.get(arena_id, {})


## The list of move ids a fighter can use, in input priority order.
func fighter_move_ids(fighter_id: String) -> Array:
	var fighter := get_fighter(fighter_id)
	if fighter.is_empty():
		return []
	return fighter.get("moves", [])


## A fighter's move definition merged with its fighter-specific overrides.
##
## Per-fighter tuning (damage multipliers, reach, cooldowns) lives in the
## roster file and is layered on top of the shared move table.
func get_move_for(fighter_id: String, move_id: String) -> Dictionary:
	var move := get_move(move_id)
	if move.is_empty():
		return {}
	var fighter := get_fighter(fighter_id)
	var overrides: Dictionary = fighter.get("move_overrides", {})
	if overrides.has(move_id):
		var patch: Dictionary = overrides[move_id]
		var merged := move.duplicate(true)
		for key in patch.keys():
			if typeof(patch[key]) == TYPE_DICTIONARY and typeof(merged.get(key)) == TYPE_DICTIONARY:
				var nested: Dictionary = (merged[key] as Dictionary).duplicate(true)
				for nested_key in (patch[key] as Dictionary).keys():
					nested[nested_key] = patch[key][nested_key]
				merged[key] = nested
			else:
				merged[key] = patch[key]
		return merged
	return move


## Human readable fighter name, falling back to the id.
func fighter_name(fighter_id: String) -> String:
	var fighter := get_fighter(fighter_id)
	return String(fighter.get("name", fighter_id.to_upper()))


## Human readable move name, falling back to the id.
func move_name(move_id: String) -> String:
	var move := get_move(move_id)
	return String(move.get("name", move_id.to_upper()))


## The arenas a given fighter is allowed to fight in.
func arenas_for(fighter_id: String) -> Array:
	var fighter := get_fighter(fighter_id)
	if fighter.is_empty():
		return arena_order.duplicate()
	var allowed: Array = fighter.get("arenas", [])
	if allowed.is_empty():
		return arena_order.duplicate()
	return allowed
