extends Node
## Screen routing.
##
## Owns the current screen and swaps between them. Every screen is a
## `UIScreen` and is added as a child of the router's host, so transitions
## are a single call and there is never a half-built screen on screen.

## Emitted after a screen has been swapped in.
signal screen_changed(screen_id: String)

const SCREENS := {
	"boot": "res://scenes/Boot.tscn",
	"main_menu": "res://scenes/MainMenu.tscn",
	"fighter_select": "res://scenes/FighterSelect.tscn",
	"versus_setup": "res://scenes/VersusSetup.tscn",
	"loading": "res://scenes/Loading.tscn",
	"vs_card": "res://scenes/VSCard.tscn",
	"match": "res://scenes/Match.tscn",
	"results": "res://scenes/Results.tscn",
	"practice": "res://scenes/Practice.tscn",
	"collection": "res://scenes/Collection.tscn",
	"settings": "res://scenes/Settings.tscn",
}

## The node that screens are added under.
var host: Node = null

## The screen currently on screen.
var current: Node = null

## The id of the screen currently on screen.
var current_id: String = ""

## The context passed between screens, e.g. the chosen fighters.
var context: Dictionary = {}


func set_host(node: Node) -> void:
	host = node


## Swaps to the screen with the given id.
func go_to(screen_id: String, new_context: Dictionary = {}) -> void:
	if not SCREENS.has(screen_id):
		push_error("SceneRouter: unknown screen %s" % screen_id)
		return
	var path: String = SCREENS[screen_id]
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: missing scene %s" % path)
		return

	for key in new_context.keys():
		context[key] = new_context[key]

	if current != null:
		current.queue_free()
		current = null

	var packed: PackedScene = load(path)
	var screen: Node = packed.instantiate()
	if host != null:
		host.add_child(screen)
	else:
		add_child(screen)
	current = screen
	current_id = screen_id
	screen_changed.emit(screen_id)
	AudioDirector.play_sound("ui_select")


## Returns to the main menu, clearing the match context.
func go_to_menu() -> void:
	context.clear()
	go_to("main_menu")
