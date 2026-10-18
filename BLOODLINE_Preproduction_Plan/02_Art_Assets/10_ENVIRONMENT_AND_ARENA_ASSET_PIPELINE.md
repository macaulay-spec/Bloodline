# Environment and Arena Asset Pipeline

## Arena purpose

A fighting arena must frame both fighters, support clear spacing, communicate a location, and run consistently on Android. Background detail should enrich the world without competing with the combat. Launch arenas are contained spaces, not open-world maps.

## Initial arena concepts

1. **The Circuit Pit:** underground contemporary fighting venue; industrial lights, crowd ambience, clear flat floor.
2. **Old Quarter Courtyard:** stone courtyard with traditional architectural motifs; controlled foliage and props.
3. **Meridian Test Hall:** clean research facility with restrained advanced technology and Veil containment equipment.

These concepts are candidates. Start with a neutral training arena to validate camera, collision, lighting, and fighter readability.

## Arena requirements

- A calibrated fighting plane and defined left/right boundaries.
- Clear floor collision with no unintended gaps or snag points.
- Camera limits, fighter scale, and staging marks.
- Background layers with controlled parallax/depth only if they remain readable and efficient.
- Fixed or baked lighting where practical for mobile; dynamic lighting only where it adds clear value.
- Audio ambience and visual effects referenced by data.
- Spawn points, round reset behavior, and testing hooks.
- Small/large screen checks and accessibility/readability review.

## Modular production

Build reusable wall pieces, doors, columns, floor modules, trims, props, decals, lights, and background elements. Establish common scale and material standards. Reuse must not make all arenas visually identical; use distinct composition, palette, silhouettes, and landmark props.

## Collision and interaction

At launch, background props should generally be non-interactive unless an explicit gameplay mechanic requires interaction. Avoid unexpected collision near the fighters. Any destructible or reactive arena feature adds animation, state, testing, and performance costs and should be treated as a later feature.

## Asset optimization

Budget triangles, materials, texture sizes, shadow casting, transparent layers, particles, and lighting. Prefer texture atlases or shared materials where useful. Use level-of-detail or reduced background detail if profiling demonstrates benefit. Avoid overbuilding unseen backsides and distant objects when the camera never reveals them.

## Lighting and camera composition

Fighters must remain readable under all arena conditions. Test silhouette contrast, skin/material response, weapon edges, ability VFX, and UI readability. Avoid severe bloom, excessive motion blur, and full-screen effects. The camera must keep both fighters visible during throws, knockbacks, jumps, and side switches.

## Production pipeline

Concept thumbnail → camera blockout → fighter-scale test → modular blockout → collision and lighting → material pass → props and background detail → VFX/audio → mobile optimization → acceptance test. Do not add final details before the actual combat camera is stable.

## Acceptance

The arena passes only when boundaries work, fighters cannot fall through or escape unintentionally, all moves fit the visible space, the camera does not lose combatants, lighting remains readable, device performance passes, and asset provenance is recorded.
