class_name UIScreen

extends Control
## Base class for every full-screen UI screen.
##
## Provides the shared background, the safe-area padding, a consistent
## header and a standard way to build the screen. Subclasses call
## `build()` from `_ready()`.

## The screen id, used by the router.
var screen_id: String = "screen"

## The screen title shown in the header.
var screen_title: String = ""

## Whether a back button is offered.
var show_back: bool = false

var _root: VBoxContainer = null

var _header: HBoxContainer = null

var _body: VBoxContainer = null

var _back_button: Button = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_background()
	_build_frame()
	build()


## Override in a subclass to fill the screen.
func build() -> void:
	pass


## The main content column, for subclasses to add to.
func body() -> VBoxContainer:
	return _body


## The root column, when a subclass needs the whole layout.
func root() -> VBoxContainer:
	return _root


func _build_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = BloodlineTheme.BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# A soft Veil glow behind the content.
	var glow := ColorRect.new()
	glow.name = "Glow"
	glow.color = Color(
		BloodlineTheme.ACCENT.r, BloodlineTheme.ACCENT.g, BloodlineTheme.ACCENT.b, 0.05
	)
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)


func _build_frame() -> void:
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	_root = VBoxContainer.new()
	_root.name = "Root"
	_root.add_theme_constant_override("separation", 16)
	margin.add_child(_root)

	_header = HBoxContainer.new()
	_header.name = "Header"
	_header.add_theme_constant_override("separation", 16)
	_root.add_child(_header)

	if show_back:
		_back_button = BloodlineTheme.secondary("Back")
		_back_button.pressed.connect(_on_back_pressed)
		_header.add_child(_back_button)

	var title_label := BloodlineTheme.title(screen_title, 34)
	title_label.name = "Title"
	_header.add_child(title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(spacer)

	_body = VBoxContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 14)
	_root.add_child(_body)


func _on_back_pressed() -> void:
	AudioDirector.play_sound("ui_back")
	on_back()


## Override to handle the back button.
func on_back() -> void:
	SceneRouter.go_to("main_menu")


## A panel that holds a block of content.
static func make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", BloodlineTheme._panel_box(BloodlineTheme.PANEL))
	return panel


## A horizontal strip of buttons.
static func make_row(separation: int = 12) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	return row


## A right-aligned text line.
static func make_label(
	text: String, color: Color = BloodlineTheme.TEXT_DIM, size: int = 17
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return label
