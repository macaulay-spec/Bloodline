"""Generates the BLOODLINE fighter roster as glTF files for Godot.

Run inside Blender (bpy module):
    LD_LIBRARY_PATH=/tmp/xstub python tools/blender/generate_fighters.py

Each fighter is built from:
  * the shared bone hierarchy (bloodline_rig)
  * fighter-specific proportions
  * fighter-specific costume geometry parented to the rig
  * the shared animation set (bloodline_anim)

Output: Game/assets/characters/<id>.glb  (skinned mesh + skeleton + clips)
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

OUT_DIR = os.environ.get(
    "BLOODLINE_OUT",
    os.path.join(HERE, "..", "..", "Game", "assets", "characters"),
)

# --- Roster definition -----------------------------------------------------
# proportions: height/bulk/torso/limb scales applied to the shared cage.
FIGHTERS = {
    "unbound": {
        "proportions": {"height": 1.0, "bulk": 1.0, "torso": 1.0, "limb": 1.0},
        "skin": (0.42, 0.28, 0.21),
        "cloth": (0.13, 0.15, 0.19),
        "accent": (0.25, 0.62, 0.85),
        "metal": (0.30, 0.32, 0.36),
        "weapon": "none",
        "bulk_extra": 0.0,
    },
    "nyra": {
        "proportions": {"height": 0.95, "bulk": 0.88, "torso": 0.92, "limb": 0.92},
        "skin": (0.50, 0.33, 0.25),
        "cloth": (0.20, 0.10, 0.16),
        "accent": (0.85, 0.35, 0.62),
        "metal": (0.34, 0.30, 0.34),
        "weapon": "none",
        "bulk_extra": 0.0,
    },
    "dagan": {
        "proportions": {"height": 1.10, "bulk": 1.26, "torso": 1.18, "limb": 1.20},
        "skin": (0.38, 0.25, 0.19),
        "cloth": (0.16, 0.14, 0.12),
        "accent": (0.90, 0.55, 0.18),
        "metal": (0.26, 0.25, 0.24),
        "weapon": "none",
        "bulk_extra": 0.05,
    },
    "kael": {
        "proportions": {"height": 1.02, "bulk": 1.04, "torso": 1.02, "limb": 1.04},
        "skin": (0.45, 0.30, 0.22),
        "cloth": (0.24, 0.09, 0.09),
        "accent": (0.95, 0.25, 0.20),
        "metal": (0.30, 0.28, 0.28),
        "weapon": "none",
        "bulk_extra": 0.02,
    },
    "sable": {
        "proportions": {"height": 0.99, "bulk": 0.96, "torso": 0.98, "limb": 0.98},
        "skin": (0.47, 0.34, 0.28),
        "cloth": (0.10, 0.12, 0.20),
        "accent": (0.45, 0.85, 0.72),
        "metal": (0.30, 0.33, 0.38),
        "weapon": "none",
        "bulk_extra": 0.0,
    },
    "voss": {
        "proportions": {"height": 1.12, "bulk": 1.18, "torso": 1.14, "limb": 1.14},
        "skin": (0.34, 0.24, 0.21),
        "cloth": (0.08, 0.08, 0.10),
        "accent": (0.70, 0.15, 0.35),
        "metal": (0.20, 0.20, 0.22),
        "weapon": "none",
        "bulk_extra": 0.04,
    },
}


def _bind_to_bone(obj, bone):
    """Give every vertex of obj full weight in the named bone's group.

    The glTF exporter reads vertex groups, not object parenting, so the
    costume pieces need real groups before they are joined.
    """
    vg = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
    vg.add([v.index for v in obj.data.vertices], 1.0, "REPLACE")


def _shirt(name, sections, arm, material, offset=0.02, radial=14,
           length_scale=1.0, drop=0.0, squash=1.0):
    """A garment shell fitted to the body."""
    obj, _ = rig.build_shell(name, sections, arm, offset=offset, radial=radial,
                              squash=squash, length_scale=length_scale, drop=drop)
    obj.data.materials.append(material)
    rig._assign_weights(obj, arm)
    bpy.ops.object.shade_smooth()
    return obj


def _plate(name, size, location, material, bone=None, taper=1.0):
    """A hard armour plate, weighted to a bone."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (size[0], size[1], size[2])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if taper != 1.0:
        bpy.ops.object.mode_set(mode="EDIT")
        for v in obj.data.vertices:
            if v.co.z > 0:
                v.co.x *= taper
                v.co.y *= taper
        bpy.ops.object.mode_set(mode="OBJECT")
    obj.data.materials.append(material)
    if bone:
        _bind_to_bone(obj, bone)
    return obj


def _spike(name, radius, depth, location, material, bone, vertices=6):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices, radius1=radius, radius2=radius * 0.15,
        depth=depth, location=location,
    )
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(material)
    if bone:
        _bind_to_bone(obj, bone)
    return obj


def build_costume(body, arm, spec, out_dir):
    """Fighter costume, baked into a texture over the body.

    A cube projection gives a predictable layout, and the region masks are
    evaluated per texel in 3D, so costume boundaries are smooth and every
    piece sits exactly on the fighter.
    """
    props = spec["proportions"]
    b = props["bulk"]
    h = props["height"]
    t = props["torso"]
    l = props["limb"]

    def region(name, color, roughness, metallic, features, priority):
        return {"name": name, "color": color, "roughness": roughness,
                "metallic": metallic, "features": features, "priority": priority}

    regions = [
        region("skin", spec["skin"], 0.62, 0.0, [
            {"kind": "sphere", "c": (0.0, 0.0, 0.95 * h), "r": 1.2, "falloff": 0.0,
             "priority": 0},
        ], 0),
        region("chest_plate", spec["metal"], 0.28, 0.85, [
            {"kind": "capsule", "a": (0.0, -0.090 * t, 1.28 * h),
             "b": (0.0, -0.090 * t, 1.44 * h), "r": 0.080 * b, "falloff": 0.030,
             "priority": 60},
        ], 60),
        region("belt", spec["metal"], 0.30, 0.80, [
            {"kind": "capsule", "a": (0.0, 0.0, 1.00 * h),
             "b": (0.0, 0.0, 1.05 * h), "r": 0.150 * b, "falloff": 0.022,
             "priority": 55},
        ], 55),
        region("shoulder", spec["metal"], 0.30, 0.85, [
            {"kind": "sphere", "c": (0.210 * b, 0.0, 1.44 * h),
             "r": 0.062 * b, "falloff": 0.030, "priority": 50},
            {"kind": "sphere", "c": (-0.210 * b, 0.0, 1.44 * h),
             "r": 0.062 * b, "falloff": 0.030, "priority": 50},
        ], 50),
        region("bracer", spec["metal"], 0.32, 0.80, [
            {"kind": "capsule", "a": (0.385 * b, -0.045, 1.03 * h),
             "b": (0.400 * b, -0.045, 1.24 * h), "r": 0.042 * b, "falloff": 0.020,
             "priority": 45},
            {"kind": "capsule", "a": (-0.385 * b, -0.045, 1.03 * h),
             "b": (-0.400 * b, -0.045, 1.24 * h), "r": 0.042 * b, "falloff": 0.020,
             "priority": 45},
        ], 45),
        region("shin", spec["metal"], 0.32, 0.80, [
            {"kind": "capsule", "a": (0.13 * b, -0.055, 0.30 * h),
             "b": (0.13 * b, -0.055, 0.58 * h), "r": 0.045 * b, "falloff": 0.020,
             "priority": 45},
            {"kind": "capsule", "a": (-0.13 * b, -0.055, 0.30 * h),
             "b": (-0.13 * b, -0.055, 0.58 * h), "r": 0.045 * b, "falloff": 0.020,
             "priority": 45},
        ], 45),
        region("coat", tuple(c * 0.75 for c in spec["cloth"]), 0.70, 0.05, [
            {"kind": "capsule", "a": (0.0, 0.0, 0.90 * h),
             "b": (0.0, 0.0, 1.00 * h), "r": 0.140 * b, "falloff": 0.035,
             "priority": 40},
        ], 40),
        region("tunic", spec["cloth"], 0.84, 0.0, [
            {"kind": "capsule", "a": (0.0, 0.0, 1.04 * h),
             "b": (0.0, 0.0, 1.40 * h), "r": 0.140 * b, "falloff": 0.040,
             "priority": 30},
        ], 30),
    ]

    os.makedirs(out_dir, exist_ok=True)
    colour_img, orm_img = rig.bake_region_texture(body, regions, resolution=1024,
                                                   name="Costume")
    material = bpy.data.materials.new("Costume")
    material.use_nodes = True
    nt = material.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = colour_img
    tex.location = (-600, 200)
    orm = nt.nodes.new("ShaderNodeTexImage")
    orm.image = orm_img
    orm.location = (-600, -150)
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    sep.location = (-380, -150)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(orm.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
    body.data.materials.clear()
    body.data.materials.append(material)

    # The Veil core is a separate emissive piece so it can glow.
    accent = rig.bake_veil_material("Accent", spec["accent"], spec["accent"], roughness=0.35)
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12, radius=0.046 * b, depth=0.026,
        location=(0.0, -0.128 * t, 1.34 * h), rotation=(math.radians(90), 0.0, 0.0),
    )
    core = bpy.context.active_object
    core.name = "VeilCore"
    core.data.materials.append(accent)
    _bind_to_bone(core, "Chest")
    return [core]


def build_fighter(fighter_id, spec):
    print("=== building fighter: %s ===" % fighter_id)
    bpy.ops.wm.read_factory_settings(use_empty=True)

    arm = rig.build_armature(
        "Rig", height=spec["proportions"]["height"], bulk=spec["proportions"]["bulk"]
    )
    body = rig.build_body(arm, spec["proportions"], name="Body")

    # Bind the body to the rig. Without a live Armature modifier the glTF
    # exporter treats the mesh as static, so the fighter would never deform.
    body_arm_mod = body.modifiers.new("Armature", "ARMATURE")
    body_arm_mod.object = arm
    body.parent = arm
    body.matrix_parent_inverse = arm.matrix_world.inverted()

    costume = build_costume(body, arm, spec, os.path.abspath(OUT_DIR))

    # Join the costume into one mesh, then bind it to the rig.
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

    # Author every animation clip on the shared rig.
    for clip in anim.ALL_CLIPS:
        clip(arm)
        print("    clip: %s" % arm.animation_data.action.name)

    # glTF export: the last action is the active one; Blender exports all
    # actions that have a fake user when asked.
    for action in bpy.data.actions:
        action.use_fake_user = True
    # Leave the rig on the idle clip so the exported rest pose is neutral.
    idle = bpy.data.actions.get("idle")
    if idle:
        arm.animation_data.action = idle

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.abspath(os.path.join(OUT_DIR, fighter_id + ".glb"))
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_apply=False,
        export_yup=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_frame_range=True,
        export_bake_animation=True,
        export_def_bones=False,
        export_optimize_animation_size=False,
    )
    size = os.path.getsize(out_path)
    print("    wrote %s (%d bytes)" % (out_path, size))
    return out_path


def main():
    only = os.environ.get("BLOODLINE_ONLY", "")
    for fighter_id, spec in FIGHTERS.items():
        if only and fighter_id != only:
            continue
        build_fighter(fighter_id, spec)


if __name__ == "__main__":
    main()
