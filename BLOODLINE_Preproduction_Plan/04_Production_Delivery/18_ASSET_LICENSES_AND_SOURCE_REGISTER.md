# Asset Licences and Source Register

## Purpose

Track where every external asset came from, what rights permit its use, and whether it can ship inside a paid or free game. “Free download,” “AI-generated,” and “available on a marketplace” are not sufficient licence checks.

## Register fields

For each asset or asset pack, record:
- Stable asset ID and descriptive name.
- Creator/publisher.
- Source URL and date accessed/downloaded.
- Exact licence name/version and a saved copy or link to its terms where permitted.
- Permitted commercial use, modification rights, attribution requirements, redistribution restrictions, and whether source files can be included.
- Required attribution text and where it will appear.
- Engine/export compatibility and any platform limits.
- Whether the asset was modified and which source files are derived from it.
- Approval status, reviewer, and review date.

## Review rules

- Do not ship an asset if licence terms cannot be established.
- Distinguish a personal-use licence from a commercial licence.
- A character model licence may not include its textures, rig, animations, or embedded music.
- Assets may be licensed under different terms inside the same pack.
- Some licences permit a compiled game but prohibit redistribution of source files or standalone assets.
- Verify that AI or generator terms permit the intended commercial use and that the output does not create an obvious third-party IP conflict.
- Preserve attribution obligations in a third-party notices file or in-game credits as required.

## Third-party versus original assets

Prioritise original designs for signature fighters, logo, key UI, and recognisable powers. Third-party base meshes, generic props, and properly licensed animation resources can reduce workload if adapted coherently. Never use extracted models, ripped textures, copied animation data, or copyrighted character assets from commercial games without permission.

## Source storage

Keep source project files and licence evidence in a controlled asset-source directory. Track large binaries intentionally; avoid accidentally placing unlicensed assets in public repositories. Do not publish a source asset pack merely because the finished game may be allowed to contain it.

## Approval workflow

Asset candidate → technical sample import → licence review → adaptation review → in-engine test → provenance record → release approval. The technical artist or project owner signs off each stage. Any change in licence, account plan, tool, or distribution route triggers a recheck.

## Release checklist

Every shipped asset has an asset ID, licence/provenance record, correct attribution if required, known modification status, no unresolved restrictions, and appropriate source retention. Generate the third-party notices and credits from the register where practical.
