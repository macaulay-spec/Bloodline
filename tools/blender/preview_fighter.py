"""Renders preview images of a generated fighter so the art can be reviewed.

    LD_LIBRARY_PATH=/tmp/xstub python tools/blender/preview_fighter.py unbound

Produces Game/assets/preview/<id>_<view>.png
"""

import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

CHAR_DIR = os.path.join(HERE, "..", "..", "Game", "assets", "characters")
OUT_DIR = os.path.join(HERE, "..", "..", "Game", "assets", "preview")


def setup_scene(subject, ground=True):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 24
    sc.render.resolution_x = 400
    sc.render.resolution_y = 560
    sc.render.film_transparent = False

    world = bpy.data.worlds.new("W")
    sc.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.09, 1.0)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0

    if ground:
        bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
        g = bpy.context.active_object
        m = bpy.data.materials.new("Ground")
        m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = (0.11, 0.12, 0.15, 1.0)
        b.inputs["Roughness"].default_value = 0.7
        g.data.materials.append(m)

    target = bpy.data.objects.new("Target", None)
    sc.collection.objects.link(target)
    target.location = (0, 0, 1.0)

    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 70
    cam = bpy.data.objects.new("Cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    con = cam.constraints.new("TRACK_TO")
    con.target = target
    con.track_axis = "TRACK_NEGATIVE_Z"
    con.up_axis = "UP_Y"

    for name, loc, energy, size in (
        ("Key", (2.6, -3.6, 4.4), 1400, 3.5),
        ("Fill", (-3.4, -2.2, 2.2), 320, 3.0),
        ("Rim", (-1.4, 3.6, 3.2), 900, 2.5),
    ):
        ld = bpy.data.lights.new(name, "AREA")
        ld.energy = energy
        ld.size = size
        lo = bpy.data.objects.new(name, ld)
        sc.collection.objects.link(lo)
        lo.location = loc
        lo.rotation_euler = (Vector(target.location) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return cam, target


def main():
    fighter_id = sys.argv[1] if len(sys.argv) > 1 else "unbound"
    path = os.path.join(CHAR_DIR, fighter_id + ".glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    # The rig is imported as an armature with actions; drop to a neutral pose.
    for ob in bpy.context.scene.objects:
        if ob.type == "ARMATURE":
            ob.animation_data_clear()
            for act in list(ob.animation_data.action_slot.bl_rna.properties.keys()) if ob.animation_data else []:
                pass
    cam, target = setup_scene(bpy.context.scene)
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, loc in (("front", (0, -4.0, 1.0)), ("quarter", (2.6, -2.8, 1.05)),
                      ("side", (4.0, 0, 1.0)), ("back", (0, 4.0, 1.0))):
        cam.location = loc
        bpy.context.scene.render.filepath = os.path.abspath(
            os.path.join(OUT_DIR, "%s_%s.png" % (fighter_id, name)))
        bpy.ops.render.render(write_still=True)
        print("rendered", name)


if __name__ == "__main__":
    main()
