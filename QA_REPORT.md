# Subterranea 0.9.1 - validation report

Validated on 18 November 2026 using Godot 4.7.2 on Windows. Automated tests use isolated profiles and do not alter the player's campaign. This report distinguishes scripted verification from hands-on playtesting.

## Version 0.9.1 combat polish

The current pass runs 146 checks across smoke (18), acoustics/contact feedback (18), sound bank (16), flight presentation (33), combat (40) and six live combat scenarios (21 assertions), with zero failures. Logs are exports/v091-*.log. The combat runner allows the audio mix thread to settle after scene cleanup before exiting.

Acoustic tests place real collision between source and listener, verify low-pass bus routing/attenuation, effects-volume inheritance, clear-path recovery, interface priority, pause behavior and an eight-query refresh budget. Actual pulse/rail shots verify metal/glass/armor/shield/hull contacts, retained window collision and armor damage reduction, foundry metal feedback, rate limiting and no false wall-hit damage confirmation.

Six Standard-difficulty scenarios use normal shields, no upgrades and fully active enemy AI. The scripted pilot orbits the Nereid nexus for 24 simulation seconds with each primary in cockpit and chase views; the first two seconds allow enemies to attack before returning fire. All six survive and destroy six enemies. Remaining shields range from 28 to 60. Across 1,446 sampled camera positions, none overlap world collision; the peak hull-fragment count stays below the 48-piece Balanced budget. Raw observations are tests/chase_combat.json. These small scripted fights supplement human playtesting; they do not establish comparative camera difficulty or complete-campaign survival.

Godot's internal master-bus recording captures clear/blocked/clear pulse bursts. The middle section measures about 15 dB lower and the clear level returns to its original value. Tests and the recording use only game-generated audio. Three GPU captures show actual glass, metal and armor contacts. The packaged Windows runtime additionally validates real wall muffling and impact routing. Performance is recorded in tests/performance_v091.json with other simulations stopped.

## Version 0.9 flight and sound validation

The combined update passes 283 checks across smoke (18), flight presentation (33), combat (40), profiles/manual slots (23), real-display flight (21), input/settings/training (35), exploration/rescue (62), complete chase-view campaign routes (35), and the new sound bank (16). Logs are exports/v09-*.log. No player campaign is used by these tests.

The presentation suite verifies actual camera sphere clearance, full attitude rotation, automatic cockpit fallback/return, legacy custom T precedence, default touchpad events, actual boost mesh/material power, directional shield state, low-integrity smoke/scorch, repair, map pause, all four weapon hits, and low cover that is visible over from the camera but still blocks every ship weapon. It also checks actual six-part mesh breakups, duplicate-death guards, the 48-part Balanced cap, real wall bounces, expiry, restored damage appearance and boss/player death flow.

All three operations complete through actual movement, objectives, final boss phases and escape with chase requested. These route scenarios use high test shields and frozen/nonblocking ordinary enemies; they validate geometry and flow rather than normal-shield survival. tests/campaign_routes_chase.json records the results. Physical controller feel remains untested; input events are simulated.

Sixteen sound-bank checks cover imported mono 44.1 kHz playback, loop bounds, non-repeating variants, actual trigger routing, concurrency, independent effects/music gain, afterburner response, pause/interface behavior, master limiter, the new settings control and source provenance. All thirty prepared files decode with zero full-scale clipped samples and peaks below 0.8; the three loop boundaries also pass a discontinuity check. Per-file results are tests/audio_levels.json. Original Kenney CC0 license and a source/transformation manifest are included.

Eleven staged GPU captures show flight, boost, shield damage, smoke/scorch, actual hull breakup, fragments, clearance and settings. Brief shield/smoke moments are held at a representative lifetime for some images. Native Windows checks validate all operations, training, map, saves, profiles, fleet, chase, damage, breakup and the imported sound bank; additional native GPU captures inspect the new presentation. Performance is recorded in tests/performance_v09.json after other gameplay simulations finish. PCM and scripted checks do not replace listening on a range of speakers/headphones.

## Version 0.8 fleet validation

The current art update runs targeted smoke, real-display flight, combat, exploration/rescue and fleet-viewer suites: 156 checks, zero failures. They cover actual ship selection, all seven imported hulls and exhaust assemblies, independent drag rotation, zoom and its near bound, rear/automatic view presets, Escape navigation and unchanged campaign progress. Existing checks cover pulse/plasma/rail behavior, Warden attacks, active checkpoint restoration, hull paints and all three physical courier routes. Collision and gameplay values retain their existing definitions.

Eleven in-engine fleet/gameplay screens and nine close-up viewport renders show every vessel, Kestrel rear engines, Ember paint, first-person cannon housings and a targeted drone in the mine. The Windows build validates all operations, training, map, saves, profiles and Fleet Hangar. Additional GPU captures exercise the exported fleet viewer. Performance is measured after other gameplay checks finish in tests/performance_v08.json. Controller menu input still needs physical-device validation; the fleet can be selected through the existing menu focus system.

## Version 0.7 full regression baseline

- Smoke: core flight/collision, relays, reactor gates, weapons, pickups and win/loss flow.
- Expansion: ship-sized route clearance, moving doors, alternate reactor entrance, secret rewards, enemy armor, telegraphed projectiles, navigation, positional audio and containment failure.
- Campaign: real profile write/read and backup recovery, duplicate reward rejection, all upgrade levels, checkpoint restoration, archive interaction, unlocks, boss attacks/beam avoidance/phase shielding and final completion.
- Flight with a real display backend: WASD/lift/roll, boost, drift, braking, assist, mouse steering, pulse hits, map and pause/resume.
- Readiness: remapping and conflict swapping, saved binding round trip, simulated sticks/deadzone, Start pause/resume, A/Cross menu activation, FOV, graphics and difficulty effects, briefings, vertical projectile spread, and the entire physical training course through certification. Training preserves the active checkpoint and grants no campaign rewards.

The version 0.7 full baseline passed: 373 checks, zero failures. Logs are generated under `exports/v07-*.log`. No physical controller was connected; analog events and button presses were simulated through Godot's input system. Controller feel and device-specific mappings still need a hands-on check.

- Combat update: real plasma travel and splash, close-wall blocking, rail hold/release/piercing and energy costs, shared upgrades, squad attack admission, flanking, radio alerts, retreat and patrol decisions, warning/live/offline hazard intervals, machinery blasts, one-shot ambush triggers, restored arrival markers, two trial waves, Warden overdrive, supplies and salvage rewards, legacy custom-binding precedence, and both completed and active encounter checkpoints.

## Exploration update

The exploration suite passed 62 checks: old-profile migration, canonical discovery/reward guards, real profile write/read, solid observation glass, all nine recorder interactions, all cache/paint rewards and actual hull materials, crew recovery, waiting, disable/repair, active courier checkpoint restoration, incoming projectile damage, enemy courier targeting, journal/pause navigation, all three physical escort routes, duplicate delivery guards, extraction bonuses, radio transcripts, mix ducking, pause UI audio and bounded weapon voices. Ten rendered previews cover all vistas, rescue, journal, radio, livery, rail charging and effects.

Five additional normal-shield, live-AI escort scenarios completed successfully. See `EXPLORATION.md` for measurements and limitations. Geometry-focused escort checks freeze ordinary enemies; active-AI observations do not. The final benchmark is recorded separately in `tests/performance_v06.json`.

## Navigation and campaign profiles

Version 0.7 adds 55 navigation/security/foundry/rating checks and 23 real-file profile/manual-slot checks. These cover map simulation freeze, mouse rotation without steering, zoom/filters, surveyed pins, extraction priority, survey JSON restoration, locked graph edges and actual gate collision, all three key pickups and alternative local switches, real CharacterBody3D flight through all three new shortcuts, required-objective preservation, production capacity/replacement/shutdown, persisted foundry state, rating thresholds and best-record retention.

Profile tests preserve the existing Pilot 1 bytes during selection, repeatedly replace the selector file, reload the actual main scene, isolate all three campaigns, save all three manual slots, require occupied-slot/load confirmation, retain permanent purchases/discoveries when loading an older mission and reject duplicate completed-run rewards. They use a temporary project fixture directory and remove only their own files.

Three additional Standard-difficulty foundry scenarios use normal shields, no upgrades and active enemy AI. A stationary scripted pulse pilot observes two production cycles, destroys the machine through actual weapon input and then waits nine seconds. All three stop production and survive. These narrow scenarios verify production/shutdown, not complete encounter difficulty; machine-generated timings are in tests/foundry_balance.json. No enemy is frozen in these runs. All three complete campaign route checks and the full physical training course passed again.

Twelve in-engine previews cover partial/full/rotated maps, gate, key, override, live/offline foundry, manual slots and confirmation, pilot profiles and medal debrief. NAVIGATION.md contains exact controls and rules. Performance measurements are recorded in tests/performance_v07.json.

## Version 0.5 combat measurements (historical)

Fifteen normal-shield scenarios exercise live enemy AI: all three primaries across Pilot/Standard/Ace in Nereid, three Standard Helios vault trials, and three stationary no-fire controls. These are automated scenarios with scripted aiming and movement, not human completion times. Existing enemies can join the open vault trial. `COMBAT_BALANCE.md` contains the final measurements and limits; `tests/combat_balance.json` contains the raw data. No enemies are frozen and no test shield multiplier is applied in this suite.

## Complete campaign route scenarios

A bot flew the real CharacterBody3D through the normal route graph, doors, vertical shafts, objective approaches and extraction triggers using normal thrust, boost and braking. Pulse shots, archive downloads/uploads and the live three-phase boss sequence completed all three operations. The ship used no installed upgrades.

| Operation | Scripted scenario seconds | Escape seconds used | Allowed escape seconds | Result |
| --- | --- | --- | --- | --- |
| Nereid | 64.0 | 9.6 | 75 | Won |
| Boreas | 64.2 | 9.7 | 90 | Won |
| Helios | 67.4 | 12.1 | 90 | Won |

Source results are in `tests/campaign_routes.json`. These runs use very high test shields and freeze ordinary enemies with their blocking collision disabled. They verify navigation, collision with the level, objective gates and completion; they do not measure realistic combat survival or human completion time. Route travel leaves generous escape headroom for searching and combat, so the existing timers were retained. Tightening them needs human evidence.

## Balance review

The first Nereid completion awards at least 1,150 salvage before kill/secret bonuses. Base upgrades cost 500-650, allowing an early meaningful choice. A minimum first-clear campaign awards 4,200 salvage; fully upgrading every system costs 11,100, leaving room for replay progression. Purchasing and reward guards passed. Pilot/Standard/Ace incoming damage factors offer adjustable pressure without changing objective routes or escape budgets. No unsupported claim of fully human-balanced combat is made.

Training testing exposed a lesson that required boost speed at the exact marker. It now remembers that the pilot reached boost speed, allowing safe braking on approach. Controller testing exposed missing default confirm/cancel pad bindings; these are now explicitly installed. Vertical projectile fans now remain distinct when aiming straight up or down.

## Release and presentation checks

The build script verified all three operations plus training from the exported native Windows executable. Additional version 0.7 native release runs render and validate the 3D map, occupied manual save screen and three pilot cards. The earlier fusion vista and livery captures remain under exports/v06-native-*.png. The release includes the PCK, instructions, this report, performance notes and Godot notices. No editor, .NET or installer is needed to play. The unsigned build has not undergone storefront certification.

Ten version 0.4 presentation screenshots were captured in-engine. The earlier combat update adds six version 0.5 captures showing new weapons, a live coolant hazard, Warden phases and expanded controller bindings under `exports/combat-preview/`. The 26.6-second trailer is H.264 1280 x 720 at 30 FPS with stereo AAC, original score and effects. The finished file was fully decoded without codec errors and representative frames were inspected. Cameras and encounters are staged for presentation; menu progress uses an isolated profile. The local press kit has not been published.

The 0.6 exploration update adds ten in-engine screenshots. Version 0.7 adds twelve navigation/save/medal previews and a separate preview archive.

Remaining external validation: ordinary human campaign combat at all difficulties, physical gamepads, and a broader hardware sample. The active-enemy scenarios now supplement the earlier navigation-only checks. These are release candidate limitations, not completed human tests.
