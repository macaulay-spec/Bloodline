class_name Arena

extends Node3D
## A fighting arena built procedurally from the arena data.
##
## Every arena is a floor, a back wall, side bounds and a lighting rig.
## The camera must never lose the combatants, so the arena is sized to the
## fighting area rather than the other way around.

## The arena definition.
var arena_data: Dictionary = {}

var _floor_mesh: MeshInstance3D = null

var _wall_mesh: MeshInstance3D = null

var _key_light: DirectionalLight3D = null

var _rim_light: DirectionalLight3D = null


func build(arena_id: String) -> void:
	arena_data = ContentDB.get_arena(arena_id)
	if arena_data.is_empty():
		arena_data = ContentDB.get_arena("meridian_hall")
	_build_environment()
	_build_floor()
	_build_walls()
	_build_lights()
	_build_props()


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "Environment"
	var env := Environment.new()
	var sky_color: Array = arena_data.get("fog_color", [0.06, 0.07, 0.1])
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(float(sky_color[0]), float(sky_color[1]), float(sky_color[2]), 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var ambient: Array = arena_data.get("ambient_color", [0.25, 0.28, 0.35])
	env.ambient_light_color = Color(float(ambient[0]), float(ambient[1]), float(ambient[2]), 1.0)
	env.ambient_light_energy = float(arena_data.get("ambient_energy", 0.9))
	env.fog_enabled = true
	env.fog_light_color = Color(float(sky_color[0]), float(sky_color[1]), float(sky_color[2]), 1.0)
	env.fog_density = float(arena_data.get("fog_density", 0.03))
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)


func _build_floor() -> void:
	var size_array: Array = arena_data.get("floor_size", [22.0, 9.0])
	var floor_size := Vector3(float(size_array[0]), 0.2, float(size_array[1]))
	var box := BoxMesh.new()
	box.size = floor_size
	_floor_mesh = MeshInstance3D.new()
	_floor_mesh.name = "Floor"
	_floor_mesh.mesh = box
	_floor_mesh.position = Vector3(0.0, -0.1, 0.0)
	var mat := StandardMaterial3D.new()
	var floor_color: Array = arena_data.get("floor_color", [0.16, 0.17, 0.2])
	mat.albedo_color = Color(
		float(floor_color[0]), float(floor_color[1]), float(floor_color[2]), 1.0
	)
	mat.roughness = 0.82
	mat.metallic = 0.05
	_floor_mesh.material_override = mat
	add_child(_floor_mesh)


func _build_walls() -> void:
	var wall_height := float(arena_data.get("wall_height", 7.0))
	var size_array: Array = arena_data.get("floor_size", [22.0, 9.0])
	var wall_color: Array = arena_data.get("wall_color", [0.1, 0.11, 0.14])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(float(wall_color[0]), float(wall_color[1]), float(wall_color[2]), 1.0)
	mat.roughness = 0.9

	var back := BoxMesh.new()
	back.size = Vector3(float(size_array[0]), wall_height, 0.4)
	_wall_mesh = MeshInstance3D.new()
	_wall_mesh.name = "BackWall"
	_wall_mesh.mesh = back
	_wall_mesh.position = Vector3(0.0, wall_height * 0.5, -float(size_array[1]) * 0.5)
	_wall_mesh.material_override = mat
	add_child(_wall_mesh)

	# Side walls frame the fighting area without blocking the camera.
	for side in [-1.0, 1.0]:
		var side_mesh := BoxMesh.new()
		side_mesh.size = Vector3(0.4, wall_height, float(size_array[1]))
		var side_wall := MeshInstance3D.new()
		side_wall.name = "SideWall"
		side_wall.mesh = side_mesh
		side_wall.position = Vector3(side * float(size_array[0]) * 0.5, wall_height * 0.5, 0.0)
		side_wall.material_override = mat
		add_child(side_wall)


func _build_lights() -> void:
	_key_light = DirectionalLight3D.new()
	_key_light.name = "KeyLight"
	var key_color: Array = arena_data.get("key_light_color", [0.9, 0.95, 1.0])
	_key_light.light_color = Color(
		float(key_color[0]), float(key_color[1]), float(key_color[2]), 1.0
	)
	_key_light.light_energy = float(arena_data.get("key_light_energy", 1.6))
	_key_light.rotation_degrees = Vector3(-52.0, 38.0, 0.0)
	_key_light.shadow_enabled = true
	add_child(_key_light)

	_rim_light = DirectionalLight3D.new()
	_rim_light.name = "RimLight"
	var rim_color: Array = arena_data.get("rim_light_color", [0.4, 0.7, 1.0])
	_rim_light.light_color = Color(
		float(rim_color[0]), float(rim_color[1]), float(rim_color[2]), 1.0
	)
	_rim_light.light_energy = float(arena_data.get("rim_light_energy", 1.0))
	_rim_light.rotation_degrees = Vector3(-14.0, -145.0, 0.0)
	_rim_light.shadow_enabled = false
	add_child(_rim_light)


## Arena dressing. Kept simple and non-interactive: the fighters are the
## focus and nothing in the arena may obscure them.
func _build_props() -> void:
	var accent: Array = arena_data.get("accent_color", [0.3, 0.6, 0.8])
	var accent_color := Color(float(accent[0]), float(accent[1]), float(accent[2]), 1.0)
	var emissive := StandardMaterial3D.new()
	emissive.albedo_color = accent_color
	emissive.emission_enabled = true
	emissive.emission = accent_color
	emissive.emission_energy_multiplier = 1.6

	var size_array: Array = arena_data.get("floor_size", [22.0, 9.0])
	var depth := float(size_array[1]) * 0.5

	# A pair of glowing boundary strips mark the edges of the fighting area.
	for side in [-1.0, 1.0]:
		var strip := BoxMesh.new()
		strip.size = Vector3(0.12, 0.06, float(size_array[1]) * 0.8)
		var strip_mesh := MeshInstance3D.new()
		strip_mesh.name = "BoundaryStrip"
		strip_mesh.mesh = strip
		strip_mesh.position = Vector3(side * CombatConstants.ARENA_HALF_WIDTH, 0.02, 0.0)
		strip_mesh.material_override = emissive
		add_child(strip_mesh)

	# A back wall band, so the arena reads as a place rather than a void.
	var band := BoxMesh.new()
	band.size = Vector3(float(size_array[0]), 0.1, 0.06)
	var band_mesh := MeshInstance3D.new()
	band_mesh.name = "BackBand"
	band_mesh.mesh = band
	band_mesh.position = Vector3(0.0, 1.1, -depth + 0.25)
	band_mesh.material_override = emissive
	add_child(band_mesh)
