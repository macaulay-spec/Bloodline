# Engine and Platform Architecture

## Decision status

Unity is the provisional first candidate; Godot is the principal alternative to evaluate. No engine is considered finally selected until a small, time-boxed feasibility exercise runs on the target Android device and demonstrates model import, skeletal animation, touch input, collision/hit detection, profiling, and repeatable APK packaging.

## Selection criteria

Score candidate engines against:
- Android build reliability and toolchain access.
- Performance on low-memory, modest-GPU phones.
- Character rigging, retargeting, and animation workflow.
- Input, physics, camera, UI, audio, profiling, and test support.
- Asset import/export reliability with the planned Blender workflow.
- Build automation from a repository.
- Documentation, community support, licence and distribution terms.
- Maintainability by the available developer and tools.

Choose from a demonstrated project rather than preference or marketing footage. Use the smallest possible technical scene to answer these questions.

## Target platform

Android first, with aspect-ratio adaptation and touch-first input. Set the minimum OS version, API level, graphics backend, architecture, memory class, and frame-rate target after checking the actual target device and build tools. Do not claim compatibility with all Android phones until device testing exists.

## Rendering approach

Use stylized-realistic art, controlled lighting, practical texture sizes, conservative transparent effects, and predictable draw/skinning costs. Prefer readable contrast over expensive post-processing. Build quality tiers only after profiling shows what can be scaled.

## Code architecture principles

- Separate input, combat rules, animation presentation, AI decisions, UI, save data, and content definitions.
- Use stable IDs and typed data where supported rather than relying on display strings.
- Keep fighter-specific values in content data where they do not require unique code.
- Centralize configuration, scene references, and asset validation.
- Define explicit lifecycle/state transitions for matches and fighters.
- Make error states visible during development; do not silently ignore missing models, animations, or data.
- Keep debugging tools out of release builds unless intentionally included.

## Scene/system boundaries

Suggested scenes: Boot/Initialization, Main Menu, Fighter Select, Arena/Match, Results, Practice Setup, Settings. Exact scene count depends on the chosen engine. Keep fight logic reusable so versus, practice, tournament, and later campaign encounters can instantiate the same combat runtime with different rules.

## Asset pipeline

Blender or another chosen content tool produces source assets. Use a versioned export area, consistent names, automated or scripted import validation where feasible, and an asset register. Preserve working source files separately from engine imports. Every third-party asset must pass licence review before it enters release content.

## Build and source control

Use a repository structure with clear separation of project source, documentation, tools, tests, and build outputs. Do not commit generated caches or very large binary assets blindly; define Git LFS or alternative storage only if needed and feasible. Keep secrets out of the repository. A successful CI build is not the same as a tested APK; install and run packaged builds on a device.

## Architecture for later networking

Keep match inputs, combat events, fighter state, and match rules conceptually separate from UI. Avoid embedding offline-only assumptions into every system. However, do not prematurely build a custom network engine. Later multiplayer requires deterministic or reconciliable combat, authority rules, lag compensation or rollback research, security, account services, and thorough online playtesting.

## Feasibility spike checklist

1. New clean project builds to Android.
2. A rigged humanoid imports and animates correctly.
3. Touch inputs register reliably.
4. Fighter moves within bounds and faces an opponent.
5. Attack hit volumes cause exactly the expected result.
6. One simple AI executes legal actions.
7. Repeated matches start/end/reset without state leakage.
8. Performance and memory are recorded on a real device.
9. A second clean build can be reproduced from documented steps.

## Engine decision record

When the spike passes, record engine/version, target configuration, dependencies, build steps, measured device results, reasons for rejecting alternatives, licence implications, and known limitations. If it fails, fix the blockers or test the alternative before creating production content.
