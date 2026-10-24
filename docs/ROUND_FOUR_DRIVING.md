# Round Four driving update

The roadside props now move toward the following camera as travelled distance grows, matching the road and station. The supplied SUV remains: its fixed `wheel-back` spare no longer receives rolling-wheel animation; the four actual left/right road wheels still animate.

## Driving and stops

Traffic has an individual road speed: same-direction vehicles travel at 7–16 m/s, oncoming vehicles at 12–25 m/s. Relative motion uses both that speed and the player's speed, so braking lets faster traffic pull away. Traffic still has actual 3D collision consequences.

Stations have a marked right-hand slip lane beginning 180 m before the forecourt. Steer progressively to the far right: a held touch near the right screen edge follows the lane as it widens. Keyboard right also works. Arriving beside the station while in its forecourt automatically opens the free fuel stop. The station HUD action explains the exit and cannot teleport the car off the highway. Missing an exit leaves the next station available; ordinary fuel rescue still gives a free ride without travelled-distance credit.

A completed fuel stop records the current ramble's route, trip distance, fuel and hearts. Rare parked shoulder patrols occur 2.6–4.3 km apart, with a visible warning before their observation area. A clean overtake of same-direction traffic within 70 m of a patrol returns the current ramble to that completed stop (or departure before the first stop). Banked lifetime progress, coins, XP, daily claims and discoveries remain safe; the caught pass itself gives no reward. Meeting oncoming traffic is not an offence. Police never spawn as moving traffic. A parked police sighting remains a one-time journal discovery and never counts as a passed vehicle.

The save filename and version-2 persistent schema remain unchanged. Checkpoints are local to the active ramble, matching the existing new-ramble flow; this update does not claim cold-load trip restoration. Existing genuine saves, original QA APKs and source/capture records remain preserved.

## Verification boundaries

`tests/test_round_four_road.gd` exercises actual source scene/model/physics assets with isolated test user data, including prop motion, SUV wheel hierarchy, continuous-touch station entry, patrol conditions, checkpoint reset, bank preservation and traffic speed variation. The existing state, Physics3D, Back/station, integrated flow and service tests remain required. These fixtures are automated source evidence, not native gameplay or real SDK proof.

The changed exit lane, HUD guidance and roadside patrol need fresh affected Android visual/input validation on the new binary. Prior native screenshots retain their old build provenance. Physical-device, audible-output, interactive Web, production-ID and broad startup/reliability acceptance remain separate owner checks. No gameplay evidence or rewards are fabricated.

## Qualified source/export and limited Web checkpoint (2026-10-24)

Public source `e0cf51952cdec4c896ac99279f4303e80a349ed4` has [passing exact-commit hosted CI](https://github.com/EthannYakabuski/open-road-ramble/actions/runs/40125607404). `../HANDOFF.txt` records the frozen AAB/Web/test-ZIP component source identities and hashes; this documentation update makes no rebuild or archive change.

Limited interactive Web checks in an isolated browser profile on the frozen Web export verified forward scenery and NPC traffic, one actual right-steering hold, natural collisions and one free roadside-help recovery into a fuel forecourt. Free refuelling/Continue returned to driving, and ordinary Finish ramble returned Home with progress visible. Recovery into the forecourt is not proof of a driven station exit; reward-component formulas and once-only banking were not isolated. The driven exit was not verified: the operator responded about 24.5 seconds after the captured cue against an approximately ten-second nominal approach window. This input-limited run establishes neither an app defect nor human driving/usability acceptance. The exit-arrow glyph rendered as a box; an aborted startup resource request remains qualified, without a blanket clean-log claim.

Still required: genuine driven right-lane station entry, continuous driving/exit clarity and traffic-density assessment, rare roadside-patrol spawn/consequences and SUV/Jeep-specific wheel-motion review. Actual pause-menu, reload/banked-save retention, real rewarded-ad lifecycle, audible output, affected Android/native checks, materially changed current-build Android captures, intended physical-device and production-service acceptance remain unverified. No new Round Four Android screenshots are accepted. Historical APKs, screenshots and earlier checkpoint text retain only their named source/build scope.
