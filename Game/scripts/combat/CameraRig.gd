class_name CameraRig

extends Node3D
## The match camera.
##
## The camera frames both combatants at all times. It never loses a
## fighter, and it never cuts: it tracks the midpoint of the two fighters
## and pulls back as the distance between them grows.

## The fighter on the left of the screen.
var left_fighter: Fighter = null

## The fighter on the right of the screen.
var right_fighter: Fighter = null

var _camera: Camera3D = null

var _current_distance: float = 8.0

var _current_height: float = 2.6

var _current_look: Vector3 = Vector3(0.0, 1.1, 0.0)

var _shake_amount: float = 0.0

var _shake_time: float = 0.0


func setup(a: Fighter, b: Fighter) -> void:
	left_fighter = a
	right_fighter = b

	_camera = Camera3D.new()
	_camera.name = "MatchCamera"
	_camera.fov = 48.0
	_camera.near = 0.15
	_camera.far = 120.0
	_camera.current = true
	add_child(_camera)
	_camera.position = Vector3(0.0, 2.6, 8.0)


## Adds camera shake, used on heavy impacts.
func add_shake(amount: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)
	_shake_time = 0.25


## The camera's current framing, exposed for tests and the debug overlay.
func current_distance() -> float:
	return _current_distance


func _process(delta: float) -> void:
	if _camera == null or left_fighter == null or right_fighter == null:
		return

	var a := left_fighter.body_position
	var b := right_fighter.body_position
	var midpoint := (a + b) * 0.5
	var separation := absf(a.x - b.x)

	# Pull back as the fighters separate, but never so far that a fighter
	# leaves the frame.
	var target_distance := clampf(6.0 + separation * 0.85, 6.0, 13.5)
	var target_height := clampf(2.1 + separation * 0.10, 2.1, 3.4)
	var target_look := Vector3(midpoint.x, 1.05, 0.0)

	_current_distance = lerpf(_current_distance, target_distance, clampf(delta * 3.2, 0.0, 1.0))
	_current_height = lerpf(_current_height, target_height, clampf(delta * 3.2, 0.0, 1.0))
	_current_look = _current_look.lerp(target_look, clampf(delta * 5.0, 0.0, 1.0))

	var shake := Vector3.ZERO
	if _shake_time > 0.0:
		_shake_time -= delta
		var amount := _shake_amount * clampf(_shake_time / 0.25, 0.0, 1.0)
		shake = Vector3(
			randf_range(-amount, amount), randf_range(-amount, amount), randf_range(-amount, amount)
		)
		_shake_amount = 0.0

	_camera.position = Vector3(_current_look.x, _current_height, _current_distance) + shake
	_camera.look_at(_current_look + shake * 0.4, Vector3.UP)
