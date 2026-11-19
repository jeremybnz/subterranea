# Subterranea 0.8 - fleet art guide

18 November 2026. All models are original, code-authored glTF assets. No Descent artwork or other game's ship meshes are used.

## Inspect the fleet

Open Fleet Hangar from the flight deck. Select any of seven vessels. Drag inside the preview to rotate it, use the wheel to zoom, or choose Front, Rear, Side or Auto Rotate. Manual rotation stops automatic spin. Zoom is bounded. Escape returns to the flight deck. A gamepad can select vessels and the view-preset buttons through normal menu navigation. Ship Livery provides the same preview controls.

The viewer uses its own 3D world, a lit studio platform, sky reflections, key/fill/rim lighting and cast shadows. Vessels are scaled to fit for inspection; the display is not a comparison of their physical sizes. Fleet inspection does not unlock missions, purchase upgrades or change the active run.

## Vessel designs

| Vessel | Visual identity | Mesh triangles / surfaces |
| --- | --- | --- |
| Kestrel | Split shoulders, recessed canopy, twin vector nacelles, layered wing plates, pale identification bars | 6,820 / 9 |
| Scout | Narrow sensor head, swept outriggers, small turbine pods and red optic | 4,376 / 6 |
| Striker | Double engine booms, underslung cannons, violet emitters and dorsal cooling fins | 4,632 / 7 |
| Bulwark | Broad overlapping frontal shields, amber optic and compact engine bunker | 5,232 / 7 |
| Warden | Dedicated split-crown guardian hull, raised shoulder reactors and violet rings | 6,448 / 7 |
| Overseer | Segmented armored wing, recessed command eye, four forward cannons and four engines | 9,612 / 8 |
| Courier | Protected crew capsule, cyan rescue cross, ducted vector jets and pale protective panels | 4,604 / 8 |

The first-person cannon casing uses 1,076 triangles and six material surfaces. These counts exclude animated exhaust cones and existing attack/hit indicator meshes. Warden rendering uses its dedicated asset; its combat behavior and hitbox remain separate.

## Materials and effects

Hull meshes use inset plates, chamfered edges, real vent slats, metallic collars and layered engine bores. The exporter converts authored sRGB hex colors to the linear color factors required by glTF. Dark canopy glass, pale ceramic armor and emissive identification colors distinguish surfaces. Shared procedural roughness adds subtle finish variation without downloaded textures.

The Kestrel retains Abyss, Ember, Glacier and Solar coatings. Hull/armor/accent material names remain compatible with existing saves and paint rewards. Exhaust follows the selected Kestrel accent. Enemy and courier exhaust use their role colors. A small additive shader animates the cones; it is a visual effect and does not alter movement, damage or enemy targeting.

The player still flies from the cockpit. The exterior Kestrel is visible on the flight deck and in the preview; first-person cannon housings, recoil and rail/plasma coils are visible during flight. Existing collision bodies, six-axis handling, AI and weapon statistics retain their definitions.

## Rebuild and verify

Run python tools/author_models.py to regenerate all eight binary glTF assets, then import them in Godot. scripts/ship_visuals.gd supplies exhaust and surface finish; assets/shaders/engine_plume.gdshader contains the animated plume. tools/fleet_visual.gd renders fleet, rear-engine, livery, cockpit and in-mine previews. tests/fleet.gd checks the actual fleet buttons, all seven assets, drag/zoom limits, view presets, Escape navigation and campaign isolation.

The prior version 0.7 Windows archive is preserved locally as exports/Subterranea-0.7-Windows-x64.zip. See QA_REPORT.md and PERFORMANCE.md for the current checks and measured rendering cost.
