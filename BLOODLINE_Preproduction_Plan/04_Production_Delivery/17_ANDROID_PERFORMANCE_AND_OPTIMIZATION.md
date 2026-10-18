# Android Performance and Optimization

## Objective

Maintain responsive, stable combat on the declared supported Android device range. A short period of smooth gameplay is not enough; test full matches, repeated rematches, background/resume, device heating, and heavy VFX moments.

## Performance target

Choose a target frame rate after engine and device testing. Prefer a stable target over an unstable peak. Record average frame time, worst spikes, memory use, loading time, CPU/GPU pressure, and battery/thermal behavior. Define minimum supported device classes and graphics settings from evidence.

## Budget categories

Set per-scene and per-character budgets for:
- Geometry and skinned-mesh cost.
- Bone count and skin influences.
- Texture memory and texture dimensions.
- Materials and draw calls.
- Lights, shadows, post-processing, and transparent surfaces.
- Particle counts and active VFX.
- Audio assets and simultaneous voices.
- Scene memory, loading spikes, and retained asset references.

Do not invent universal numeric budgets before profiling. Measure the vertical slice on the actual target phone, then set guardrails and keep a safety margin.

## Asset optimization

Use appropriate texture compression, mipmaps where useful, shared materials, sensible mesh complexity, reduced hidden geometry, and levels of detail where beneficial. Keep hair, cloth, transparent VFX, and layered materials under control. Do not ship source-resolution textures when they have no visible benefit at the fight camera's distance.

## Rendering and effects

Use controlled lighting, cautious shadow use, restrained bloom, and limited full-screen post-processing. Pool repeated impact effects if supported by the engine. Avoid needless allocations in combat loops. Test simultaneous attacks, multiple particles, and two high-effect fighters.

## Memory and loading

Load only required fighters/arenas where feasible. Release references when no longer needed. Avoid loading the entire future roster at boot. Profile allocations and garbage collection/stutter during combat. Check low-memory behavior, interruption, and returning from background.

## Device test matrix

At minimum: a low-end target phone, a mid-range representative device if available, multiple screen aspect ratios/resolutions where available, and the exact packaged Android build. Record device/OS/build version for every performance report. An emulator is useful but cannot substitute for real-device testing.

## Thermal and battery behavior

Run extended matches, not only brief demos. Observe thermal throttling, sustained frame pacing, and touch responsiveness after the device warms. Quality settings should allow heavy visual costs to be reduced without making gameplay unclear.

## Performance acceptance

- No recurring severe combat hitch attributable to known uncontrolled allocations.
- Stable enough frame pacing to support the selected combat timing model.
- No reproducible out-of-memory or app crash in the supported test set.
- Loading and rematch loops work repeatedly.
- Gameplay stays readable at the lowest supported visual preset.
- Performance budgets and exceptions are documented before release.
