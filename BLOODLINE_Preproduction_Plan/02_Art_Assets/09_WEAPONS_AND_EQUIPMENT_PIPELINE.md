# Weapons and Equipment Pipeline

## Design intent

Weapons and equipment support character identity and long-term collection. They must not turn the combat system into an unmanageable set of incompatible rigs and animation variants. The initial launch should use a narrow, validated subset.

## Equipment categories

- Signature weapon: defines or strongly shapes a fighter's fighting style.
- Alternate combat weapon: changes a curated moveset and requires dedicated balance/animation work.
- Cosmetic equipment: changes appearance only and does not affect combat statistics.
- Defensive equipment: if used, introduces clear trade-offs and must be balanced.

Do not treat every visible object as equippable. Decorative props can remain part of the character model.

## Data required per item

Stable item ID, display name, description, category, rarity if applicable, ownership/unlock rule, compatible fighters, attachment socket, model/material references, animation/moveset reference, stat modifiers if allowed, icon, licensing provenance, and validation status.

## Weapon modelling

Use consistent scale and pivot conventions. Keep the origin at a documented grip point or define a socket offset. Model the blade/striking surface clearly enough for hitbox calibration. Validate material response under arena lighting. Minimise unnecessary geometry and transparency.

## Socket and rig integration

Create standard hand sockets and define hand/grip poses. The weapon's position and orientation must remain correct through idle, guard, attack, hit reaction, victory, and defeat. If left/right-handed versions are supported, both need checks. Do not duplicate a whole skeleton for each weapon unless a measured technical reason requires it.

## Weapon hitboxes

Use move-specific hit volumes, not the visible mesh's every-triangle collision. Define active windows, reach, damage, hit reaction, block interaction, and whether attacks are high/low/throwing or otherwise unique. Ensure long weapon reach is visible and fair. Never allow hitboxes to linger after the visible strike.

## Moveset strategy

Initial recommendation: signature weapons belong to a few fighters and are supported by curated animations. Add alternate weapon-based movesets only after one full alternate set has passed the pipeline. Cosmetic-only gear should be visually compatible without changing collision or balance.

## Unlocks and economy

Item rarity is a collection label, not automatic proof of strength. Clarify whether items are earned through challenges, progression, direct unlocks, or future purchases. Do not implement random paid item draws without explicit product, platform-policy, and legal review. The current plan assumes no real-money economy until separately approved.

## QA checklist

Check model scale, pivots, grip, clipping, attachment stability, visible/active hit alignment, mirrored orientation, move cancellations, weapon persistence across round resets, material performance, icon readability, ownership rules, save persistence, and licence records.
