"""Renders the in-game screenshots of the BLOODLINE roster.

    LD_LIBRARY_PATH=/tmp/xstub python tools/blender/make_screenshots.py

Produces:
    Game/assets/screenshots/<id>.png   one 16:9 shot per fighter
    Game/assets/screenshots/roster.png  the whole roster lined up

The shots are rendered from the exported game models themselves, inside a
reconstruction of the arena built from Game/data/arenas.json, and framed
with the same field of view the match camera uses.  What the player sees in
the menu is therefore exactly what the fighter looks like in the ring.

Axes: Blender is Z-up, the game is Y-up.  The game calls the arena width X,
the arena depth Z and the height Y; here the same numbers are used with the
height on Z and the depth on Y.
"""

import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
CHAR_DIR = os.path.join(ROOT, "Game", "assets", "characters")
OUT_DIR = os.path.join(ROOT, "Game", "assets", "screenshots")
ARENA_PATH = os.path.join(ROOT, "Game", "data", "arenas.json")

RES_X = 1280
RES_Y = 720
SAMPLES = 64

# Game/scripts/combat/CameraRig.gd: 48 degrees of vertical field of view.
GODOT_FOV = 48.0
BLENDER_SENSOR = 36.0
CAMERA_LENS = (BLENDER_SENSOR * 0.5) / math.tan(math.radians(GODOT_FOV) * 0.5)

WORLD_UP = Vector((0.0, 0.0, 1.0))


def load_arena(arena_id):
    with open(ARENA_PATH, "r", encoding="utf-8") as fh:
        arenas = json.load(fh)
    return arenas[arena_id]


def aim_at(obj, position, target):
    """Points an object's -Z axis at `target` from `position`, Z-up world."""
    obj.location = position
    forward = (Vector(target) - Vector(position)).normalized()
    right = forward.cross(WORLD_UP)
    if right.length < 1e-6:
        right = Vector((1.0, 0.0, 0.0))
    right.normalize()
    up = right.cross(forward)
    obj.rotation_euler = Matrix((right, up, -forward)).transposed().to_euler()


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
    """A box whose size is given as (width, depth, height) in Blender axes."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    cube = bpy.context.active_object
    cube.name = name
    cube.scale = (size[0], size[1], size[2])
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
    width = arena["floor_size"][0]
    depth = arena["floor_size"][1]
    wall_height = arena["wall_height"]

    scene = bpy.context.scene

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

    # The fighting floor, the back wall and the two side walls.
    _box("Floor", (width, depth, 0.2), (0.0, 0.0, -0.1), floor_mat)
    _box("BackWall", (width, 0.4, wall_height),
         (0.0, -depth * 0.5, wall_height * 0.5), wall_mat)
    for side in (-1.0, 1.0):
        _box("SideWall", (0.4, depth, wall_height),
             (side * width * 0.5, 0.0, wall_height * 0.5), wall_mat)

    # The glowing boundary strips and the band on the back wall.
    for side in (-1.0, 1.0):
        _box("BoundaryStrip", (0.12, depth * 0.8, 0.06),
             (side * 10.0, 0.0, 0.02), glow)
    _box("BackBand", (width, 0.06, 0.1),
         (0.0, -depth * 0.5 + 0.25, 1.1), glow)

    # The key light comes from the front left and above; the rim light from
    # behind the fighter, the way the arena rig places them.
    for name, colour, energy, position, target in (
        ("KeyLight", arena["key_light_color"], arena["key_light_energy"],
         (3.2, 4.2, 5.0), (0.0, 0.0, 1.0)),
        ("RimLight", arena["rim_light_color"], arena["rim_light_energy"],
         (-4.2, -3.6, 3.4), (0.0, 0.0, 1.2)),
    ):
        data = bpy.data.lights.new(name, "SUN")
        data.energy = energy
        data.color = (colour[0], colour[1], colour[2])
        data.angle = math.radians(4.0)
        light = bpy.data.objects.new(name, data)
        scene.collection.objects.link(light)
        aim_at(light, position, target)

    # A broad soft fill stands in for the engine's ambient light term.
    data = bpy.data.lights.new("AmbientFill", "AREA")
    data.energy = arena["ambient_energy"] * 500.0
    data.size = 20.0
    data.color = (ambient[0], ambient[1], ambient[2])
    fill = bpy.data.objects.new("AmbientFill", data)
    scene.collection.objects.link(fill)
    aim_at(fill, (0.0, 0.0, 9.0), (0.0, 0.0, 0.0))


def build_camera(location, target):
    data = bpy.data.cameras.new("ShotCam")
    data.lens = CAMERA_LENS
    data.sensor_width = BLENDER_SENSOR
    data.sensor_fit = "VERTICAL"
    cam = bpy.data.objects.new("ShotCam", data)
    bpy.context.scene.collection.objects.link(cam)
    aim_at(cam, location, target)
    bpy.context.scene.camera = cam
    return cam


def import_fighter(fighter_id, action_name="guard"):
    """Imports the exported game model and poses it on a clip from the game."""
    path = os.path.join(CHAR_DIR, fighter_id + ".glb")
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objects = [o for o in bpy.context.scene.objects if o not in before]

    rig_object = None
    for obj in new_objects:
        if obj.type == "ARMATURE":
            rig_object = obj
        elif obj.type == "MESH" and obj.name.startswith("Icosphere"):
            # A helper the importer leaves behind; it is not part of the
            # game model.
            bpy.data.objects.remove(obj, do_unlink=True)

    if rig_object is not None and rig_object.animation_data is not None:
        action = bpy.data.actions.get(action_name)
        if action is not None:
            rig_object.animation_data.action = action
            slots = getattr(action, "slots", None)
            if slots is not None and len(slots) > 0:
                rig_object.animation_data.action_slot = slots[0]

    if rig_object is not None:
        # The fighters are modelled facing -Y, the way they stand in the
        # ring. The camera is on the +Y side, so the rig is turned around
        # to face the lens.
        rig_object.rotation_euler = (0.0, 0.0, math.pi)
    return rig_object


def setup_render():
    scene = bpy.context.scene
    fast = os.environ.get("BLOODLINE_FAST", "") == "1"
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 12 if fast else SAMPLES
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 640 if fast else RES_X
    scene.render.resolution_y = 360 if fast else RES_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Filmic"
    scene.render.image_settings.file_format = "PNG"
    # A settled point in the pose clip.
    scene.frame_set(int(os.environ.get("BLOODLINE_FRAME", "18")))
    bpy.context.view_layer.update()


def dump_scene():
    """Prints what the render is actually going to see."""
    scene = bpy.context.scene
    depsgraph = bpy.context.evaluated_depsgraph_get()
    bpy.context.view_layer.update()
    print("  camera:", scene.camera.name if scene.camera else None)
    for obj in scene.objects:
        if obj.type != "MESH":
            continue
        evaluated = obj.evaluated_get(depsgraph)
        points = [evaluated.matrix_world @ Vector(c) for c in evaluated.bound_box]
        lo = [round(min(p[i] for p in points), 2) for i in range(3)]
        hi = [round(max(p[i] for p in points), 2) for i in range(3)]
        print("  mesh %-16s lo=%s hi=%s" % (obj.name, lo, hi))


def render_to(path):
    bpy.context.scene.render.filepath = os.path.abspath(path)
    bpy.ops.render.render(write_still=True)
    print("    wrote %s" % path)


def shoot_fighter(fighter_id, arena):
    print("=== screenshot: %s ===" % fighter_id)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import_fighter(fighter_id, os.environ.get("BLOODLINE_ACTION", "guard"))
    build_arena(arena)
    setup_render()
    # The match camera looks at the midpoint of the two fighters, so a solo
    # shot sits a little closer than the two-fighter framing.  The values
    # are (width, depth, height) to match the game's camera rig.
    cam = os.environ.get("BLOODLINE_CAM", "")
    if cam:
        loc_part, _, tgt_part = cam.partition("|")
        loc = tuple(float(v) for v in loc_part.split(","))
        tgt = tuple(float(v) for v in tgt_part.split(","))
    else:
        loc = (0.70, 3.35, 1.55)
        tgt = (0.0, 0.0, 0.92)
    build_camera(loc, tgt)
    os.makedirs(OUT_DIR, exist_ok=True)
    dump_scene()
    render_to(os.path.join(OUT_DIR, fighter_id + ".png"))


def shoot_roster(order, arena):
    """The whole roster in one arena, for the README."""
    print("=== screenshot: roster ===")
    bpy.ops.wm.read_factory_settings(use_empty=True)

    spacing = 1.40
    start = -(len(order) - 1) * spacing * 0.5
    for index, fighter_id in enumerate(order):
        rig_object = import_fighter(fighter_id, os.environ.get("BLOODLINE_ACTION", "guard"))
        if rig_object is not None:
            rig_object.location = (start + index * spacing, 0.0, 0.0)
        print("    placed %s" % fighter_id)

    build_arena(arena)
    setup_render()
    bpy.context.scene.frame_set(int(os.environ.get("BLOODLINE_FRAME", "18")))
    bpy.context.view_layer.update()

    # Frame the line-up. The camera has a 48 degree vertical field of
    # view, so it only has to stand far enough back to see the ends of
    # the line.
    width = (len(order) - 1) * spacing + 0.8
    distance = max(6.0, width * 1.15)
    build_camera((0.0, distance, 1.45), (0.0, 0.0, 0.95))
    os.makedirs(OUT_DIR, exist_ok=True)
    render_to(os.path.join(OUT_DIR, "roster.png"))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    arena = load_arena("circuit_pit")

    order = ["unbound", "nyra", "dagan", "kael", "sable", "voss"]
    order = [f for f in order if os.path.exists(os.path.join(CHAR_DIR, f + ".glb"))]

    only = os.environ.get("BLOODLINE_ONLY", "")
    roster_only = os.environ.get("BLOODLINE_ROSTER", "") == "1"
    for fighter_id in order:
        if roster_only:
            break
        if only and fighter_id != only:
            continue
        shoot_fighter(fighter_id, arena)

    if not only or roster_only:
        shoot_roster(order, arena)


if __name__ == "__main__":
    main()
