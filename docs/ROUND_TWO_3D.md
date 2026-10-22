# 3D driving update

The current source uses real Kenney Car Kit cars, City Kit road/building models and Nature Kit vegetation in a perspective 3D world. The portrait following camera, streamed curved roads, traffic, biome scenery and Little Pine forecourt are rendered by Godot Compatibility. The forecourt combines supplied buildings and scenery with original canopy and pump details because the reviewed packs contain no named fuel-pump model. See `assets/3d/SOURCE_MANIFEST.json` and `LICENSES/Assets/` for exact supplied assets and CC0 notices.

## Controls and consequences

Drag left/right to steer; hold BRAKE to slow down near a station. Each distinct physical traffic collision removes one heart, reduces speed and cannot grant a clean-pass reward. A short grace period prevents one overlap from consuming all three hearts. Three hits offer friendly, free roadside repair. A free stop repairs the car and fills the tank; out-of-fuel assistance remains available. Rescue travel grants no distance or progression. Existing cars, upgrades, discoveries, levels and daily rewards remain. The accepted lifetime-distance day/night cycle remains across trip restarts, with real forward headlights and warm forecourt lighting at night.

Driving freezes while the application or a fullscreen ad is covered. Returning requires Resume and drops the covered frame time. Reward benefits still require the earned SDK callback; no fallback creates pretend rewards.

## Save compatibility

The existing profile filename remains unchanged. Version-1 profiles migrate to version 2 by adding a lifetime collision counter while retaining banked coins, XP, distance, purchases, discoveries, earned achievements and daily claim state. Test profiles are synthetic and isolated; never alter a real profile to produce evidence.

## Verification and remaining acceptance

Strict source import,25state,39Physics3D,40Back/station,17integrated flow and service smoke checks passed with zero exits/empty strict error lists. These are isolated source fixtures. Actual source GPU views showed driving, headlights and forecourt presentation; they are not native captures or audible-output proof.

The integrated fixture waits for its first idle-frame boundary after scene setup before sending input; `_ready` has already run. Later rapid refuel/pause/resume actions remain adjacent. Shutdown prevents new playback, and the fixture drains owned audio before removing the scene. This does not explain the original pre-first-frame resource diagnostic or establish a general mixer fix.

The focused successor routes Android Back through the intended Escape navigation and disables default Back quitting. Home stays Home, menus return Home, driving pauses and paused Back resumes. Covered input/frame time and held brake are retired. Active drive/station views hide the menu banner; earned station feedback has its own noninteractive area. Source/state/economy/service IDs and free ordinary play remain unchanged.

Accepted Android/Web exports identify source `bfcf2790b728e8134a4cc840d779724de462b114` and APK5B1FD8DC. Earlier actual native checks on that same binary establish Back/pause/brake retirement, settled station controls, one earned sponsor+200coins/+25XP with covered save held, and a normal free fill. The free-fill interval also included ordinary driving; it is not an isolated41coin/30XP reward. Source free fill is15coins/20XP. Natural collision/three-hit repair/rescue branches not observed remain source-tested, not claimed native proof.

A later actual absent-package host-session restoration recovered a genuine19-group profile before first launch; this is recovery, not cross-session retention. One subsequent actual network-none cold retained all19groups without restoration, and ordinary offline driving progressed normally. The finalbank, full18capture set and release/restoration/files-subtree backup are recorded separately below. Earlier startup/launcherANR and host disconnection causes remain unproved; neither a causal app/environment failure nor a broad stability/performance pass is inferred. HANDOFF.txt separates all dated binaries/sessions. Current source CI39718956764 passed; hosted artifacts are separate binaries.


Use Godot 4.5.1 Compatibility. Android is primary, Web secondary; the observed test preset remains min API 24/target 35 and is not a current Play release-eligibility claim. Keep official sample AdMob IDs in development and the existing disabled PGS placeholders. No Pages activation, Library operation or Google Play publication is included.

All 18 distinct unmodified actual current-APK views passed root visual, raw SHA256, source-capture equivalence and dimension review: six each at phone1080x1920@420dpi, logical7-inch1200x1920@320dpi and logical10-inch1600x2560@300dpi. They cover Home, driving, station, Garage, Journal and Detours. The earlier nine gameplay views retain their original genuine-session provenance; nine new menu views follow the documented genuine host-session restoration on the identical5B1APK. No rewards were replayed or state manufactured. Selected seven/ten Detours show the normally scrolled full Home control; initial-fold controls need not all be visible at once. These are logical emulator profiles, not physical tablets. Exact names/hashes are in marketing/screenshots-round-two/capture-manifest.json.

The final ONE normal cold launch at the restored original emulator phone profile first showed the Godot splash at23.08seconds, then actual Home at90.77seconds in the same launch, without ANR, relaunch or intervening input. Home onset is bounded between those observations; this is not a performance pass. All19savegroups (599bytes),3274coins/450XP,7,985.93355162478 lifetime metres,158passes and10discoveries remained byte-exact unchanged. Refuels4/rescues1/collisions3 are retained counters, not proof those branches ran in this final pass. Final stop left no process or pending inputs. Original1080x1920@420dpi/nooverrides, airplaneoff/Wi-Fiandmobiledataon and actual connected defaultWi-Fi were verified restored. A private stopped files-subtree backup has a matching embedded main save; it is not a whole-sandbox backup.

The broad native log gate is FALSE: earlier hot-display Road focus/launcher ANRs have an unproved cause, and the current retained closing slice contains one unattributed ACodec error (-1010). Scoped script/fatal/ANR/engine-error/ObjectDB/resource/VAO counts are zero, not whole-log cleanliness. No new ANR was observed in recovered flows; the final launch is a bounded observation, not a general stability/performance pass. Offline sponsor-unavailability remains unverified; no sponsor/refuel/reward was requested in this offline pass.
