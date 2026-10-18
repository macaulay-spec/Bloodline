"""Renders the fighter portraits used on the roster and select screens.

    LD_LIBRARY_PATH=/tmp/xstub python tools/blender/make_portraits.py

Produces Game/assets/portraits/<id>.png at 512x640.

The portrait has to match the model the player sees in the match, so it is
rendered from the same rig, the same body and the same idle clip that the
game loads, rather than from a re-imported GLB.
"""

import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import bloodline_anim as anim  # noqa: E402
import bloodline_rig as rig  # noqa: E402
from generate_fighters import FIGHTERS  # noqa: E402

OUT_DIR = os.path.join(HERE, "..", "..", "Game", "assets", "portraits")


def setup_scene():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.render.resolution_x = 512
    sc.render.resolution_y = 640
    sc.render.film_transparent = False

    world = bpy.data.worlds.new("PortraitWorld")
    sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.035, 0.045, 0.075, 1.0)
    bg.inputs[1].default_value = 1.0

    # A gradient backdrop card behind the fighter.
    bpy.ops.mesh.primitive_plane_add(size=14, location=(0, 4.0, 2.2),
                                     rotation=(math.radians(90), 0.0, 0.0))
    card = bpy.context.active_object
    card.name = "Backdrop"
    mat = bpy.data.materials.new("Backdrop")
    mat.use_nodes = True
    nt = mat.node_tree
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (-400, 0)
    ramp.color_ramp.elements[0].color = (0.015, 0.02, 0.045, 1.0)
    ramp.color_ramp.elements[1].color = (0.09, 0.12, 0.21, 1.0)
    tex = nt.nodes.new("ShaderNodeTexCoord")
    tex.location = (-800, 0)
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    sep.location = (-600, 0)
    nt.links.new(tex.outputs["Generated"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
    nt.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    card.data.materials.append(mat)

    # Key, fill and rim lights, arranged for a portrait.
    for name, loc, energy, size in (
        ("Key", (2.6, -3.0, 3.2), 1600.0, 2.2),
        ("Fill", (-3.4, -2.2, 1.5), 380.0, 3.6),
        ("Rim", (-1.2, 3.2, 2.9), 1100.0, 1.5),
    ):
        light_data = bpy.data.lights.new(name, "AREA")
        light_data.energy = energy
        light_data.size = size
        light = bpy.data.objects.new(name, light_data)
        bpy.context.scene.collection.objects.link(light)
        light.location = loc
        direction = Vector((0.0, 0.0, 1.40)) - Vector(loc)
        light.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    cam_data = bpy.data.cameras.new("PortraitCam")
    cam_data.lens = 92
    cam = bpy.data.objects.new("PortraitCam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    sc.camera = cam

    target = bpy.data.objects.new("PortraitTarget", None)
    bpy.context.scene.collection.objects.link(target)
    target.location = (0.0, 0.0, 1.26)

    con = cam.constraints.new("TRACK_TO")
    con.target = target
    con.track_axis = "TRACK_NEGATIVE_Z"
    con.up_axis = "UP_Y"
    # Orbited around the fighter for a three-quarter view.
    cam.location = (2.30, -4.40, 1.42)


def build_fighter(spec):
    """Build the fighter and pose it on the idle clip."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    arm = rig.build_armature("Rig")
    body = rig.build_body(arm, spec["proportions"], name="Body")

    from generate_fighters import build_costume
    costume = build_costume(body, arm, spec,
                            os.path.abspath(os.path.join(OUT_DIR, "..")))
    garment_objects = [c for c in costume if c is not None]
    if garment_objects:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in garment_objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = garment_objects[0]
        bpy.ops.object.join()
        gear = bpy.context.active_object
        gear.name = "Gear"
        arm_mod = gear.modifiers.new("Armature", "ARMATURE")
        arm_mod.object = arm
        gear.parent = arm
        gear.matrix_parent_inverse = arm.matrix_world.inverted()

    for clip in anim.ALL_CLIPS:
        clip(arm)
    idle = bpy.data.actions.get("idle")
    if idle:
        arm.animation_data.action = idle
    return arm


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for fighter_id, spec in FIGHTERS.items():
        build_fighter(spec)
        setup_scene()
        # Frame 20 is a settled point in the idle loop.
        bpy.context.scene.frame_set(20)
        bpy.context.view_layer.update()
        out = os.path.abspath(os.path.join(OUT_DIR, fighter_id + ".png"))
        bpy.context.scene.render.filepath = out
        bpy.ops.render.render(write_still=True)
        print("portrait:", out)


if __name__ == "__main__":
    main()
