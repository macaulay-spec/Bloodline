extends Node
## The application root.
##
## Sets up the screen host and hands over to the boot splash. Everything
## else is driven by the `SceneRouter` autoload.

## The node that screens are added under.
var _host: Control = null


func _ready() -> void:
	# The screen host fills the window and sits behind everything.
	_host = Control.new()
	_host.name = "Screens"
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_host)

	SceneRouter.set_host(_host)
	SceneRouter.go_to("boot")
