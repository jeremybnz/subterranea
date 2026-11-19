# Subterranea — The Nereid Campaign

An original six-degrees-of-freedom combat flight game inspired by Descent. Three connected operations, three primary weapons, squad tactics, interactive hazards, optional combat trials, permanent upgrades, mission checkpoints, detailed ship hulls, an interactive fleet viewer, two boss encounters, crew rescues, an interactive 3D automap, optional security shortcuts, robot foundries, mission medals, three campaign profiles and an original story journal. Built in Godot 4.7.2 with original code, geometry, UI and synthesized music, plus CC0 Kenney sound effects; no Descent assets or code are included.

## Play the Windows release

Extract **Subterranea-Windows-x64.zip** into a folder and double-click **Subterranea.exe**. Keep **Subterranea.pck** beside the executable. Godot, .NET, Python and an installer are not required to play. This is an unsigned local Windows x64 build.

The source project can also be opened in Godot using **project.godot**, or run through **Launch.bat** with the engine in `C:\Development\Godot`.

Start with **Training Hangar** for eleven interactive flight checks. Press Enter to review the selected operation briefing, then Enter again to deploy; Continue Checkpoint restores directly. **Campaign** shows unlocked operations, completion records, best scores, fastest times and discovered secrets. **Upgrade Bay** installs permanent improvements with salvage earned from completed missions.

## The campaign

### 01 — The Nereid Incident

Explore the mining complex across three elevations. Disable the lower foundry, coolant and turbine relays, destroy the reactor, and return to the arrival dock before the 75-second containment timer ends. Both reactor entrances remain locked until the relays are disabled. A side route through the pump hall provides an alternate return path.

### 02 — Cold Signal

Recover three encrypted archives in Boreas's cryogenic station. Approach each archive within 5.6 meters and **hold the interaction control (R by default) for two seconds**. Weapons cannot recover archive data. After all three downloads, the orbital uplink unlocks. Approach it and **hold the interaction control for three seconds**, then return to extraction before the 90-second response-fleet timer ends.

### 03 — Heart of the Machine

Destroy three shield nodes in the Helios fortress: west, deep and crown. The crown node is reached through the flight shaft above the boss chamber, which is accessible while the Overseer remains shielded. Once its generators are down, defeat the Overseer:

- Phase one fires aimed spreads.
- Phase two fires radial barrages and summons escorts.
- Phase three marks a beam line before firing. Move away from that line to dodge.

Short transition shields prevent bypassing entire phases. Destroying the Overseer starts the final 90-second escape. Reach the arrival dock to complete the campaign.

Each operation has a concealed reserve vault. Breach fractured maintenance plating with pulse fire, enter the vault for a full repair, boost recharge and 1,000 mission points, and collect its supplies.

## Controls

| Input | Action |
| --- | --- |
| Mouse | Steer and aim; unlimited pitch and roll |
| W / S | Forward / reverse |
| A / D | Strafe left / right |
| Space / Ctrl | Rise / descend along the ship's local axes |
| Q / E | Roll |
| Left mouse | Fire selected primary; hold and release to charge the railgun |
| 1 / 2 / 3 | Select pulse / plasma / railgun |
| V | Cycle primary weapon |
| Right mouse | Seeker missiles; home on visible drones and the Overseer near the crosshair |
| Shift | Afterburner |
| C | Airbrake |
| R (hold) | Archives, recorders, crew rescue/repair, local security overrides and combat trials |
| Tab | Interactive 3D automap; pauses flight while open |
| T | Toggle cockpit / chase view; automatically retracts near walls |
| F | Toggle headlight |
| Escape | Pause / resume; back out of settings |
| F11 | Fullscreen |

Flight assist brakes after thrust release. Disable it in settings for inertial drift; C brakes in either mode. Boost increases speed, field of view and engine pitch. Hard wall impacts damage shields. Cyan pickups restore 35 shields; violet pickups restore 40 energy; amber pickups replenish missiles. Weapon energy and boost recharge automatically.

Scouts flank. Strikers lead moving targets using projectile travel time. Enemies patrol, share visible alerts, separate from squadmates, and limit nearby simultaneous attackers to two. Damaged drones make a brief retreat toward cover. Bulwarks carry frontal armor: flank them or use explosive missiles. Attacks visibly charge before firing. The HUD includes target health, seeker lock, directional damage arcs, altitude, attitude, local radar and a gold route guide through the mine's actual connections.

## Map, security routes and mission medals

Press **Tab** to inspect the explored mine in 3D. Left-drag rotates, right-drag pans, the wheel zooms, **R** recenters, and **1/2/3** toggle objectives, contacts and supplies. Click a surveyed node to pin it; **Delete** clears the marker. **Tab** or **Escape** closes the map. Gamepad controls are shown on screen. Pins follow accessible route connections, and extraction guidance takes priority during escape.

Each operation has a colored service key and a local security override (**hold R for 1.5 seconds**). Either opens the optional route. Purple **robot foundries** warn before fabricating scouts and strikers; shoot them to stop production. They can maintain at most three living reinforcements and stop producing during evacuation.

Successful extraction awards **combat, exploration, rescue and escape medals**, producing an overall **D-to-S rank**. The campaign retains your best category medals and highest overall rank. See **NAVIGATION.md** for route details and exact rating thresholds.

## Chase view, damage and breakup

Press **T** during flight for the optional chase camera, or choose **View** in Flight Settings. The action is remappable; touchpad click is the default pad event. The camera follows full pitch/roll, retracts near walls and temporarily restores the cockpit in tight spaces. Fire still originates at the ship and respects intervening cover.

Engines respond to thrust and boost. Hits create directional shield ripples and sparks; low integrity adds scorch marks, smoke and engine flicker. Repairs clear the damaged appearance. Destroyed ships shed actual armor and engine pieces that spin, bounce and expire. These are cosmetic and do not obstruct flight. See **FLIGHT.md** for exact behavior and limits.

The sound update uses thirty prepared **Kenney Sci-fi Sounds (CC0)** effects/loops for weapons, impacts, explosions, doors and engines. Set their volume separately from music with **Sound Effects** in Flight Settings. Source credits and transformations are in **SOUND.md** and the included notices. World sounds now muffle through walls and doors, while interface cues stay clear. Weapon strikes distinguish metal, reinforced glass, armor, shields and damaged hulls.

## Training, controllers and options

The safe Training Hangar teaches thrust, strafing, lift, roll, boost, braking, pulse fire, missiles, the map, vertical shafts and a held interaction. Follow its gold markers to earn flight certification. Training cannot damage the ship, spend salvage, unlock operations or replace a campaign checkpoint.

Open **Flight Settings > Controls**, select keyboard/mouse or gamepad, choose an action and press the new input. Conflicts swap assignments so no action loses its binding. Escape cancels capture. Enter, Escape and F11 remain available for menus. Bindings save automatically; **Restore Default Bindings** resets both devices. Flight prompts follow the current input device and bindings.

Default gamepad layout uses Xbox names (equivalent PlayStation controls work through Godot's controller mapping):

| Input | Action |
| --- | --- |
| Left stick | Forward/reverse and strafe |
| Right stick | Steer/aim |
| A / B | Rise / descend |
| LB / RB | Roll |
| Left / right stick click | Boost / brake |
| RT / LT | Selected primary / missile |
| D-pad up / left / down | Pulse / plasma / railgun |
| D-pad right | Cycle primary |
| X / Y | Interact / headlight |
| Back / Start | Map / pause |
| D-pad or left stick in menus | Navigate |
| A / B in menus | Confirm / back |

Display settings offer a 65-100 degree field of view, 75-100% HUD size, controller look speed and stick deadzone. The tactical map remains full size. Performance, Balanced and Quality presets control render scale, antialiasing, glow and dust. Difficulty changes incoming damage: **Pilot 65%**, **Standard 100%**, **Ace 130%**. These options and flight/audio settings save automatically.

## Weapons and encounters

All three primaries are available on deployment. They share the rechargeable capacitor and Pulse Amplifier upgrades; missiles remain on the secondary trigger. Training uses pulse so its target checks stay consistent.

| Primary | Role | Base energy and damage |
| --- | --- | --- |
| Pulse / Mk II | Instant rapid fire; efficient against light drones | 3 energy, 18 damage, 0.135 second interval |
| Plasma / Cyclone | Traveling 42 m/s projectile with 3.8 m splash; bypasses frontal drone armor | 9 energy, up to 52 damage with splash falloff, 0.38 second interval |
| Rail / Lancer | Hold fire up to 0.85 seconds, release to fire; pierces up to three bodies and bypasses frontal drone armor | 16-28 energy, about 52-110 damage; successive penetrations retain 80% damage |

Rail charge requires at least 25% before release. Switching weapons or resuming from pause cancels charge. Walls stop all weapons. Plasma does not home; lead moving targets. The Overseer's explosive resistance also reduces plasma and armor-piercing rail damage. The HUD shows the selected weapon and rail charge; every selection displays a handling hint.

Each operation includes a delayed response-team ambush with visible arrival rings and an announcement. Coolant valves and arc power cells warn before cycling live, damaging nearby ships during their active interval. Shoot their marked cells to shut them down. Volatile machinery explodes when destroyed, damaging nearby enemies and the ship. Hazard cells use their own weapon collision layer and do not form invisible flight barriers.

Each concealed supply vault contains a purple **optional combat trial** console. Hold the interaction control within five meters for two seconds to begin. Clear two waves; retreat remains open. Nereid and Boreas end with armored reinforcements. Helios ends with the **Warden**, a 460-shield guardian with spread attacks and radial overdrive below half health.

Clearing a trial grants repair +25, energy +40, missiles +3 and score (1,000; 1,500 in Helios). Successful extraction adds 300 salvage and saves a trial-completion record. Trial rewards can only be claimed once per run. Trials close when the mission's escape sequence begins; the campaign can be completed without entering them.

## Exploration, story and rescue

Each operation now has an observation vista: Nereid's rotating drilling array, Boreas's frozen excavation face and Helios's animated fusion array. Observation glass stops ships and weapons; the vista is exterior scenery. Damaged supports and caution markings distinguish service areas without obstructing the flight routes.

Find **three data recorders per operation**. Approach within 4.3 meters and hold the interaction control (R by default) for 1.5 seconds. Read collected writing in **Mission Journal**, available from the flight deck and pause menu. Unknown recorder entries give location hints. Radio messages arrive as readable captions with a short radio cue; heard transmissions remain in the journal. This update does not include spoken voice acting.

Each operation contains a green **crew refuge**. Hold interaction for 1.5 seconds to secure its crew aboard the Kestrel and launch the rescue courier. The crew earns **250 extra salvage on successful extraction**. Escorting the courier safely to the arrival dock earns **300 more salvage** and 700 score.

- Stay within **20 meters**; the courier waits when you fall behind.
- It follows the physical route graph, including shafts, and can open unlocked proximity doors.
- Some enemy squads target it. Integrity starts at 160 and regenerates slowly after four seconds without damage.
- A disabled courier stays repairable: approach within 4.3 meters and hold interaction for 1.5 seconds. It returns with 100 integrity.
- A functioning courier already inside the arrival chamber can be recovered with your ship's extraction. Couriers left far behind or disabled need further attention to earn their delivery bonus.
- Rescue work is optional and never locks the main objectives or exit.

Each operation also has a **survey cache**. Fly within 1.8 meters to discover it. Its first discovery grants 200 salvage, repair +25, energy +40, missiles +2 and an exclusive paint scheme: **Ember**, **Glacier** or **Solar**. Cache salvage and paint unlocks are awarded only once per profile. Equip unlocked coatings in **Ship Livery** on the flight deck; its rotating preview shows the actual Kestrel hull. Paint affects hull, cockpit trim and friendly engine trails, with no gameplay stat changes.

The journal tracks recorders, caches, refuge crew, courier delivery, reserve vaults and combat trials; the map surveys rooms, objectives, contacts, supplies, keys and foundries. Discovery and paint progress saves immediately; rescue records and extraction bonuses save on successful mission completion. Active checkpoints include crew recovery, courier position/integrity/route, caption progress and queued story events. Older profiles and checkpoints remain compatible.

## Progress and upgrades

Completing an operation earns salvage, including bonuses for kills, secrets and its first completion. Replays also earn salvage and can improve your best score and fastest time. A run can claim its completion reward only once.

Each ship system has three upgrade levels:

| System | Improvement per level |
| --- | --- |
| Aegis shields | +25 maximum shields |
| Vector engines | +10% flight speed and acceleration, reduced boost drain |
| Pulse amplifier | +4 pulse, +8 plasma and +15 rail damage; faster pulse/plasma fire and energy recovery |
| Seeker rack | +25 blast damage, +2 starting missiles, improved homing and pickups |

Upgrades apply to all operations and save immediately. The upgrade bay shows the exact next cost and effect. A new deployment fully services the ship. Restoring a checkpoint preserves the saved shield, energy, ammunition and boost amounts with the installed upgrades.

## Saving and continuing

Mission progress auto-saves every 20 seconds. Pause-menu **Save & Return to Flight Deck**, **Save & Quit**, and closing the game also save a checkpoint. Choose **Continue Checkpoint** to restore it. Checkpoints preserve position and orientation, ship resources, remaining enemies, collected objectives, score, secret access and boss phase. Version 0.5 also preserves selected primary, destroyed hazard cells, ambush completion, trial waves and their exact surviving enemies. Existing 0.4 checkpoints load with the new encounter systems ready. In-flight projectiles and temporary visual effects are cleared when restoring.

Restarting a mission begins a fresh run and clears the active checkpoint; completed operations, salvage, upgrades and best records remain. Death clears the active checkpoint. Manual slots remain available. Open **Profiles & Saves** on the flight deck to choose among **Pilot 1 / 2 / 3**. Pilot 1 keeps your existing campaign. Each profile owns its upgrades, discoveries, records, autosave and **three manual save slots**; settings are shared.

During flight use **Escape > Manual Saves > Save Current Run**. Occupied slots require **Confirm Overwrite**. Loading requires **Confirm Load** and restores that mission snapshot while retaining current permanent upgrades, discoveries and earned rewards. A completed run cannot claim its salvage twice. Profiles can be switched from the flight deck; return there before changing pilots.

Save files are stored in Godot's Windows user-data directory, normally:

`%APPDATA%\Godot\app_userdata\SUBTERRANEA\`

- `campaign_v1.json`: Pilot 1 campaign, records, upgrades, autosave and manual slots
- `campaign_2_v1.json`, `campaign_3_v1.json`: Pilot 2 and Pilot 3
- `profiles.cfg`: active pilot selection
- `campaign_v1.json.bak`: previous valid profile
- `flight.cfg`: flight/audio options, bindings, controller response, FOV, HUD size, graphics and difficulty

Saves are written through a validated temporary file. A damaged primary profile falls back to the previous copy. Unreadable originals are preserved rather than overwritten. A storage error is reported in the campaign or upgrade screen.

## Fleet Hangar

Choose **Fleet Hangar** on the flight deck to inspect the redesigned Kestrel, Scout, Striker, Bulwark, Warden, Overseer and rescue Courier. **Drag** the preview to rotate, use the **mouse wheel** to zoom, or choose **Front / Rear / Side / Auto Rotate**. Escape returns to the deck. Ship Livery uses the same inspection controls, and your existing coatings apply to the new Kestrel hull and exhaust.

Version 0.8 adds layered armor, beveled edges, machined engine collars, recessed optics, physical vents, maneuvering ports and animated exhaust. First-person cannon housings match the new hull style. See **FLEET.md** for the asset guide.

## Art and sound

The Kestrel, Scout, Striker, Bulwark, Warden, Overseer, Courier and first-person cannon housings are authored reusable glTF assets in `assets/models/`. The deterministic mesh-authoring source is included in `tools/author_models.py`. The mine uses metal surface detail, emissive lighting, moving machinery, rotating turbines, coolant collars, dust and physical cockpit geometry. Explosions include transient lighting, shock rings, debris and fading smoke.

The original stereo score adds a separate combat rhythm layer. Separate weapon, impact, ambience, music and interface buses provide voice limits and temporary ducking so captions and menu cues remain readable during combat. Weapon mechanisms recoil and charge, ships and missiles leave short trails, and explosions add hot cores and streak sparks. The original score and fallback clips are cached in `assets/audio/`; `tools/bake_audio.gd` regenerates them. Kenney-derived effects in `assets/audio/sfx/` are prepared by `tools/prepare_sfx.py`; their CC0 license and provenance are included. Ship engines respond to speed; weapons, explosions, doors and machinery use positional audio. Fonts are requested from installed system families and are not redistributed.

## Development and validation

The game uses GDScript and the Compatibility renderer; Balanced defaults to 2x MSAA. Static decorative geometry is batched by material and spatial cell while preserving collision and moving objects. See `PERFORMANCE.md` for measured results. The supplied Mono editor may print a C# SDK warning during editor import; the project and release do not use C# or require that SDK.

- `scripts/campaign.gd`, `scripts/profiles.gd`: campaign profiles, manual slots, salvage, unlocks, upgrades and records
- `scripts/automap.gd`, `scripts/systems.gd`, `scripts/foundry.gd`, `scripts/ratings.gd`: 3D survey, security shortcuts, production and medals
- `scripts/main.gd`: mission state, interactions, weapons, checkpoints and route graph
- `scripts/mine.gd`: Nereid layout and procedural landmarks
- `scripts/operations.gd`: Boreas and Helios layouts
- `scripts/boss.gd`: Overseer phases, telegraphs and attacks
- `scripts/lore.gd`, `scripts/exploration.gd`, `scripts/rescue_drone.gd`, `scripts/atmosphere.gd`: story, discoveries, liveries, rescue routes and exterior landmarks
- `scripts/arsenal.gd`, `scripts/hazard.gd`, `scripts/encounters.gd`: primary weapons, interactive hazards and saved encounter progression
- `scripts/controls.gd`, `scripts/training.gd`: shared remappable input and interactive flight school
- `scripts/static_batch.gd`: static geometry batching with preserved physics
- `scripts/player.gd`, `scripts/drone.gd`, `scripts/door.gd`: flight, enemies and doors
- `scripts/hud.gd`, `scripts/sound.gd`, `scripts/forge.gd`: interface, audio and materials

Run these from the project directory with the installed Godot console executable:

```powershell
$engine = 'C:\Development\Godot\Godot_v4.7.2-stable_mono_win64_console.exe'
& $engine --headless --path . --script tests/smoke.gd
& $engine --headless --path . --script tests/expansion.gd
& $engine --headless --path . --script tests/campaign.gd
& $engine --headless --path . --script tests/flight_presentation.gd
& $engine --headless --path . --script tests/acoustics.gd
& $engine --headless --path . --script tools/chase_combat.gd
& $engine --headless --path . --script tests/sound_bank.gd
& $engine --headless --path . --script tests/fleet.gd
& $engine --headless --path . --script tests/navigation.gd
& $engine --headless --path . --script tests/profiles.gd
& $engine --headless --path . --script tools/foundry_balance.gd
& $engine --headless --path . --script tests/exploration.gd
& $engine --headless --path . --script tools/rescue_balance.gd
& $engine --headless --path . --script tests/combat.gd
& $engine --headless --path . --script tools/combat_balance.gd
& $engine --headless --path . --script tests/readiness.gd
& $engine --headless --path . --script tests/campaign_routes.gd
& $engine --path . --script tests/flight.gd
& $engine --path . --script tests/visual.gd --resolution 1600x900
& $engine --path . --script tests/campaign_visual.gd --resolution 1600x900
```

Tests use isolated in-memory campaign profiles; persistence checks create and clean up their own fixtures. They do not unlock the player's campaign or spend the player's salvage. The flight suite uses the real display backend for captured mouse input. Visual suites write rendered PNGs to `tests/`. `QA_REPORT.md` records the latest checks and their limits. Controller checks use simulated events; a physical gamepad still needs a hands-on pass.

Build the Windows release with:

```powershell
.\tools\build_windows.ps1
```

The build script uses the exact matching official Windows runtime, exports the game, verifies all three packaged missions and training, includes Godot license notices, creates `exports/Subterranea-Windows-x64.zip`, and writes `exports/SHA256SUMS.txt`. If needed, the runtime-fetch helper downloads only the Windows member of the official template archive.

The existing version 0.4 presentation kit at `exports/Subterranea-PressKit.zip` contains ten rendered screenshots, suggested release copy and a 26.6-second H.264/AAC trailer. The trailer uses scripted cameras and staged encounters in the actual engine. Ten version 0.6 screenshots are in `exports/exploration-preview/`; `tools/exploration_visual.gd` recreates them. Six additional version 0.5 previews are in `exports/combat-preview/`; `tools/combat_visual.gd` recreates them. No material has been posted publicly. Capture tools live in `tools/presentation.gd`, `tools/trailer_overlay.gd` and `tools/finish_presskit.py`; the encoder is a local build dependency and is not distributed with the game.

Twelve version 0.7 previews are in `exports/navigation-preview/`; `tools/navigation_visual.gd` recreates them.

Eleven version 0.8 fleet/gameplay screens and nine close-up renders are in `exports/fleet-preview/`; `tools/fleet_visual.gd` recreates them.

Eleven version 0.9 flight/effect/settings captures are in `exports/flight-preview/`; `tools/flight_visual.gd` recreates them. The local sound preview is `exports/v09-sound-preview.wav`.

See `FLIGHT.md`, `SOUND.md`, `FLEET.md`, `NAVIGATION.md`, `CHANGELOG.md`, `EXPLORATION.md`, `COMBAT_BALANCE.md` and `QA_REPORT.md` for the updates and their validation limits.

This is a small playable three-operation campaign, with no multiplayer or additional campaigns. See `THIRD_PARTY_NOTICES.md` and `licenses/` for Godot's redistribution notices.

Version 0.9.1 adds three contact screenshots in exports/contact-preview/ and an in-engine clear/muffled/clear recording at exports/v091-clear-muffled-clear.mp3.
