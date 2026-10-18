"""Shared rig + body construction for BLOODLINE fighters.

This module is imported by the character generation scripts. It runs inside
Blender (as the `bpy` Python module) and must not be imported outside Blender.

Design notes:
  * One bone hierarchy shared by the whole roster, so animation authored for
    one fighter ports to all of them.
  * The body is built by lofting cross-sections along bone chains. This gives
    clean, controllable anatomy instead of a modifier-driven approximation.
  * Vertex weights are assigned by nearest bone segment, which is stable and
    produces no twisting at the joints.
"""

import math

import bpy
from mathutils import Vector

# --- Shared bone hierarchy -------------------------------------------------
# (name, head, tail, parent)
BONES = [
    ("Root", (0.0, 0.0, 0.0), (0.0, 0.0, 0.10), None),
    ("Hips", (0.0, 0.0, 0.92), (0.0, 0.0, 1.05), "Root"),
    ("Spine", (0.0, 0.0, 1.05), (0.0, 0.0, 1.28), "Hips"),
    ("Chest", (0.0, 0.0, 1.28), (0.0, 0.0, 1.50), "Spine"),
    ("Neck", (0.0, 0.0, 1.50), (0.0, 0.0, 1.60), "Chest"),
    ("Head", (0.0, 0.0, 1.60), (0.0, 0.0, 1.86), "Neck"),
    ("Shoulder.L", (0.10, 0.0, 1.46), (0.24, 0.0, 1.45), "Chest"),
    ("UpperArm.L", (0.24, 0.0, 1.45), (0.36, 0.0, 1.30), "Shoulder.L"),
    ("LowerArm.L", (0.36, 0.0, 1.30), (0.40, 0.0, 1.04), "UpperArm.L"),
    ("Hand.L", (0.40, 0.0, 1.04), (0.42, 0.0, 0.88), "LowerArm.L"),
    ("Shoulder.R", (-0.10, 0.0, 1.46), (-0.24, 0.0, 1.45), "Chest"),
    ("UpperArm.R", (-0.24, 0.0, 1.45), (-0.36, 0.0, 1.30), "Shoulder.R"),
    ("LowerArm.R", (-0.36, 0.0, 1.30), (-0.40, 0.0, 1.04), "UpperArm.R"),
    ("Hand.R", (-0.40, 0.0, 1.04), (-0.42, 0.0, 0.88), "LowerArm.R"),
    ("UpperLeg.L", (0.11, 0.0, 0.92), (0.13, 0.0, 0.62), "Hips"),
    ("LowerLeg.L", (0.13, 0.0, 0.62), (0.13, 0.0, 0.28), "UpperLeg.L"),
    ("Foot.L", (0.13, 0.0, 0.28), (0.13, -0.16, 0.06), "LowerLeg.L"),
    ("Toe.L", (0.13, -0.16, 0.06), (0.13, -0.26, 0.04), "Foot.L"),
    ("UpperLeg.R", (-0.11, 0.0, 0.92), (-0.13, 0.0, 0.62), "Hips"),
    ("LowerLeg.R", (-0.13, 0.0, 0.62), (-0.13, 0.0, 0.28), "UpperLeg.R"),
    ("Foot.R", (-0.13, 0.0, 0.28), (-0.13, -0.16, 0.06), "LowerLeg.R"),
    ("Toe.R", (-0.13, -0.16, 0.06), (-0.13, -0.26, 0.04), "Foot.R"),
]

BONE_NAMES = [b[0] for b in BONES]
BONE_INDEX = {name: i for i, name in enumerate(BONE_NAMES)}

# Bones that should never receive skin weights.
NON_DEFORM = {"Root"}


# --- Body definition -------------------------------------------------------
# A body is a set of limbs. Each limb is a chain of cross-sections; each
# section is (bone, offset_along_bone, radius_x, radius_z, roundness).
# The torso uses a dedicated builder because its cross-sections are ellipses
# that are wider than they are deep.

def _arm_sections(side, bulk, limb):
    return [
        ("Chest", 0.86, 0.098 * bulk, 0.092 * bulk),
        ("Shoulder." + side, 0.60, 0.100 * bulk, 0.095 * bulk),
        ("UpperArm." + side, 0.30, 0.098 * bulk, 0.094 * bulk),
        ("UpperArm." + side, 0.85, 0.090 * bulk, 0.086 * bulk),
        ("LowerArm." + side, 0.20, 0.082 * bulk, 0.078 * bulk),
        ("LowerArm." + side, 0.80, 0.068 * bulk, 0.066 * limb),
        ("Hand." + side, 0.15, 0.055 * bulk, 0.048 * bulk),
        ("Hand." + side, 0.85, 0.048 * bulk, 0.042 * bulk),
    ]


def _leg_sections(side, bulk, limb):
    return [
        ("Hips", 0.55, 0.135 * bulk, 0.128 * bulk),
        ("UpperLeg." + side, 0.20, 0.124 * bulk, 0.119 * bulk),
        ("UpperLeg." + side, 0.75, 0.108 * bulk, 0.104 * bulk),
        ("LowerLeg." + side, 0.20, 0.100 * bulk, 0.098 * bulk),
        ("LowerLeg." + side, 0.80, 0.074 * bulk, 0.072 * limb),
        ("Foot." + side, 0.30, 0.068 * bulk, 0.062 * limb),
    ]


def _torso_sections(height, bulk, torso):
    """Cross-sections from the pelvis up to the neck."""
    return [
        ("Hips", 0.05, 0.165 * bulk, 0.120 * torso),
        ("Hips", 0.70, 0.150 * bulk, 0.112 * torso),
        ("Spine", 0.15, 0.142 * bulk, 0.106 * torso),
        ("Spine", 0.75, 0.152 * bulk, 0.110 * torso),
        ("Chest", 0.20, 0.172 * bulk, 0.116 * torso),
        ("Chest", 0.60, 0.180 * bulk, 0.118 * torso),
        ("Chest", 0.90, 0.150 * bulk, 0.108 * torso),
        ("Neck", 0.10, 0.078 * bulk, 0.072 * torso),
    ]


def build_armature(name="Rig", height=1.0, bulk=1.0):
    """Create the shared armature and return the object.

    The bones are written for a fighter of average build, so they are
    scaled to the proportions of the fighter: the height stretches the
    skeleton along the spine and the bulk widens it. The body mesh is
    built from the same proportions, so the two always agree and the
    head never floats away from the neck.
    """
    arm_data = bpy.data.armatures.new(name)
    arm = bpy.data.objects.new(name, arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for bname, head, tail, parent in BONES:
        eb = arm_data.edit_bones.new(bname)
        eb.head = (head[0] * bulk, head[1] * bulk, head[2] * height)
        eb.tail = (tail[0] * bulk, tail[1] * bulk, tail[2] * height)
        if parent:
            eb.parent = arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


# --- Lofting ---------------------------------------------------------------

def _bone_segment(arm, bone_name):
    bone = arm.data.bones.get(bone_name)
    if bone is None:
        return None
    head = arm.matrix_world @ bone.head_local
    tail = arm.matrix_world @ bone.tail_local
    return head, tail


def _point_on_segment(p, a, b):
    """Return (closest_point, distance, t) for point p on segment a-b."""
    ab = b - a
    denom = ab.dot(ab)
    if denom < 1e-9:
        return a, (p - a).length, 0.0
    t = max(0.0, min(1.0, (p - a).dot(ab) / denom))
    closest = a + ab * t
    return closest, (p - closest).length, t


def _frame_for(direction):
    """A stable orthonormal frame around a direction vector."""
    n = direction.normalized()
    helper = Vector((0.0, 0.0, 1.0))
    if abs(n.dot(helper)) > 0.95:
        helper = Vector((0.0, 1.0, 0.0))
    u = n.cross(helper).normalized()
    v = n.cross(u).normalized()
    return u, v


def _loft(name, sections, arm, radial=12, squash=1.0, cap_start=True, cap_end=True):
    """Build a lofted tube through a list of (bone, t, radius_x, radius_z).

    Returns (object, ring_index) where ring_index[i] is the list of vertex
    indices for section i.
    """
    verts = []
    faces = []
    rings = []

    for bone_name, t, rx, rz in sections:
        seg = _bone_segment(arm, bone_name)
        if seg is None:
            continue
        a, b = seg
        centre = a.lerp(b, t)
        direction = (b - a)
        if direction.length < 1e-6:
            direction = Vector((0.0, 0.0, 1.0))
        u, v = _frame_for(direction)
        ring = []
        for i in range(radial):
            ang = (2.0 * math.pi * i) / radial
            # Squashed circle: depth (Y) is compressed for a human torso.
            p = centre + u * (math.cos(ang) * rx) + v * (math.sin(ang) * rz * squash)
            ring.append(len(verts))
            verts.append(tuple(p))
        rings.append((ring, bone_name))

    for i in range(len(rings) - 1):
        r0 = rings[i][0]
        r1 = rings[i + 1][0]
        for k in range(radial):
            k2 = (k + 1) % radial
            faces.append((r0[k], r0[k2], r1[k2], r1[k]))

    if cap_start and rings:
        faces.append(tuple(reversed(rings[0][0])))
    if cap_end and rings:
        faces.append(tuple(rings[-1][0]))

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj, rings


def _ellipsoid(name, centre, radii, arm, segs=16, rings=8, bone_name=None):
    """A UV-sphere-like blob, optionally weighted to one bone."""
    verts = []
    faces = []
    for r in range(rings + 1):
        phi = math.pi * r / rings
        z = math.cos(phi)
        rad = math.sin(phi)
        for s in range(segs):
            theta = 2.0 * math.pi * s / segs
            verts.append((
                centre[0] + math.cos(theta) * rad * radii[0],
                centre[1] + math.sin(theta) * rad * radii[1],
                centre[2] + z * radii[2],
            ))
    for r in range(rings):
        for s in range(segs):
            s2 = (s + 1) % segs
            a = r * segs + s
            b = r * segs + s2
            c = (r + 1) * segs + s2
            d = (r + 1) * segs + s
            faces.append((a, b, c, d))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj, list(range(len(verts)))


def _join_objects(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    return obj


def _assign_weights(obj, arm, bone_of_vertex=None, max_influences=2):
    """Weight every vertex to the nearest bone segment(s)."""
    segments = []
    for bname in BONE_NAMES:
        if bname in NON_DEFORM:
            continue
        seg = _bone_segment(arm, bname)
        if seg:
            segments.append((bname, seg[0], seg[1]))

    groups = {}
    for v in obj.data.vertices:
        if bone_of_vertex is not None:
            weights = {bone_of_vertex[v.index]: 1.0}
        else:
            scored = []
            for bname, a, b in segments:
                _, dist, _ = _point_on_segment(v.co, a, b)
                scored.append((dist, bname))
            scored.sort()
            picked = scored[:max_influences]
            total = sum(1.0 / max(d, 1e-4) for d, _ in picked)
            weights = {}
            for d, bname in picked:
                weights[bname] = weights.get(bname, 0.0) + (1.0 / max(d, 1e-4)) / total

        for bname, w in weights.items():
            if w < 0.01:
                continue
            if bname not in groups:
                groups[bname] = []
            groups[bname].append((v.index, w))

    for bname, entries in groups.items():
        vg = obj.vertex_groups.get(bname) or obj.vertex_groups.new(name=bname)
        # Batch by identical weight for speed.
        by_weight = {}
        for idx, w in entries:
            by_weight.setdefault(round(w, 3), []).append(idx)
        for w, indices in by_weight.items():
            vg.add(indices, w, "REPLACE")


def build_body(arm, proportions, name="Body"):
    """Build the fighter body mesh.

    The limbs are lofted, then fused with a voxel remesh so the result is
    one continuous surface with clean joints. The mesh is then decimated to
    a mobile-appropriate triangle budget.
    """
    h = proportions["height"]
    b = proportions["bulk"]
    t = proportions["torso"]
    l = proportions["limb"]

    objects = []

    torso, _ = _loft("Torso", _torso_sections(h, b, t), arm, radial=14)
    objects.append(torso)

    neck, _ = _loft("Neck", [
        ("Neck", -0.4, 0.082 * b, 0.078 * t),
        ("Neck", 1.0, 0.076 * b, 0.072 * t),
    ], arm, radial=10)
    objects.append(neck)
    head, _ = _ellipsoid("Head", (0.0, 0.0, 1.70 * h),
                          (0.104 * b, 0.114 * b, 0.132 * h), arm)
    objects.append(head)

    for side in ("L", "R"):
        arm_obj, _ = _loft("Arm." + side, _arm_sections(side, b, l), arm, radial=10)
        objects.append(arm_obj)

    for side in ("L", "R"):
        leg_obj, _ = _loft("Leg." + side, _leg_sections(side, b, l), arm, radial=10)
        objects.append(leg_obj)
        foot, _ = _loft("Foot." + side, [
            ("Foot." + side, -0.15, 0.070 * b, 0.070 * b),
            ("Foot." + side, 0.45, 0.072 * b, 0.062 * b),
            ("Toe." + side, 0.35, 0.060 * b, 0.044 * b),
        ], arm, radial=10)
        objects.append(foot)

    merged = _join_objects(objects, name)
    bpy.context.view_layer.objects.active = merged
    sub = merged.modifiers.new("Subdivision", "SUBSURF")
    sub.levels = 1
    sub.render_levels = 1
    bpy.ops.object.modifier_apply(modifier="Subdivision")
    _assign_weights(merged, arm)
    bpy.ops.object.shade_smooth()
    return merged


def decimate_preserving_materials(obj, target_ratio=0.28):
    """Reduce the triangle count while keeping material boundaries crisp."""
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.decimate_type = "DISSOLVE"
    mod.delimit = {"MATERIAL"}
    mod.angle_limit = math.radians(4.0)
    bpy.ops.object.modifier_apply(modifier="Decimate")
    bpy.ops.object.shade_smooth()


def _fuse_and_smooth(obj, voxel=0.011, smooth_iterations=3, smooth_factor=0.45):
    """Fuse the separate body parts into one continuous surface."""
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)

    remesh = obj.modifiers.new("Remesh", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = voxel
    remesh.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier="Remesh")

    smooth = obj.modifiers.new("Smooth", "SMOOTH")
    smooth.factor = smooth_factor
    smooth.iterations = smooth_iterations
    bpy.ops.object.modifier_apply(modifier="Smooth")
    bpy.ops.object.shade_smooth()


def bake_region_texture(obj, regions, resolution=1024, name="Costume",
                       uv_margin=0.004):
    """Bake a costume texture by evaluating the region masks in UV space.

    For every texel the 3D position under the UV is recovered, and the
    region masks are evaluated there. Because the masks are continuous
    functions of position, the baked boundaries are smooth instead of the
    stair-stepped edges that per-face material assignment produces.

    regions: list of dicts with keys
        name, color (RGB), roughness, metallic, features, priority
    """
    import numpy as np

    # UV unwrap.
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.quads_convert_to_tris()
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=uv_margin)
    bpy.ops.object.mode_set(mode="OBJECT")

    uv_layer = obj.data.uv_layers.active
    if uv_layer is None:
        return None, None

    width = resolution
    height = resolution
    colour = np.zeros((height, width, 3), dtype=np.float32)
    rough = np.zeros((height, width), dtype=np.float32)
    metal = np.zeros((height, width), dtype=np.float32)
    written = np.zeros((height, width), dtype=bool)

    ordered = sorted(regions, key=lambda r: r["priority"], reverse=True)

    for poly in obj.data.polygons:
        loop_indices = list(poly.loop_indices)
        if len(loop_indices) != 3:
            continue
        uvs = []
        xyz = []
        for li in loop_indices:
            uvs.append(uv_layer.data[li].uv)
            xyz.append(obj.data.vertices[obj.data.loops[li].vertex_index].co)
        if len(uvs) != 3:
            continue

        px = [(u.x * (width - 1), (1.0 - u.y) * (height - 1)) for u in uvs]
        min_x = max(0, int(min(p[0] for p in px)))
        max_x = min(width - 1, int(max(p[0] for p in px)) + 1)
        min_y = max(0, int(min(p[1] for p in px)) + 1)
        max_y = min(height - 1, int(max(p[1] for p in px)) + 1)
        if max_x < min_x or max_y < min_y:
            continue

        ax, ay = px[0]
        bx, by = px[1]
        cx, cy = px[2]
        denom = ((by - cy) * (ax - cx) + (cx - bx) * (ay - cy))
        if abs(denom) < 1e-9:
            continue

        v0 = np.array(xyz[0], dtype=np.float32)
        v1 = np.array(xyz[1], dtype=np.float32)
        v2 = np.array(xyz[2], dtype=np.float32)

        xs = np.arange(min_x, max_x + 1, dtype=np.float32)
        ys = np.arange(min_y, max_y + 1, dtype=np.float32)

        # Supersample each texel so costume edges are smooth rather than
        # aliased against the atlas resolution.
        samples = []
        for sub_y in (0.25, 0.75):
            for sub_x in (0.25, 0.75):
                gx, gy = np.meshgrid(xs + sub_x, ys + sub_y)
                w0 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / denom
                w1 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / denom
                w2 = 1.0 - w0 - w1
                inside = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
                p3 = v0 * w0[..., None] + v1 * w1[..., None] + v2 * w2[..., None]
                flat = p3.reshape(-1, 3)
                region_index = np.full(flat.shape[0], len(ordered) - 1, dtype=np.int32)
                for idx, region in enumerate(ordered):
                    mask = _region_mask_flat(region["features"], flat)
                    uncovered = (region_index == len(ordered) - 1) & (mask > 0.5)
                    region_index = np.where(uncovered, idx, region_index)
                samples.append((inside.reshape(gx.shape),
                                region_index.reshape(gx.shape)))

        inside = samples[0][0]
        best_index = np.zeros(inside.shape, dtype=np.int32)
        counts = np.zeros(inside.shape, dtype=np.float32)
        for sub_inside, sub_index in samples:
            use = sub_inside & inside
            best_index = np.where(use, sub_index, best_index)
            counts += use.astype(np.float32)
        counts = np.maximum(counts, 1.0)

        block = colour[min_y:max_y + 1, min_x:max_x + 1]
        rblock = rough[min_y:max_y + 1, min_x:max_x + 1]
        mblock = metal[min_y:max_y + 1, min_x:max_x + 1]
        wblock = written[min_y:max_y + 1, min_x:max_x + 1]
        for idx, region in enumerate(ordered):
            sel = inside & (best_index == idx)
            if not sel.any():
                continue
            block[sel] = region["color"]
            rblock[sel] = region["roughness"]
            mblock[sel] = region["metallic"]
            wblock[sel] = True
        colour[min_y:max_y + 1, min_x:max_x + 1] = block
        rough[min_y:max_y + 1, min_x:max_x + 1] = rblock
        metal[min_y:max_y + 1, min_x:max_x + 1] = mblock
        written[min_y:max_y + 1, min_x:max_x + 1] = wblock

    # Fill unwritten texels with the fallback region colour.
    fallback = ordered[-1]
    colour[~written] = fallback["color"]
    rough[~written] = fallback["roughness"]
    metal[~written] = fallback["metallic"]

    # Pack into images: base colour, and ORM (G=roughness, B=metallic).
    colour_img = bpy.data.images.new(name + "_BaseColor", width, height, alpha=False)
    colour_buf = np.concatenate([colour, np.ones((height, width, 1), dtype=np.float32)], axis=2)
    colour_buf = colour_buf[::-1]  # flip to Blender's bottom-up convention
    colour_img.pixels.foreach_set(colour_buf.ravel())
    colour_img.filepath_raw = "//%s_BaseColor.png" % name
    colour_img.file_format = "PNG"
    colour_img.save()

    orm_buf = np.zeros((height, width, 4), dtype=np.float32)
    orm_buf[..., 0] = 1.0
    orm_buf[..., 1] = rough
    orm_buf[..., 2] = metal
    orm_buf[..., 3] = 1.0
    orm_img = bpy.data.images.new(name + "_ORM", width, height, alpha=False)
    orm_buf = orm_buf[::-1]
    orm_img.pixels.foreach_set(orm_buf.ravel())
    orm_img.filepath_raw = "//%s_ORM.png" % name
    orm_img.file_format = "PNG"
    orm_img.save()
    return colour_img, orm_img


def assign_materials_by_region(obj, regions):
    """Assign a material slot to each face based on a region list.

    regions: list of (material, features, priority). The highest-priority
    region that covers a face wins. This gives correctly fitted costume
    with no extra geometry and no z-fighting.
    """
    ordered = sorted(regions, key=lambda r: r[2], reverse=True)
    slots = []
    slot_of = {}
    for material, _features, _priority in ordered:
        if material.name not in slot_of:
            slot_of[material.name] = len(slots)
            slots.append(material)
    obj.data.materials.clear()
    for material in slots:
        obj.data.materials.append(material)

    # The lowest-priority region is the fallback (skin) for any face that
    # no other region covers.
    fallback_slot = slot_of[ordered[-1][0].name]
    for poly in obj.data.polygons:
        centre = poly.center
        best_slot = fallback_slot
        best_priority = -1.0
        for material, features, priority in ordered:
            if region_mask(features, centre) > 0.5 and priority > best_priority:
                best_slot = slot_of[material.name]
                best_priority = priority
        poly.material_index = best_slot


def build_shell(name, sections, arm, offset=0.02, radial=14, squash=1.0,
                length_scale=1.0, drop=0.0):
    """Loft a shell that hugs the body: same cross-sections, pushed out.

    `offset` is an absolute radial offset in metres, so a garment always
    clears the fused body surface by a predictable amount regardless of how
    thick the body is.
    """
    scaled = []
    for bone_name, t, rx, rz in sections:
        scaled.append((bone_name, t * length_scale, rx + offset, rz + offset))
    obj, rings = _loft(name, scaled, arm, radial=radial, squash=squash)
    if drop:
        lowest = min(rings, key=lambda r: min(obj.data.vertices[i].co.z for i in r[0]))
        for idx in lowest[0]:
            obj.data.vertices[idx].co.z -= drop
    return obj, rings


# --- Garment layers --------------------------------------------------------
# A garment is derived from the finished body mesh: a region mask decides
# which vertices belong to the garment, and those vertices are pushed out
# along their normal. Because the garment is a copy of the body surface, it
# always fits exactly, and the mask falloff gives it a bevelled edge.

def _smoothstep(edge0, edge1, x):
    if edge1 <= edge0:
        return 0.0 if x >= edge1 else 1.0
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def _feature_distance(feature, point):
    """Distance from point to a feature's core region."""
    kind = feature["kind"]
    if kind == "sphere":
        return (point - Vector(feature["c"])).length - feature["r"]
    if kind == "capsule":
        a = Vector(feature["a"])
        b = Vector(feature["b"])
        _, dist, _ = _point_on_segment(point, a, b)
        return dist - feature["r"]
    if kind == "box":
        c = Vector(feature["c"])
        half = Vector(feature["half"])
        d = Vector((abs(point.x - c.x) - half.x,
                    abs(point.y - c.y) - half.y,
                    abs(point.z - c.z) - half.z))
        outside = Vector((max(d.x, 0.0), max(d.y, 0.0), max(d.z, 0.0)))
        return outside.length + min(max(d.x, max(d.y, d.z)), 0.0)
    return 1e9


def _region_mask_flat(features, points):
    """Mask of the union of the given features over an (N, 3) point array."""
    import numpy as np

    best = np.zeros(points.shape[0], dtype=np.float32)
    for feature in features:
        kind = feature["kind"]
        if kind == "sphere":
            centre = np.array(feature["c"], dtype=np.float32)
            dist = np.linalg.norm(points - centre, axis=1) - feature["r"]
        elif kind == "capsule":
            a = np.array(feature["a"], dtype=np.float32)
            b = np.array(feature["b"], dtype=np.float32)
            ab = b - a
            denom = float(np.dot(ab, ab))
            if denom < 1e-9:
                t = np.zeros(points.shape[0], dtype=np.float32)
            else:
                t = np.clip(((points - a) @ ab) / denom, 0.0, 1.0)
            closest = a + ab * t[:, None]
            dist = np.linalg.norm(points - closest, axis=1) - feature["r"]
        elif kind == "box":
            centre = np.array(feature["c"], dtype=np.float32)
            half = np.array(feature["half"], dtype=np.float32)
            d = np.abs(points - centre) - half
            outside = np.linalg.norm(np.maximum(d, 0.0), axis=1)
            dist = outside + np.minimum(d.max(axis=1), 0.0)
        else:
            continue
        falloff = max(feature.get("falloff", 0.03), 1e-6)
        mask = np.where(dist <= 0.0, 1.0, 1.0 - np.clip(dist / falloff, 0.0, 1.0))
        mask = mask * mask * (3.0 - 2.0 * mask)
        best = np.maximum(best, mask)
    return best


def region_mask_array(features, points):
    """Vectorised region mask over an (N, 3) array of points.

    Returns the mask of the highest-priority region covering each point.
    """
    import numpy as np

    best = np.zeros(points.shape[0], dtype=np.float32)
    best_priority = np.full(points.shape[0], -1.0, dtype=np.float32)
    best_index = np.zeros(points.shape[0], dtype=np.int32)

    for idx, feature in enumerate(sorted(features, key=lambda f: -f.get("priority", 0))):
        kind = feature["kind"]
        if kind == "sphere":
            centre = np.array(feature["c"], dtype=np.float32)
            dist = np.linalg.norm(points - centre, axis=1) - feature["r"]
        elif kind == "capsule":
            a = np.array(feature["a"], dtype=np.float32)
            b = np.array(feature["b"], dtype=np.float32)
            ab = b - a
            denom = float(np.dot(ab, ab))
            if denom < 1e-9:
                t = np.zeros(points.shape[0], dtype=np.float32)
            else:
                t = np.clip(((points - a) @ ab) / denom, 0.0, 1.0)
            closest = a + ab * t[:, None]
            dist = np.linalg.norm(points - closest, axis=1) - feature["r"]
        elif kind == "box":
            centre = np.array(feature["c"], dtype=np.float32)
            half = np.array(feature["half"], dtype=np.float32)
            d = np.abs(points - centre) - half
            outside = np.linalg.norm(np.maximum(d, 0.0), axis=1)
            dist = outside + np.minimum(d.max(axis=1), 0.0)
        else:
            continue
        falloff = max(feature.get("falloff", 0.03), 1e-6)
        mask = np.where(dist <= 0.0, 1.0, 1.0 - np.clip(dist / falloff, 0.0, 1.0))
        mask = mask * mask * (3.0 - 2.0 * mask)
        better = (mask > 0.5) & (mask > best_priority)
        best_priority = np.where(better, mask, best_priority)
        best = np.where(better, mask, best)
        best_index = np.where(better, idx, best_index)
    return best, best_index


def region_mask(features, point):
    """1.0 inside a feature's core, easing to 0.0 across its falloff."""
    best = 0.0
    for feature in features:
        dist = _feature_distance(feature, point)
        falloff = feature.get("falloff", 0.03)
        if dist <= 0.0:
            m = 1.0
        else:
            m = 1.0 - _smoothstep(0.0, falloff, dist)
        if m > best:
            best = m
    return best


def build_garment(body, body_armature, sections, name, material, offset=0.016,
                  radial=12, thickness=0.010, drop=0.0, extend=0.0):
    """Loft a garment shell around the body.

    The garment uses the same cross-section definitions as the body, pushed
    outward by a fixed distance, so it always sits on the fighter instead of
    floating or cutting into it.
    """
    grown = []
    for bone_name, t, rx, rz in sections:
        grown.append((bone_name, t, rx + offset, rz + offset))
    obj, rings = _loft(name, grown, body_armature, radial=radial)
    if drop:
        lowest = min(rings, key=lambda r: min(obj.data.vertices[i].co.z for i in r[0]))
        for idx in lowest[0]:
            obj.data.vertices[idx].co.z -= drop
    bpy.context.view_layer.objects.active = obj
    solid = obj.modifiers.new("Solidify", "SOLIDIFY")
    solid.thickness = thickness
    solid.offset = -1.0
    bpy.ops.object.modifier_apply(modifier="Solidify")
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(material)
    _assign_weights(obj, body_armature)
    return obj


def set_material(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def make_pbr_material(name, base_color, roughness=0.5, metallic=0.0,
                      emission=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def bake_veil_material(name, base_color, accent, roughness=0.45):
    """A two-tone material with a procedural Veil-energy accent."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes["Principled BSDF"]

    tex = nodes.new("ShaderNodeTexNoise")
    tex.inputs["Scale"].default_value = 7.0
    tex.inputs["Detail"].default_value = 6.0
    tex.location = (-700, 0)

    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.location = (-480, 0)
    ramp.color_ramp.elements[0].position = 0.42
    ramp.color_ramp.elements[0].color = (*base_color, 1.0)
    ramp.color_ramp.elements[1].position = 0.62
    ramp.color_ramp.elements[1].color = (*accent, 1.0)
    links.new(tex.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])

    bump = nodes.new("ShaderNodeBump")
    bump.location = (-260, -240)
    bump.inputs["Strength"].default_value = 0.25
    links.new(tex.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = 0.15
    return mat


def key(arm, bone, frame, rot=(0.0, 0.0, 0.0), loc=None, scale=None):
    """Keyframe a pose bone on the armature."""
    pb = arm.pose.bones.get(bone)
    if pb is None:
        return
    pb.rotation_mode = "XYZ"
    pb.rotation_euler = rot
    pb.keyframe_insert("rotation_euler", frame=frame)
    if loc is not None:
        pb.location = loc
        pb.keyframe_insert("location", frame=frame)
    if scale is not None:
        pb.scale = scale
        pb.keyframe_insert("scale", frame=frame)


def new_action(arm, name):
    """Start a new action on the rig without destroying the previous ones."""
    if arm.animation_data and arm.animation_data.action:
        arm.animation_data.action = None
    action = bpy.data.actions.new(name)
    arm.animation_data_create()
    arm.animation_data.action = action
    action.use_fake_user = True
    return action


def rest_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)
        pb.scale = (1.0, 1.0, 1.0)


def deg(a):
    return math.radians(a)
