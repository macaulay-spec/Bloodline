# Character Data and Content Schema

## Purpose

Use stable, validated content definitions so fighter differences can be authored and balanced without duplicating entire gameplay systems. The final serialisation format depends on the selected engine, but the conceptual schema should remain consistent.

## Stable identity

Use non-localised IDs such as `chr_unbound`, `move_unbound_light_01`, `ability_nyra_dash`, `weapon_staff_basic`, and `arena_circuit_pit`. Display names and descriptions are localisation keys or editable content fields, never primary identifiers. IDs should not change because a character is renamed.

## Fighter definition

Required fields: ID, display/localisation keys, roster group, model/rig/animation references, portrait/icon, base combat stats, movement profile, allowed equipment, move IDs, ability ID, unlock rule ID, mastery rule ID if used, audio/VFX references, tags for AI/training, asset provenance reference, content version, and validation state.

## Move definition

Fields include ID, input/action tag, allowed initial states, startup/active/recovery timing, hit-volume configuration, damage and reaction parameters, pushback/launch values, guard behavior, resource cost, cancel/chain tags, animation reference, SFX/VFX references, training description key, AI suitability tags, and balancing notes. Ranges and valid values should be constrained.

## Ability definition

Fields: ID, description key, type/behavior module, range, startup, duration, recovery, cooldown or meter cost, affected target/state, damage/reaction rules if applicable, counterplay notes, animation/VFX/SFX references, and AI usage conditions. Unique ability logic must be modular and testable.

## Weapon/equipment definition

Fields: item ID, category, display key, model/material references, attachment socket, compatible fighter IDs or tags, cosmetic/combat classification, moveset override if any, modifiers if allowed, unlock rule, icon, licence record ID, and validation state.

## Arena definition

Fields: arena ID, scene/prefab reference, spawn points, boundary values, camera framing values, ambience, lighting preset if appropriate, supported match modes, performance tier, and asset provenance.

## Progression data

Represent ownership, currency, mastery, unlocked arenas, and completed challenges as separate fields/records. Use explicit schema versions. Never trust UI state as saved progression. Apply reward changes through one validated path.

## Example conceptual record

```json
{
  "id": "chr_unbound",
  "displayNameKey": "character.unbound.name",
  "archetype": "balanced_close_range",
  "modelRef": "characters/unbound/model",
  "portraitRef": "ui/characters/unbound/portrait",
  "moveIds": ["move_unbound_light_01", "move_unbound_heavy_01"],
  "abilityId": "ability_unbound_veil_strike",
  "equipmentPolicy": "curated_compatible_items",
  "unlockRuleId": "unlock_starter_pool",
  "contentVersion": 1
}
```

This example is a design illustration, not an engine-ready runtime file. Validate the eventual real schema against the chosen engine.

## Validation rules

- IDs are unique and stable.
- All referenced assets, moves, abilities, icons, and unlock rules exist.
- Numbers are within sensible limits; no negative cooldowns or invalid ranges.
- Every move has a valid animation and defined hit/recovery rules.
- Every equipment item has compatible attachment/moveset rules.
- Every unlock path is reachable and documented.
- Every third-party asset reference has a provenance record.
- Missing or invalid fields fail validation rather than silently loading a broken fighter.

## Versioning and migration

Assign schema versions to save data and content packages. Migrations must preserve ownership and progress where feasible. If a fighter is retired or a move ID changes, use explicit aliases/migrations instead of deleting player data. Test migration using older sample saves before release.
