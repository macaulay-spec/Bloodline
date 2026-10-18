extends UIScreen
## The boot splash.
##
## Shows the Veil-seam logo with a drone, holds for a moment, then hands
## over to the main menu. It also warms the content database so the first
## screen after it is instant.

## How long the splash holds, in seconds.
const HOLD_TIME := 2.5

## How long the logo takes to fade in.
const FADE_TIME := 0.9

var _elapsed: float = 0.0

var _logo: Label = null

var _seam: ColorRect = null

var _drone: Control = null

var _done: bool = false


func _ready() -> void:
	screen_id = "boot"
	screen_title = ""
	super._ready()
	AudioDirector.play_music("menu")


func build() -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body().add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)

	_logo = BloodlineTheme.title("BLOODLINE", 64)
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.modulate = Color(1, 1, 1, 0)
	column.add_child(_logo)

	var subtitle := BloodlineTheme.body("The Veil is bleeding through.", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(1, 1, 1, 0)
	subtitle.name = "Subtitle"
	column.add_child(subtitle)

	# The seam: a thin bright line that opens down the middle of the screen.
	_seam = ColorRect.new()
	_seam.name = "Seam"
	_seam.color = Color(
		BloodlineTheme.ACCENT.r, BloodlineTheme.ACCENT.g, BloodlineTheme.ACCENT.b, 0.0
	)
	_seam.set_anchors_preset(Control.PRESET_FULL_RECT)
	_seam.anchor_left = 0.5
	_seam.anchor_right = 0.5
	_seam.anchor_top = 0.18
	_seam.anchor_bottom = 0.82
	_seam.offset_left = -1.5
	_seam.offset_right = 1.5
	_seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_seam)

	_drone = Control.new()
	_drone.name = "Drone"
	_drone.custom_minimum_size = Vector2(26, 26)
	_drone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_drone)
	var drone_icon := ColorRect.new()
	drone_icon.color = BloodlineTheme.ACCENT
	drone_icon.size = Vector2(26, 26)
	drone_icon.position = Vector2(13, 13)
	drone_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drone.add_child(drone_icon)


func _process(delta: float) -> void:
	_elapsed += delta

	# The logo fades up, the seam opens, and the drone drifts.
	var fade := clampf(_elapsed / FADE_TIME, 0.0, 1.0)
	_logo.modulate = Color(1, 1, 1, fade)
	var subtitle := body().find_child("Subtitle", true, false)
	if subtitle != null:
		(subtitle as Label).modulate = Color(1, 1, 1, fade * 0.8)

	var seam_amount := clampf((_elapsed - 0.35) / 0.8, 0.0, 1.0)
	_seam.color = Color(
		BloodlineTheme.ACCENT.r, BloodlineTheme.ACCENT.g, BloodlineTheme.ACCENT.b, seam_amount * 0.5
	)
	_seam.offset_left = lerpf(-1.5, -0.5, seam_amount)
	_seam.offset_right = lerpf(1.5, 0.5, seam_amount)

	if _drone != null:
		var drift := sin(_elapsed * 2.2) * 26.0
		_drone.position = Vector2(drift, 0.0)

	if _elapsed >= HOLD_TIME and not _done:
		_done = true
		SceneRouter.go_to("main_menu")
