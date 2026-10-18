# 3D Character Asset Pipeline

## Objective

Build a repeatable, legal, measurable pipeline that turns an approved character concept into a complete, animated, playable fighter in the Android game. A model file alone is not a finished asset.

## End-to-end pipeline

1. **Concept and reference:** approve the character role, silhouette, costume, palette, body proportions, and weapon. Record reference sources and rights.
2. **Base model choice:** choose whether to create the model from scratch, adapt a licensed base, or use a permitted generator. Check commercial/redistribution rights, export formats, editability, and restrictions before committing.
3. **Blockout:** check silhouette, scale, stance, reach, and camera framing using a simple model.
4. **High-detail sculpt/model:** produce the approved appearance and clean design details.
5. **Game-ready topology:** create an appropriate deformation mesh and polygon budget. Remove hidden geometry and unnecessary detail.
6. **UVs and textures:** make efficient UV layouts; create texture maps or materials required by the chosen engine; test compression and colour-space.
7. **Rigging:** bind to the project skeleton or a validated compatible rig. Check shoulders, elbows, hips, knees, fingers, spine, and weapon grip poses.
8. **Animation:** apply shared animations, retarget only where appropriate, and author character-specific clips as needed. Validate feet, weapon contact, root motion policy, and transitions.
9. **Export:** follow a documented interchange format and naming convention, maintain scale/orientation, include only required assets, and verify exported files in a clean import.
10. **Engine integration:** assign materials, rig/avatar, animation controller, colliders, attack/hurt volumes, sockets, VFX, audio, UI portrait, and character data.
11. **Combat testing:** test movement, all moves, interruption, hit reactions, side switches, arena boundaries, weapon contacts, and AI use.
12. **Device validation:** run on representative Android hardware; check memory, frame pacing, texture load, shading, and performance during multiple effects.
13. **Approval and catalogue:** pass the character gate, record versions/licences, and update the asset register.

## Choosing the production route

### Route A: original modelling
Best for distinct signature fighters and full control. Higher skill/time cost, but the design is editable and ownership can be clearer.

### Route B: licensed base + original adaptation
Potentially the fastest way to achieve consistent anatomy. Only use source assets whose licence permits the intended use and modification. A marketplace download is not automatically free for redistribution in a shipped game. Review requirements on derivative works, attribution, and source-file redistribution.

### Route C: AI-assisted generation
Can support concepts, textures, or approved production steps where the tool produces usable output with sufficient rights. Do not assume a generated image is a rigged 3D character. Inspect topology, UVs, geometry, licenses, export limitations, and anatomical defects. Human review and cleanup remain required.

A mixed route is likely practical: original concept art; a consistent base mesh/rig; targeted modelling and costume work; licensed or original animation clips; authored signature moves.

## Shared rig strategy

Use one standard humanoid skeleton where practical. Establish naming, hierarchy, bone orientation, rest pose, scale, root/pelvis convention, hand/foot orientation, and weapon sockets. Reuse saves time only when deformation and motion stay acceptable. Large body-shape differences may need corrective weights or special animation adjustments.

## Animation retargeting policy

Never assume two humanoid rigs are compatible because they have the same number of bones. Test rest pose, mapping, bone roll/orientation, root motion, foot contact, hand position, and weapon grip. Retarget a small animation sample before purchasing, downloading, or adapting a large animation library.

## Export and naming convention

Use stable IDs, not display names, for machine references. Example patterns:
- `CHR_UNBOUND_Model_v001.fbx`
- `CHR_UNBOUND_Skeleton_v001.fbx`
- `ANIM_UNBOUND_Attack_Light_01_v001.fbx`
- `TEX_UNBOUND_BaseColor_2K_v001.png`
- `MAT_UNBOUND_Body_v001`
- `ICON_UNBOUND_Portrait_v001.png`

Exact engine-import format will be set after the engine decision. Never silently overwrite approved source files; version updates and retain source project files.

## Budgeting and level of detail

Set budgets after measuring a complete fighter on device. Track triangles, texture memory, materials, bones, animation count, accessory complexity, and VFX. Use levels of detail or reduced texture sizes if the engine and camera distance warrant them. Avoid excessive hair cards, transparency, layered cloth, and small mesh details that have little on-screen benefit.

## Required deliverables per fighter

- Editable source project and exported game model.
- Textures/materials and texture-source notes.
- Rig/skeleton reference and tested retarget setup.
- Required animation clips and animation map.
- Weapon/attachment assets if relevant.
- Collider/hitbox/hurtbox configuration or references to the combat data.
- VFX/audio/icon/portrait references.
- Machine-readable character definition.
- License/attribution record.
- Visual review images and on-device test report.

## Common failure modes

Bad topology, broken joints, incompatible rigs, sliding feet, weapons missing the hand, animation speed mismatch, excessive texture memory, dark/overblown materials, inconsistent scales, missing references, unlicensed redistribution, and a fighter that looks good only in the modelling tool. Validate at every stage, not at the end.

## Pipeline proof

Before making the full roster, finish one fighter end-to-end and measure each step. Document setup once, then repeat it for a second fighter. If the second fighter cannot use the same rig, animation framework, and integration path without extensive rework, fix the pipeline before scaling production.
