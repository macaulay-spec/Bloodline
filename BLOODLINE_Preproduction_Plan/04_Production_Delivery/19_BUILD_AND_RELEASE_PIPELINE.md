# Build and Release Pipeline

## Goal

Produce repeatable Android builds from source, install them on real devices, and retain evidence of what was tested. A CI job marked green proves only that its configured steps passed; it does not by itself prove the game behaves correctly on a phone.

## Repository organisation

Suggested logical directories (exact names may change with engine):
- `Docs/` — architecture and decisions.
- `Game/` or engine project root — scenes, scripts, resources, UI, input, audio, and content definitions.
- `AssetsSource/` — editable source models, textures, and audio when storage/licences permit.
- `Tools/` — import validation, data checks, build helpers.
- `Tests/` — unit, integration, combat and content validation.
- `BuildNotes/` — release notes and test evidence; do not commit unnecessary generated packages.

Keep engine-generated cache folders and temporary exports out of ordinary source control. Establish a policy for large files and binary source assets before the repository becomes huge. Secrets and signing keys must never be committed.

## Build stages

1. Validate repository and required tool versions.
2. Run content-data and reference validation.
3. Run automated tests available for combat rules, progression, and save logic.
4. Import/build with the documented engine version and Android configuration.
5. Produce a uniquely versioned APK for internal testing; keep signing strategy appropriate to internal versus release distribution.
6. Install the APK on a target device.
7. Test boot, a full match, results, rematch, saves, background/resume, and a second launch.
8. Record build commit, version, engine/tool versions, device/OS, known defects, and test outcome.
9. Publish/release only after the release gate is approved.

## Versioning

Track application version, content version, save schema version, and repository commit separately. Every test build must be traceable to its source. Do not overwrite the only known-good APK without keeping a clear history.

## Automated builds

GitHub Actions or another CI system may build the project if engine licensing, build runners, Android SDK components, asset storage, memory, and time limits permit. Validate this early with a small project. Large 3D asset projects can exceed free CI storage or runner limits; create a fallback documented local build path. Store secrets in CI secret storage and restrict access.

## Signing and distribution

Use a debug/internal signing path for testing and secure release signing for public distribution. Protect keystores and passwords. Follow the current target store's packaging and policy requirements at release time. Do not embed credentials in scripts or source. The current plan targets an installable APK for device testing; public distribution may require other formats and policy steps.

## Failure handling

A failed build must preserve logs and identify the failure stage. Missing assets, failed references, and test failures should stop a release build. Do not use dummy empty scenes or silently remove features merely to make CI green.

## Release checklist

- Version/commit identified.
- Correct Android configuration and package ID.
- Clean startup and main-menu flow.
- Full versus match, result, rematch, and persistence tested.
- No known blocker defects.
- Performance and asset licence gates passed.
- Permissions and privacy disclosures reviewed.
- Build artifact archived with checksums and test notes.
