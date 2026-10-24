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
