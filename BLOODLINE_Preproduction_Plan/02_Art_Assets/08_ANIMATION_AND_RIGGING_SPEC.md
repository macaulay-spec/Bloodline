# Animation and Rigging Specification

## Purpose

Establish a common skeletal and animation standard so fighters feel responsive and remain economical to produce. Combat animation must support explicit timing and collision windows; pretty movement that does not align with the hit logic is unacceptable.

## Shared skeleton baseline

Use a documented humanoid hierarchy with root, pelvis, spine/chest, neck/head, arm chains, hand/finger groups as needed, and leg/foot chains. Bone names, axes, rest pose, root direction, scale, and weapon sockets must remain consistent. Confirm the standard after selecting the engine and first base model.

## Root motion policy

For the first combat system, prefer code-controlled horizontal movement with animation poses supporting it, unless tests show authored root motion is materially better. Mixing uncontrolled root motion and gameplay movement can cause sliding, teleporting, or incorrect spacing. Document which clips may move the root and who owns position during those clips.

## Required baseline clip set

- Idle/ready stance; forward and backward movement.
- Crouch and stand; jump and landing if included.
- Light attack and heavy attack families.
- Guard raise/hold/release and block reaction.
- Hit reactions for light/heavy/launch/knockdown as required by combat rules.
- Dodge/evade if included.
- Knockdown, wake-up, defeat, and victory.
- Signature ability start/active/recovery where the animation needs phases.
- Intro/outro clips only if they do not delay or obstruct play.

Expand this list based on the chosen moveset and weapon. Do not author many highly polished unique animations before baseline combat timing is validated.

## Animation timing

Combat data defines startup/active/recovery windows. The relevant animation poses must align with those windows. Use clear anticipation and impact poses; avoid attacks whose active hitbox occurs while the weapon is visibly far from the opponent. Hit-stop, camera impulse, sound, and VFX supplement contact but must not conceal incorrect timing.

## Transitions and interruption

Define how an animation transitions into guard, hitstun, dodge, follow-up, knockdown, and round end. Some attacks cannot be cancelled; others may cancel within an explicit window. Interruptions must not leave the character with a frozen root, stuck weapon, or invalid state. Test at low frame rates.

## Retargeting checks

For every retargeted clip, check shoulder deformation, hip/knee direction, hand placement, foot contact, spine twist, facing, weapon grip, body clipping, and frame timing. Fix clips individually where needed. Do not apply a blanket retarget process to a full library without validating samples.

## Weapon animation

Ensure hand grip aligns with the weapon socket. Weapon trails and hit volumes should be separate systems triggered by the move's active window. A weapon may need bespoke animation layers or clips; do not fake a sword attack with an unmodified punch animation when the mismatch is obvious.

## Animation controllers

The controller should be driven by explicit combat state and move definitions. Avoid relying only on fragile animation-name string checks. Create a mapping from stable move IDs to animation clips, phase markers, blend behavior, and permissible transitions. Validate missing references at build time.

## Performance

Measure skeletal update cost, bone count, skin weights, blend shapes, secondary motion, and concurrently animated fighters. Disable or simplify costly secondary motion on low-end settings. Use authored motion where it is visually acceptable and more stable.

## Quality gate

A clip passes only if its start/end pose is controlled, transitions are clean, gameplay timing aligns, body/weapon clipping is acceptable, foot sliding is within tolerance, mirrored side behavior works, and it performs in the final Android build. Record clips that are placeholders and do not silently ship them as polished animation.
