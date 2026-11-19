# Subterranea - performance notes

The first table records the version 0.4 optimization pass. Measured locally on Windows with an NVIDIA GeForce RTX 3050 and Godot 4.7.2 Compatibility renderer. The same benchmark positions and default Balanced settings were used before and after optimization, with vsync disabled. Each operation warmed up for 30 frames, then sampled 100 uncapped frame intervals. These are short, single-run development measurements, not minimum requirements or a guaranteed frame rate. Other applications, drivers and scene activity affect results.

| Operation | Draw calls before / after | Nodes before / after | Mean frame ms before / after | 95th percentile ms before / after | Scene setup ms before / after |
| --- | --- | --- | --- | --- | --- |
| Nereid | 1,129 / 456 | 4,289 / 1,491 | 18.95 / 6.19 | 28.50 / 8.44 | 1,599 / 911 |
| Boreas | 936 / 314 | 3,567 / 1,199 | 7.76 / 4.22 | 9.18 / 5.67 | 1,331 / 379 |
| Helios | 329 / 195 | 3,521 / 1,132 | 4.68 / 3.62 | 5.96 / 4.50 | 1,005 / 355 |

Scene setup measures instantiation/build work inside an already-running engine, excluding process launch and first import. Node counts are sampled after deferred deletion. Draw calls are a scene sample rather than a campaign-wide maximum. Resolution was not recorded in the archived JSON; avoid comparing these values with other machines or display configurations.

## Changes

- Bake immutable decorative meshes by material, primitive type and 32 x 24 x 32 meter spatial cell. Preserve physics bodies at their world transforms. Doors, objectives, pickups, animated machinery and authored moving models remain independent.
- Load the original synthesized score and sound effects from cached resources instead of synthesizing them every time a mission loads.
- Update the aim ray at 20 Hz rather than every physics tick. Projectile and movement physics retain their existing update rate.
- Offer three graphics presets: Performance uses 70% 3D scale with MSAA/glow/dust disabled; Balanced uses native scale, 2x MSAA and effects; Quality uses native scale and 4x MSAA.

The physical training and campaign route checks passed with batching enabled, including doors and both vertical shafts. Retain a human session on lower-end hardware as a release candidate check. Reproduce with `tools/benchmark.gd`; source measurements are `tests/performance_baseline.json` and `tests/performance_current.json`.

## Version 0.5 combat update

17 November 2026. Same RTX 3050 / Compatibility renderer, native 1600 x 900 viewport, Balanced preset and vsync disabled. The final run was taken after the other game simulations finished. It uses the same short 30-frame warm-up and 100-frame sample; compare only as a local scene snapshot. New hazards, labels, supplies and squad logic add some work.

| Operation | Draw calls | Nodes | Mean frame ms | 95th percentile ms | Scene setup ms |
| --- | --- | --- | --- | --- | --- |
| Nereid | 465 | 1544 | 6.84 | 9.45 | 1023 |
| Boreas | 325 | 1252 | 5.85 | 9.01 | 443 |
| Helios | 202 | 1185 | 4.72 | 6.43 | 414 |

Raw data: `tests/performance_v05.json`. Reproduce with `tools/benchmark.gd -- --combat-v05`. Decision updates for patrol/flank/retreat target selection run at approximately 6.7 Hz; movement, collision and firing keep the regular physics update. The earlier before/after figures are historical and are not a promise of these frame times on other systems.

## Version 0.6 atmosphere and exploration

17 November 2026. RTX 3050, Compatibility renderer, Balanced preset, 1600 x 900, vsync off, 30 warm-up frames and 100 sampled uncapped frame intervals. All other gameplay simulations had finished. Exterior lights were limited to the vista area, and audio bus gains are updated only on transitions. This is a short local snapshot, not a frame-rate guarantee.

| Operation | Draw calls | Nodes | Mean frame ms | 95th percentile ms | Scene setup ms |
| --- | --- | --- | --- | --- | --- |
| Nereid | 493 | 1647 | 7.68 | 10.68 | 1206 |
| Boreas | 333 | 1334 | 7.03 | 9.95 | 502 |
| Helios | 230 | 1269 | 5.22 | 7.00 | 407 |

The extra scenery, moving trails and interaction actors add render work relative to 0.5. The livery stage creates its separate viewport only while its screen is open. Reproduce with `tools/benchmark.gd -- --exploration-v06`; raw data is `tests/performance_v06.json`.

## Version 0.7 navigation and profiles

18 November 2026. RTX 3050, Compatibility renderer, Balanced preset, 1600 x 900, vsync off. Same 30 warm-up / 100 sampled frames, after all other gameplay simulations stopped. New service geometry and independently animated foundries add scene work. Profile cards cache file summaries when opened rather than reading save files every rendered frame.

| Operation | Draw calls | Nodes | Mean frame ms | 95th percentile ms | Scene setup ms |
| --- | --- | --- | --- | --- | --- |
| Nereid | 534 | 1849 | 16.35 | 23.27 | 2286 |
| Boreas | 332 | 1486 | 4.55 | 6.51 | 601 |
| Helios | 336 | 1448 | 5.27 | 7.39 | 411 |

These short samples varied between launches; they are observations, not campaign-wide frame-rate guarantees. Reproduce with tools/benchmark.gd -- --navigation-v07. Raw final data is tests/performance_v07.json. The automap pauses world simulation, and its render workload depends on survey coverage and zoom.

## Version 0.8 fleet art

18 November 2026. RTX 3050, Compatibility renderer, Balanced preset, 1600 x 900, vsync off. Same 30 warm-up frames and 100 sampled intervals; other gameplay simulations had finished. New hull geometry, roughness sampling and two exhaust cones per ordinary drone add rendering work. A ship uses one imported mesh with six to nine material surfaces; separate individual vent/plate nodes are avoided. The studio viewport exists only while Fleet Hangar or Ship Livery is open.

| Operation | Draw calls | Nodes | Mean frame ms | 95th percentile ms | Scene setup ms |
| --- | --- | --- | --- | --- | --- |
| Nereid | 569 | 1898 | 8.11 | 12.30 | 1441 |
| Boreas | 353 | 1524 | 11.96 | 16.27 | 542 |
| Helios | 349 | 1499 | 12.47 | 16.91 | 936 |

Reproduce with tools/benchmark.gd -- --fleet-v08. Raw data is tests/performance_v08.json. These are short development observations, not minimum requirements or a guaranteed frame rate; the scene timing varied between launches. The fleet studio enables additional shadows and reflections within its own viewport, so its cost is separate from these combat-scene samples.

## Version 0.9 flight and sound update

18 November 2026. RTX 3050, Compatibility renderer, Balanced preset, 1600 x 900, vsync off. The final run follows all other gameplay simulations and the audio integration. Each scene warms for 30 frames and samples 100 intervals. This standard snapshot uses the cockpit and ordinary scene activity; it is not a sustained worst-case debris benchmark. Short-run timings vary between launches.

| Operation | Draw calls | Nodes | Mean frame ms | 95th percentile ms | Scene setup ms |
| --- | --- | --- | --- | --- | --- |
| Nereid | 569 | 1985 | 7.84 | 12.29 | 1466 |
| Boreas | 350 | 1587 | 5.25 | 6.56 | 513 |
| Helios | 354 | 1552 | 5.15 | 6.58 | 505 |

Damage shells/scorches stay hidden on healthy ships. Actual hull chunks are capped at 24/48/72 by preset, expire within four seconds and use throttled ray casts rather than rigid-body collision. Shared particle-count checks bound new damage smoke. The sound bank loads once per scene; voices retain concurrency caps and mix-bus updates are cached. Reproduce with tools/benchmark.gd -- --flight-v09; raw final data is tests/performance_v09.json. These figures are local observations, not minimum hardware requirements or a frame-rate promise.

## Version 0.9.1 contact and acoustic polish

18 November 2026. Same RTX 3050, Compatibility renderer, Balanced settings, 1600 x 900, vsync off, 30 warm-up frames and 100 sampled intervals after the gameplay simulations finished. Source occlusion uses at most eight ongoing ray casts per 80 ms refresh, plus initialization for new voices; voices retain their existing caps. Filter routing and gain changes avoid redundant property updates. This remains a short scene snapshot, not a stress-test or frame-rate guarantee.

| Operation | Draw calls | Nodes | Mean frame ms | 95th percentile ms | Scene setup ms |
| --- | --- | --- | --- | --- | --- |
| Nereid | 570 | 1989 | 9.00 | 11.63 | 1835 |
| Boreas | 350 | 1587 | 5.15 | 6.38 | 499 |
| Helios | 348 | 1556 | 6.45 | 9.93 | 545 |

Raw data: tests/performance_v091.json. Reproduce with tools/benchmark.gd -- --polish-v091. Live normal-shield combat measurements, camera-clearance samples and fragment counts are recorded separately in tests/chase_combat.json.
