# Round Five: traffic, momentum and station access

Updated 2026-10-29. Source and scene acceptance passed in Godot 4.5.1 Compatibility. Previous APK evidence does not establish native acceptance for this changed code.

## Requested behavior

- **A - Traffic passing:** Heading is independent of lane. A faster right-lane NPC checks opposing traffic and forward/rear gaps, moves smoothly left to pass, then returns right after clearance. If passing is unsafe it follows and brakes. Swept body checks preserve longitudinal separation. Oncoming cars also follow slower traffic; spawning reserves body space and does not introduce an oncoming car into an active passing corridor.
- **B - Speed diversity:** Ordinary same-direction cruise targets span 4.5-31.5 m/s; opposing targets span 9-33 m/s. Trucks/vans are capped at 16 m/s and race cars travel at least 27 m/s. Following can lower actual speed while retaining the driver's cruise target.
- **C - Momentum:** Forward travel accelerates quickly to 12 m/s, then gains 1 m/s each second up to **120 km/h**. Brake still slows to 5 m/s. Leaving the road slows toward 18 m/s for station access. Paused or ad-covered time does not advance acceleration. Existing collision and free repair rules remain.
- **D - Speed achievements:** `speed_70`, `speed_90`, `speed_100` and `speed_120` are Standard achievements using the saved `top_speed_kmh` peak. They grant no extra coins/XP. Missing speed in old saves defaults to zero; v1/v2 banked fields are preserved. Existing backend mappings remain unchanged; only the four new map values are blank pending owner setup. Matching illustrated 512 px icons are in `marketing/achievements/`, with originals, prompts and hashes under `marketing/source_art/round_five/`. The catalog and store icon mapping now contain 20 achievements.
- **E - Clear access:** Right-hand scenery is hidden throughout the signed station approach and forecourt, with extra margin for scaled rock landmarks. Opposite-side scenery, the station building and marked slip lane remain. No prop collision was added.

## Source acceptance

`tests/test_round_five_road.gd`: **31 checks, zero failures**. It covers a completed NPC pass/return in the deterministic model, unsafe passing/following, high closing speeds, a 75-second mixed stream, acceleration/cap/milestones, JSON save compatibility and actual 3D-node clearance/heading.

Affected suites also passed with strict diagnostic gates: state 25, 3D scene 40, integrated flow 17, Round Four 33, Android Back/station 40, plus service smoke and import. These isolated source/scene/physics/input fixtures do not establish Android rendering, physical touch, audible sound, real SDK callbacks or human driving acceptance. Badge numerals and style were visually inspected at 144 px and full size.

Run game tests in fresh process-scoped `APPDATA` and `LOCALAPPDATA` roots on Windows, or `XDG_DATA_HOME` on Linux. Set `ROUND_FIVE_TEST_ROOT` to their common parent; the new fixture checks its actual Godot user-data path and refuses Android. Never run fixtures against owner profiles. CI creates separate XDG directories per test. Retain strict script, parse, assertion and engine error gates.

## Builds and remaining acceptance

Inspect the containing commit's hosted Actions run for its exact Android AAB and Web export results. Historical `marketing/package-status.json` describes its recorded Round Two runtime, not this revision. Existing local releases, genuine saves and private evidence are unchanged. No new local Android/Web export was generated during the source checks.

Still required on a new build: visual overtaking and speed-feel review; normal driven station entry across all four biomes; Android touch and ad lifecycle; audible output; real service configuration; and intended physical devices. The coordinator records browser/native evidence separately. No generated gameplay screenshots or synthetic rewards are offered as test evidence. The previous SwiftShader failure remains an environment limitation until fresh supported evidence resolves it.
