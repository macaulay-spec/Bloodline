"""Renders the in-game screenshots of the BLOODLINE roster.

    LD_LIBRARY_PATH=/tmp/xstub python tools/blender/make_screenshots.py

Produces:
    Game/assets/screenshots/<id>.png   one 16:9 shot per fighter
    Game/assets/screenshots/roster.png  the whole roster lined up

The shots are rendered from the same rig, the same body, the same costume
bake and the same idle clip the game loads, inside a reconstruction of the
arena built from Game/data/arenas.json, and framed with the same camera the
match camera uses.  What the player sees in the menu is therefore what the
fighter actually looks like in the ring.
"""

import json
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import bloodline_anim as anim  # noqa: E402
import bloodline_rig as rig  # noqa: E402
from generate_fighters import FIGHTERS, build_costume  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT_DIR = os.path.join(ROOT, "Game", "assets", "screenshots")
ARENA_PATH = os.path.join(ROOT, "Game", "data", "arenas.json")
BAKE_DIR = os.environ.get("BLOODLINE_BAKE", "/tmp/bloodline_bake")

RES_X = 1280
RES_Y = 720
SAMPLES = 64

# The match camera: 48 degrees of vertical field of view, looking slightly
# down at the fighters.  Game/scripts/combat/CameraRig.gd.
CAMERA_FOV = 48.0


def load_arena(arena_id):
    with open(ARENA_PATH, "r", encoding="utf-8") as fh:
        arenas = json.load(fh)
    return arenas[arena_id]


def _material(name, color, roughness=0.8, metallic=0.0, emission=None,
              emission_energy=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (
            emission[0], emission[1], emission[2], 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_energy
    return mat


def _box(name, size, location, material):
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=location)
    cube = bpy.context.active_object
    cube.name = name
    cube.scale = (size[0] / 2.0, size[1] / 2.0, size[2] / 2.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    cube.data.materials.append(material)
    return cube


def build_arena(arena):
    """Reconstructs the arena exactly as Game/scripts/combat/Arena.gd does."""
    floor_color = arena["floor_color"]
    wall_color = arena["wall_color"]
    accent = arena["accent_color"]
    fog = arena["fog_color"]
    ambient = arena["ambient_color"]
    floor_size = arena["floor_size"]
    wall_height = arena["wall_height"]
    depth = floor_size[1] * 0.5

    scene = bpy.context.scene

    # The world carries the ambient light and the background colour.
    world = bpy.data.worlds.new("W")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (fog[0], fog[1], fog[2], 1.0)
    bg.inputs[1].default_value = 1.0

    floor_mat = _material("Floor", floor_color, roughness=0.82, metallic=0.05)
    wall_mat = _material("Wall", wall_color, roughness=0.9)
    glow = _material("Accent", accent, roughness=0.4,
                     emission=accent, emission_energy=1.6)

    _box("Floor", (floor_size[0], 0.2, floor_size[1]), (0.0, 0.0, -0.1),
         floor_mat)
    _box("BackWall", (floor_size[0], wall_height, 0.4),
         (0.0, wall_height * 0.5, -depth), wall_mat)
    for side in (-1.0, 1.0):
        _box("SideWall", (0.4, wall_height, floor_size[1]),
             (side * floor_size[0] * 0.5, wall_height * 0.5, 0.0), wall_mat)

    # The glowing boundary strips and the band on the back wall.
    for side in (-1.0, 1.0):
        _box("BoundaryStrip", (0.12, 0.06, floor_size[1] * 0.8),
             (side * 10.0, 0.02, 0.0), glow)
    _box("BackBand", (floor_size[0], 0.1, 0.06),
         (0.0, 1.1, -depth + 0.25), glow)

    # Key and rim lights, with the same colour, energy and angle the arena
    # uses at runtime.
    for name, colour, energy, angles in (
        ("KeyLight", arena["key_light_color"], arena["key_light_energy"],
         (-52.0, 38.0, 0.0)),
        ("RimLight", arena["rim_light_color"], arena["rim_light_energy"],
         (-14.0, -145.0, 0.0)),
    ):
        data = bpy.data.lights.new(name, "SUN")
        data.energy = energy
        data.color = (colour[0], colour[1], colour[2])
        data.angle = math.radians(3.0)
        light = bpy.data.objects.new(name, data)
        scene.collection.objects.link(light)
        light.rotation_euler = tuple(math.radians(a) for a in angles)

    # A broad soft fill stands in for the engine's ambient light term.
    data = bpy.data.lights.new("AmbientFill", "AREA")
    data.energy = arena["ambient_energy"] * 420.0
    data.size = 18.0
    data.color = (ambient[0], ambient[1], ambient[2])
    fill = bpy.data.objects.new("AmbientFill", data)
    scene.collection.objects.link(fill)
    fill.location = (0.0, -1.0, 9.0)
    fill.rotation_euler = (math.radians(28.0), 0.0, 0.0)


def build_camera(location, target, lens_offset=0.0):
    data = bpy.data.cameras.new("ShotCam")
    data.lens = CAMERA_FOV
    data.sensor_width = 36.0
    data.sensor_fit = "VERTICAL"
    cam = bpy.data.objects.new("ShotCam", data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = location
    target_obj = bpy.data.objects.new("ShotTarget", None)
    bpy.context.scene.collection.objects.link(target_obj)
    target_obj.location = target
    con = cam.constraints.new("TRACK_TO")
    con.target = target_obj
    con.track_axis = "TRACK_NEGATIVE_Z"
    # The world is Z-up, so the camera's up axis has to be Z as well.
    con.up_axis = "UP_Z"
    bpy.context.scene.camera = cam
    return cam


def build_fighter(spec, reset=True):
    """Builds the fighter and leaves the rig on the idle clip."""
    if reset:
        bpy.ops.wm.read_factory_settings(use_empty=True)
    arm = rig.build_armature("Rig")
    body = rig.build_body(arm, spec["proportions"], name="Body")

    arm_mod = body.modifiers.new("Armature", "ARMATURE")
    arm_mod.object = arm
    body.parent = arm
    body.matrix_parent_inverse = arm.matrix_world.inverted()

    costume = build_costume(body, arm, spec, BAKE_DIR)
    garment_objects = [c for c in costume if c is not None]
    if garment_objects:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in garment_objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = garment_objects[0]
        bpy.ops.object.join()
        gear = bpy.context.active_object
        gear.name = "Gear"
        gear_arm = gear.modifiers.new("Armature", "ARMATURE")
        gear_arm.object = arm
        gear.parent = arm
        gear.matrix_parent_inverse = arm.matrix_world.inverted()

    # Every clip is authored on the rig.  The idle action is captured as it
    # is created, because a second fighter in the same scene gets its own
    # "idle.001" action.
    idle = None
    for clip in anim.ALL_CLIPS:
        clip(arm)
        action = arm.animation_data.action if arm.animation_data else None
        if action is not None and action.name.startswith("idle"):
            idle = action
    if idle is not None:
        arm.animation_data.action = idle
    return arm


def setup_render():
    scene = bpy.context.scene
    fast = os.environ.get("BLOODLINE_FAST", "") == "1"
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 12 if fast else SAMPLES
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 480 if fast else RES_X
    scene.render.resolution_y = 270 if fast else RES_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Filmic"
    scene.render.image_settings.file_format = "PNG"
    scene.frame_set(20)
    bpy.context.view_layer.update()


def dump_scene():
    """Prints what the render is actually going to see."""
    scene = bpy.context.scene
    print("  camera:", scene.camera.name if scene.camera else None)
    if scene.camera:
        print("  camera loc:", tuple(round(v, 3) for v in
                                     scene.camera.matrix_world.translation))
        print("  camera rot:", tuple(round(v, 3) for v in
                                     scene.camera.matrix_world.to_euler()))
    for obj in scene.objects:
        if obj.type != "MESH":
            continue
        points = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
        lo = [round(min(p[i] for p in points), 2) for i in range(3)]
        hi = [round(max(p[i] for p in points), 2) for i in range(3)]
        print("  mesh %-16s hide_render=%s lo=%s hi=%s" % (
            obj.name, obj.hide_render, lo, hi))


def render_to(path):
    bpy.context.scene.render.filepath = os.path.abspath(path)
    bpy.ops.render.render(write_still=True)
    print("    wrote %s" % path)


def shoot_fighter(fighter_id, spec, arena):
    print("=== screenshot: %s ===" % fighter_id)
    build_fighter(spec)
    build_arena(arena)
    setup_render()
    # The match camera looks at the midpoint of the two fighters, so a solo
    # shot sits a little closer than the two-fighter framing.
    build_camera((0.85, 1.95, 4.35), (0.0, 0.98, 0.0))
    os.makedirs(OUT_DIR, exist_ok=True)
    dump_scene()
    render_to(os.path.join(OUT_DIR, fighter_id + ".png"))


def shoot_roster(arena):
    """The whole roster in one arena, for the README."""
    print("=== screenshot: roster ===")
    bpy.ops.wm.read_factory_settings(use_empty=True)

    order = list(FIGHTERS.keys())
    spacing = 2.35
    start = -(len(order) - 1) * spacing * 0.5
    for index, fighter_id in enumerate(order):
        spec = FIGHTERS[fighter_id]
        arm = build_fighter(spec, reset=False)
        arm.location = (start + index * spacing, 0.0, 0.0)
        print("    placed %s" % fighter_id)

    build_arena(arena)
    setup_render()
    bpy.context.scene.frame_set(20)
    bpy.context.view_layer.update()

    # Frame the line-up.
    width = len(order) * spacing
    distance = max(10.0, width * 1.45)
    build_camera((0.0, 3.4, distance), (0.0, 1.0, 0.0))
    os.makedirs(OUT_DIR, exist_ok=True)
    render_to(os.path.join(OUT_DIR, "roster.png"))


def main():
    os.makedirs(BAKE_DIR, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    arena = load_arena("circuit_pit")

    only = os.environ.get("BLOODLINE_ONLY", "")
    for fighter_id, spec in FIGHTERS.items():
        if only and fighter_id != only:
            continue
        shoot_fighter(fighter_id, spec, arena)

    if not only:
        shoot_roster(arena)


if __name__ == "__main__":
    main()
