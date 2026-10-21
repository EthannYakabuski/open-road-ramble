# 3D driving update

The current source uses real Kenney Car Kit cars, City Kit road/building models and Nature Kit vegetation in a perspective 3D world. The portrait following camera, streamed curved roads, traffic, biome scenery and Little Pine forecourt are rendered by Godot Compatibility. The forecourt combines supplied buildings and scenery with original canopy and pump details because the reviewed packs contain no named fuel-pump model. See `assets/3d/SOURCE_MANIFEST.json` and `LICENSES/Assets/` for exact supplied assets and CC0 notices.

## Controls and consequences

Drag left/right to steer; hold BRAKE to slow down near a station. Each distinct physical traffic collision removes one heart, reduces speed and cannot grant a clean-pass reward. A short grace period prevents one overlap from consuming all three hearts. Three hits offer friendly, free roadside repair. A free stop repairs the car and fills the tank; out-of-fuel assistance remains available. Rescue travel grants no distance or progression. Existing cars, upgrades, discoveries, levels and daily rewards remain. The accepted lifetime-distance day/night cycle remains across trip restarts, with real forward headlights and warm forecourt lighting at night.

Driving freezes while the application or a fullscreen ad is covered. Returning requires Resume and drops the covered frame time. Reward benefits still require the earned SDK callback; no fallback creates pretend rewards.

## Save compatibility

The existing profile filename remains unchanged. Version-1 profiles migrate to version 2 by adding a lifetime collision counter while retaining banked coins, XP, distance, purchases, discoveries, earned achievements and daily claim state. Test profiles are synthetic and isolated; never alter a real profile to produce evidence.

## Verification and remaining acceptance

The state suite, actual Physics3D overlap/steering tests, integrated heart/repair/input/service-pause tests and service fallbacks pass. The integrated collision fixture runs with active engine/chime audio and drains owned audio before scene removal. A separate sound-enabled scene smoke and source GPU captures completed without engine errors. Same-frame chime restarts are coalesced; shutdown blocks new playback and lets queued voices register and stop on mixer ticks. These checks do not verify audible device output. The desktop source views were visually inspected for road orientation, car framing, lighting, heart/fuel HUD and a visible forecourt. These are source diagnostics, not native gameplay or store screenshots.

Fresh Android/Web exports, native collision/repair/ad-return/save/offline/Back checks and final-build captures remain required for this runtime change. The APK hash and native QA in `HANDOFF.txt` identify the earlier retained build, not this source. Hosted CI builds are separate artifacts. Human balance/long-session review, audible output, physical devices, interactive Web and production services remain unverified.

Use Godot 4.5.1 Compatibility. Android is primary, Web secondary; the observed test preset remains min API 24/target 35 and is not a current Play release-eligibility claim. Keep official sample AdMob IDs in development and the existing disabled PGS placeholders. No Pages activation, Library operation or Google Play publication is included.
