# Subterranea 0.6 - exploration and rescue

17 November 2026. This update adds original environmental scenery, story writing, optional rescue routes and cosmetic discoveries across the existing three-operation campaign.

## Content and controls

- Observation windows: upper Nereid relay room, Boreas Archive Beta, and the Helios Overseer chamber. Glass is solid; exterior drilling, ice and fusion-array scenery cannot be flown into.
- Nine data recorders and twelve radio captions. Hold the remappable interaction control for 1.5 seconds within 4.3 meters to download a recorder. Mission Journal is available on the deck and pause menu, with location hints, heard transcripts and live/best discovery tracking. Radio uses text captions and a cue, without recorded speech.
- One crew refuge and one rescue courier per operation. Crew recovery earns 250 salvage on successful extraction. Courier delivery adds 300 salvage and 700 score. Escort work does not lock the main mission or exit.
- Courier integrity starts at 160, with slow regeneration after four seconds without damage. Stay within 20 meters. It waits outside that radius; if disabled, hold interaction nearby to restore 100 integrity. Enemy squads can target it, friendly weapons ignore it, and unlocked doors respond to its approach.
- Three one-time survey caches grant 200 salvage, repair +25, energy +40, missiles +2 and Ember/Glacier/Solar paint. Equip coatings in Ship Livery; its rotating stage shows the actual model with the selected material overrides. Paint changes hull, trim and friendly trails without changing combat statistics.
- New weapon mechanisms, ship/missile trails, hot explosion cores and streak sparks. Performance mode omits the additional trails and explosion details.
- Separate weapon, impact, ambience, music and interface mix categories. Radio and impact events briefly duck competing layers; transient voices are bounded and interface cues remain audible during pause. Mixer gains change only when needed.

## Physical route validation

The exploration suite flies both the real pilot CharacterBody3D and courier along each rescue route through doors and shafts. Ordinary enemies are frozen in this geometry-focused test. All three couriers reached the arrival dock. Separate checks apply real enemy projectile damage, force a repairable disable, restore active route/integrity data, and verify one-time rewards and migration from older profiles.

| Operation | Physical route seconds | Result |
| --- | --- | --- |
| Nereid | 28.2 | delivered |
| Boreas | 30.1 | delivered |
| Helios | 20.5 | delivered |

## Active-enemy escort observations

A scripted pilot starts at the refuge pod, uses normal 100-point shields with no upgrades, and escorts using pulse fire and missiles. Every enemy AI remains active. Time scale 5 and 120 physics ticks accelerate the simulation. These are short development scenarios with automated aim, not human difficulty or completion-time measurements.

| Operation | Difficulty | Seconds | Courier | Ship shield | Minimum courier integrity | Kills | Missiles left |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Nereid | Standard | 28.2 | delivered | 100.0 | 160.0 | 8 | 6 |
| Boreas | Standard | 30.1 | delivered | 100.0 | 160.0 | 7 | 6 |
| Helios | Standard | 20.6 | delivered | 100.0 | 160.0 | 5 | 7 |
| Nereid | Pilot | 28.2 | delivered | 100.0 | 160.0 | 8 | 6 |
| Nereid | Ace | 28.2 | delivered | 100.0 | 160.0 | 8 | 6 |

All five cases delivered the courier. Automated aim eliminated most threats before they could charge attacks, and no courier required repair in these cases. Repair and damage handling are covered separately; these runs do not establish human escort difficulty. Raw data: `tests/rescue_balance.json` and `tests/exploration_routes.json`.

## Saves and review limits

Profiles retain the existing version-1 schema with optional new fields. Old unlocks, upgrades, currency, records and checkpoints remain compatible. Collected logs, radio history, caches and coatings save immediately. Crew/courier records require extraction. Active checkpoints include route waypoints, position, integrity, disabled/waiting state, crew recovery and caption/queue progress.

The journal differentiates the current paused run from permanent extraction records. A functioning courier already within 12 meters of the dock, with a clear path to it, can be recovered during ship extraction; this avoids losing a completed escort because the player enters the arrival chamber a few meters ahead. Disabled or distant couriers do not receive that credit.

Ten previews in `exports/exploration-preview/` show actual engine scenes with scripted cameras and an isolated presentation profile. The native game remains unsigned and local. Human campaign playtesting, physical controller feel and broader hardware validation remain useful follow-up checks. Flight speed, sensitivity defaults, incoming-damage factors and escape timers were retained without user playtest evidence.
