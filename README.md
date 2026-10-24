# Open Road Ramble

## Round 4 build continuation (2026-10-24)

The Android preset now defaults to **AAB** with Gradle, minimum API **24** and target API **35**. ARM64, x86 and x86_64 are selected; the [Round 4 Android guide](docs/ROUND_FOUR_ANDROID.md) explains the native ABI-pair validator and release-owner steps. These are current preset choices, not permanent engine restrictions.

Round 4 exact-source hosted CI and affected native acceptance are pending in this dated continuation snapshot; consult `HANDOFF.txt` for later source-bound results. An ABI-validated debug AAB is test-signed and does not establish Google Play acceptance. Dated APK hashes and screenshots below retain their original build provenance. This round does not start new games.

A quiet road, an open tank, and nowhere you have to be.

A low-pressure 3D endless driving game with a following camera, actual Kenney cars and scenery, fuel stations, friendly roadside rescue, five cars, upgrades, rare traffic discoveries, daily quests and player progression.

## Play

The road advances automatically. Drag horizontally to choose a lateral lane position as the road curves; hold BRAKE to slow near a station, then steer to the far right along its marked exit lane. Driving into the forecourt opens the free refuel stop; the station HUD button only explains the route. BRAKE slows rather than parking the car. Traffic collisions remove one of three hearts and slow the car; three hits offer free roadside repair. Running out of fuel brings a friendly ride to the next station. Visit the garage, journal and daily quests between drives.

Touch/mouse portrait play and offline local saves are supported. Android is the primary target; Web retains gameplay and saves when Android services are unavailable. Browser play never grants pretend ad rewards.

See [Round Four driving details](docs/ROUND_FOUR_DRIVING.md) for speed-varied traffic, rare roadside patrols, right-hand station exits and the source/native verification boundary.

## Development

Original code: Apache-2.0. Developer: [EthannYakabuski](https://github.com/EthannYakabuski). Included assets/plugins retain their own licenses and notices.

Use Godot **4.5.1**, **Compatibility**, matching export templates, Java 17 and the Android SDK. The test preset uses minimum API 24 and target API 35. This is a test-configured build; final release signing, current Play requirements and production backend verification remain with the owner. See [native setup](docs/PLATFORM_SETUP.md).

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/test_state.gd
godot --headless --path . --script tests/test_road_3d.gd
godot --headless --path . --script tests/test_road_flow_3d.gd
godot --headless --path . --script tests/test_android_back_station.gd
godot --headless --path . --script platform/tests/services_smoke.gd
godot --headless --path . --export-release Web build/local-next-update/web/index.html
godot --headless --path . --install-android-build-template --export-debug Android build/local-next-update/android/game-debug.aab
```

Create the unused build/local-next-update/web and build/local-next-update/android directories first; preserve accepted and original outputs. Android package: `com.ethannyakabuski.openroadramble`. Tests and capture helpers are documented under game/ and tests/. No Windows build is supplied.

The Round Two runtime has accepted Android/Web exports and verified same-APK Back/station/earned-return checks. See [3D update notes](docs/ROUND_TWO_3D.md) and HANDOFF.txt for exact source/APK identities, session restoration versus retention, and the qualified final18/closing evidence. Original native records remain tied to their original FEF0 APK; hosted CI artifacts are separate builds.

## Integration and handoff

AdMob uses Google's official test IDs. Menus support a banner, every two completed rounds create an interstitial opportunity, and rewarded benefits require the earned-reward callback. Unavailable ads or consent leave normal play usable. Google Play Games uses symbolic achievement/leaderboard maps with empty production IDs and is disabled until the owner configures them. See platform/config.json and docs/PLATFORM_SETUP.md.

Marketing text, icons, feature art and screenshot provenance are in marketing/. The current evidence, limitations and exact next owner actions are in HANDOFF.txt. Production backend testing, human playtesting and Google Play publication are human-owned.

## CI and Web

GitHub Actions imports resources, runs game/service tests with strict error checks, exports Web and validates an Android debug AAB, and uploads artifacts with the accompanying license notices. **Pages deployment is disabled**; this workflow does not publish a live site or submit to Google Play. Current build/test status is recorded below and in `HANDOFF.txt`. A passing run does not verify production services, physical devices or browser interaction.

## Continue development

Open this repository root as the game's Codex project and start a focused task for the requested change. Read `AGENTS.md`, this README, `HANDOFF.txt` and `docs/PLATFORM_SETUP.md` first; a new task must obtain its context from these files and the current Git diff, rather than assume it inherits an earlier chat. This is the active development copy; older publication/export staging copies are archival.

Recorded public CI baseline (2026-10-21): `dc8790832575cde2adcdd656a0d438e030c876b3`; [successful build/test run](https://github.com/EthannYakabuski/open-road-ramble/actions/runs/39525803252).

This game has **16 achievement** and **4 leaderboard** definitions in `game/catalog.json`. Use their symbolic keys in `platform/config.json` under `play_games.achievements` and `play_games.leaderboards`; the existing keys must remain unchanged when inserting console IDs. Play Games is currently disabled and its IDs are blank. Set `play_games.game_id`, and set the same numeric value in the Android export preset at `godot_play_game_services/game_id` in `export_presets.cfg`, before enabling the configured service. Configure the package, OAuth signing fingerprints and authorized testers in the owner consoles.

`platform/config.json` also supplies banner/interstitial/rewarded unit IDs. Its `admob.app_id` is a reference value, not the Android manifest input: set the manifest App ID through Godot Project Settings `admob/general/android/app_id`, serialized as `general/android/app_id` under `[admob]` in `project.godot`, and keep the JSON reference consistent. The missing override is normal while the plugin default is Google's sample App ID. `test_mode` in this adapter only changes the displayed status wording; it does not substitute sample unit IDs or register test devices. Keep Google sample IDs for development, or explicitly configure and verify SDK test devices before using production units. See [platform setup](docs/PLATFORM_SETUP.md).

Preserve original local packages and QA evidence. The accepted local APK hash is in `HANDOFF.txt`; hosted CI archives contain separately built binaries that have not received that local native QA. Documentation-only changes do not require rebuilding or replacing the original QA APK. Run tests with isolated process-local user-data directories, including the platform pending-service store, so the owner's real saves cannot be changed. Preserve notices and inspect explicit file diffs before staging.

## Future extension

Coastal Detours: seaside scenery, another rare traffic collection and a new touring car.

## Licenses

See [the complete accompanying notices](LICENSES/INDEX.txt) for the engine,
fonts, plugins and assets. Keep the `LICENSES` directory with every redistributed
Android or Web build; original-code Apache licensing does not replace third-party
terms. CI copies these notices beside both exports and includes them with the
Android artifact.

## Public source and local artifacts

Public repository: [Open Road Ramble](https://github.com/EthannYakabuski/open-road-ramble). Current source and this continuation documentation are tracked here. Prebuilt exports, real saves, private QA records, credentials and signing material stay outside the published source history. Local artifact availability is described in `HANDOFF.txt`; a fresh clone does not contain the original debug APK.

Original work is Apache-2.0; assets, fonts, engine and plugins retain their own terms in `LICENSES/`, `NOTICE` and source notices. Creature Mixer assets, where used, have custom non-NFT/non-blockchain terms and are not CC0.

Current runtime `bfcf2790b728e8134a4cc840d779724de462b114` is verified published with [passing source CI](https://github.com/EthannYakabuski/open-road-ramble/actions/runs/39718956764); deploy was skipped. The final docs/screenshot commit requires its own CI result. The final18capture set and closing release are verified separately below. Earlier startup/launcher ANR and host disconnection causes remain unproved. Physical devices, audible output, interactive Web and broad reliability are not established.

All 18 distinct unmodified actual current-APK views passed root visual, raw SHA256, source-capture equivalence and dimension review: six each at phone1080x1920@420dpi, logical7-inch1200x1920@320dpi and logical10-inch1600x2560@300dpi. They cover Home, driving, station, Garage, Journal and Detours. The earlier nine gameplay views retain their original genuine-session provenance; nine new menu views follow the documented genuine host-session restoration on the identical5B1APK. No rewards were replayed or state manufactured. Selected seven/ten Detours show the normally scrolled full Home control; initial-fold controls need not all be visible at once. These are logical emulator profiles, not physical tablets. Exact names/hashes are in marketing/screenshots-round-two/capture-manifest.json.

The final ONE normal cold launch at the restored original emulator phone profile first showed the Godot splash at23.08seconds, then actual Home at90.77seconds in the same launch, without ANR, relaunch or intervening input. Home onset is bounded between those observations; this is not a performance pass. All19savegroups (599bytes),3274coins/450XP,7,985.93355162478 lifetime metres,158passes and10discoveries remained byte-exact unchanged. Refuels4/rescues1/collisions3 are retained counters, not proof those branches ran in this final pass. Final stop left no process or pending inputs. Original1080x1920@420dpi/nooverrides, airplaneoff/Wi-Fiandmobiledataon and actual connected defaultWi-Fi were verified restored. A private stopped files-subtree backup has a matching embedded main save; it is not a whole-sandbox backup.

The broad native log gate is FALSE: earlier hot-display Road focus/launcher ANRs have an unproved cause, and the current retained closing slice contains one unattributed ACodec error (-1010). Scoped script/fatal/ANR/engine-error/ObjectDB/resource/VAO counts are zero, not whole-log cleanliness. No new ANR was observed in recovered flows; the final launch is a bounded observation, not a general stability/performance pass. Offline sponsor-unavailability remains unverified; no sponsor/refuel/reward was requested in this offline pass.
