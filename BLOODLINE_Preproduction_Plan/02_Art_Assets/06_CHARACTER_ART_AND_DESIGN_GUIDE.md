# Character Art and Design Guide

## Visual target

Stylized realism: plausible human anatomy, believable cloth/metal/leather/skin materials, expressive faces, intentional proportions, readable silhouettes, and selective exaggeration for combat readability. Avoid both low-effort cartoon proportions and unrestricted photorealism that is expensive to render and animate on mobile.

## Design principles

- Each fighter must be identifiable in silhouette before material detail is visible.
- Keep a coherent world-wide material and lighting language.
- Use supernatural colour and effects as limited identity cues, not a full-screen fog of particles.
- Ensure clothing and accessories do not obscure key joints, hit reactions, or weapon contacts.
- Build variations around deliberate visual themes; do not merely recolour the same costume and call it a new character.
- Keep original design language. Do not trace or replicate recognisable franchise characters, signature weapons, costumes, fatalities, logos, or UI.

## Character concept sheet

Each fighter needs front, side, and back views; face close-up; colour/material palette; silhouette thumbnail; costume callouts; weapon and accessory sheet; stance/pose sheet; power-effect reference; and scale comparison with existing fighters. Include a short text explaining role, background, combat archetype, strengths, weaknesses, and visual motif.

## Proportion and silhouette

Set a common project scale and a shared baseline for standing height. Variation is allowed for fighter identity, but not so extreme that camera framing, rig reuse, and hitboxes become unmanageable. Establish silhouette checks against bright and dark backgrounds. Readability during guard, crouch, jump, and attacks is more important than ornamental detail.

## Materials and textures

Use physically based materials where supported, but budget material slots and texture resolution for mobile. Prioritise face, hands, upper-body costume, and signature equipment. Reuse material instances where practical. Avoid unnecessary 4K textures for assets that appear at a small on-screen size. Validate compression and colour-space settings inside the final engine, not only in the art tool.

## Face and expression

Launch characters need a consistent quality threshold for faces. If facial animation is out of initial scope, use strong base expression, head motion, pose, and body language rather than attempting a complex face rig inconsistently across the roster. Future cinematics may require additional facial blend shapes or a compatible facial rig.

## Costume construction

Costumes must deform cleanly at shoulders, elbows, hips, knees, and waist. Long coats, skirts, loose straps, capes, hair, and hanging accessories can create clipping and performance issues. Use simulated secondary motion only after profiling; a controlled authored animation can be better for low-end phones.

## Weapons

Design weapons for clear outlines and readable contact points. Measure reach against the fighter's attack data. Use dedicated weapon attachment points and clear naming. Avoid oversized shapes that cover both fighters or obscure the hit. Every weapon must be either combat-functional under documented rules or explicitly cosmetic.

## Effects

Create a hierarchy: small contact sparks, block effects, signature ability effects, and exceptional ultimate effects. Use brief effects, disciplined brightness, pooled particles, and restrained transparent layers. Provide clear telegraphs and avoid visual noise. Effects must not be essential to identifying the opponent's real body or attack state.

## UI portraits and icons

Each character needs a high-quality selection portrait, small HUD identifier, ability icon, and optional rarity frame. The portrait must match the final in-game model. Use separate UI artwork only when it adds value and has a trackable source file.

## Review process

Concept review → silhouette review → model blockout → material review → rig/deformation review → in-engine lighting review → small-screen readability review → performance review → final approval. Record feedback and versioned approvals rather than overwriting the only source copy.

## Reference management

Keep reference images and generated concepts in a clearly named folder with creator/source, date, permitted use, and any restrictions. AI-generated references may guide original work, but review outputs for accidental similarity to protected characters, logos, or artist-specific work. Preserve editable working files.
