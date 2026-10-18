class_name BloodlineTheme

extends RefCounted
## The shared look of the game.
##
## Everything is built in code so the project has a single source of truth
## for colour and type, and so the UI works at any screen size.

## Background of the whole game.
const BG := Color(0.035, 0.042, 0.065)

## Panel background.
const PANEL := Color(0.07, 0.08, 0.115)

## Panel background, raised.
const PANEL_RAISED := Color(0.11, 0.125, 0.17)

## Primary text.
const TEXT := Color(0.90, 0.92, 0.96)

## Secondary text.
const TEXT_DIM := Color(0.58, 0.62, 0.70)

## The Veil accent.
const ACCENT := Color(0.36, 0.78, 0.92)

## Warning and lock colour.
const WARN := Color(0.95, 0.62, 0.28)

## Danger, used for damage and break.
const DANGER := Color(0.92, 0.32, 0.30)

## Health.
const HEALTH := Color(0.55, 0.85, 0.45)

## Meter.
const METER := Color(0.45, 0.70, 0.98)

## Guard.
const GUARD := Color(0.85, 0.80, 0.45)


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 20

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM.darkened(0.3))
	theme.set_color("font_color", "RichTextLabel", TEXT)

	theme.set_stylebox("normal", "Button", _button_box(PANEL_RAISED, ACCENT.darkened(0.5)))
	theme.set_stylebox("hover", "Button", _button_box(PANEL_RAISED.lightened(0.12), ACCENT))
	theme.set_stylebox("pressed", "Button", _button_box(ACCENT.darkened(0.55), ACCENT))
	theme.set_stylebox(
		"disabled", "Button", _button_box(PANEL.darkened(0.2), TEXT_DIM.darkened(0.5))
	)
	theme.set_stylebox("focus", "Button", _button_box(Color(0, 0, 0, 0), ACCENT))

	theme.set_stylebox("panel", "PanelContainer", _panel_box(PANEL))
	theme.set_stylebox("panel", "Panel", _panel_box(PANEL))
	theme.set_constant("separation", "VBoxContainer", 12)
	theme.set_constant("separation", "HBoxContainer", 12)

	theme.set_stylebox("background", "ProgressBar", _panel_box(Color(0.05, 0.06, 0.08)))
	theme.set_color("font_color", "ProgressBar", TEXT)

	theme.set_stylebox("normal", "LineEdit", _panel_box(Color(0.05, 0.06, 0.09)))
	theme.set_stylebox("focus", "LineEdit", _panel_box(Color(0.05, 0.06, 0.09), ACCENT))

	return theme


static func _panel_box(color: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	if border.a > 0.0:
		box.border_color = border
		box.set_border_width_all(1)
	return box


static func _button_box(color: Color, border: Color) -> StyleBoxFlat:
	var box := _panel_box(color, border)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


## A title label in the game's type.
static func title(text: String, size: int = 48) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT)
	return label


## A section heading.
static func heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", ACCENT)
	return label


## A dim supporting line.
static func body(text: String, size: int = 17) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT_DIM)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## A primary action button.
static func primary(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 56)
	button.add_theme_font_size_override("font_size", 22)
	return button


## A secondary action button.
static func secondary(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 46)
	button.add_theme_font_size_override("font_size", 18)
	return button
