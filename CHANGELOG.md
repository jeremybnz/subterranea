# Subterranea 0.9.1 - combat sound polish

18 November 2026

- Positional effects now check world/door collision from source to listener. Blocked sounds fade toward -14 dB and a real 1.8 kHz low-pass route; clear paths restore the original mix. Interface cues remain clear. Filter buses feed the existing category buses, preserving effects volume and ducking.
- Ongoing occlusion work is bounded to eight sources per 80 ms refresh and uses a round-robin schedule. New effects initialize their state immediately; paused gameplay stops ongoing ray casts.
- Pulse, rail, close plasma and enemy wall strikes now receive contact-specific sparks and positional impact audio. Metal, observation glass, frontal armor, intact shields, damaged hulls and objectives have distinct responses. Contact sounds are rate limited, and wall hits never create a false damage confirmation.
- Static batching preserves observation-glass surface metadata. Existing reinforced windows remain solid; weapon damage and armor rules retain their definitions.
- Six normal-shield live-AI combat scenarios compare all three primaries in cockpit/chase views. All complete with active incoming fire, no detected camera penetrations and bounded hull fragments.
- Eighteen acoustic/contact tests, audio and combat regressions, native acoustic validation and a recorded clear/blocked/clear comparison. Previous 0.9 Windows archive retained locally.

# Subterranea 0.9 - flight, impact and sound update

18 November 2026

- Optional chase camera with the actual painted Kestrel, remappable T / touchpad input and a Flight Settings view button. A camera sphere cast retracts the view near walls and temporarily restores the cockpit where clearance is tight; full pitch and roll are retained.
- All four weapon paths remain anchored at the ship. Chase reticle convergence respects cover, preventing the raised/trailing camera from firing through low walls.
- Smoothed thrust/boost exhaust, low-integrity engine flicker and a separate afterburner audio layer.
- Directional shield-hit ripples, impact sparks, scorch patches and smoke on player, hostile craft and courier. Repairs clear derived damage, and restored integrity reconstructs the appearance.
- Ship deaths shed six armor/engine chunks partitioned from their actual original meshes. Fragments spin, bounce, trail smoke and expire. Performance/Balanced/Quality budgets cap active hull chunks at 24/48/72; chunks have no gameplay collision bodies.
- Thirty prepared Kenney Sci-fi Sounds effects/loops (CC0): weapon variants, layered plasma/rail/explosions, shield/metal impacts, separate opening/closing doors, seamless engine/machinery loops and boost roar. Source license, credits and a transformation manifest are included.
- Independent saved effects-volume control, no immediate repeated shot variant, retained positional audio and voice limits, and a single master limiter. Original score and interface/critical-warning cues remain.
- Camera/weapon/FX tests, all three complete chase-view campaign routes, profile/manual-save checks, physical flight/training/rescue regressions, sound-bank checks and PCM peak/seam validation.

# Subterranea 0.8 - fleet art update

18 November 2026

- Redesigned Kestrel with split armored shoulders, recessed canopy, detailed cannon pods, maneuvering ports, layered wing plates and recessed twin engine nozzles.
- Distinct Scout, Striker and Bulwark silhouettes. Dedicated Warden guardian and protected rescue Courier assets replace their earlier shared/procedural hulls. The Overseer gains segmented armor, command optics and four detailed cannon mounts.
- Beveled mesh edges, physical vents, machined collars, inset emitters and correctly encoded glTF linear material colors. Existing liveries recolor hull and engine accents.
- Animated additive engine exhaust on player previews, hostile craft and the rescue courier. Detailed first-person cannon housings retain the existing recoil and weapon animations.
- Fleet Hangar on the flight deck: seven vessels, independent 3D studio lighting, drag rotation, bounded zoom, front/rear/side presets and automatic rotation. Ship Livery gains the same inspection controls.
- Eight original reusable glTF meshes built by the included deterministic authoring tool. Collision bodies, flight handling, AI and damage values retain their existing definitions.

# Subterranea 0.7 - navigation and campaign profiles

18 November 2026

- Rotatable, zoomable 3D automap reveals entered rooms and traversed shafts. Filters, controller navigation and surveyed location pins drive in-flight route guidance; extraction takes priority. Inspecting it pauses flight, enemies and mission time.
- Three optional colored-key routes, each with an alternative held local security override. Shortcuts include real service corridors and shafts; all required objectives remain mandatory.
- Destructible robot foundries telegraph production, replenish scouts/strikers up to three living reinforcements, and stop after shutdown or containment. State and exact reinforcement identities survive checkpoints.
- Combat, exploration, rescue and escape medals produce D-to-S mission ranks. Profiles retain best medals and highest overall rank across replays.
- Three independent campaign profiles with a separate autosave and three manual slots each. Pilot 1 uses the existing campaign file. Slot overwrite/load confirmation, profile isolation, backup recovery and completed-run reward protection are included.
- Full file/scene reload tests, physical shortcut flight, three normal-shield live foundry scenarios and twelve rendered feature previews. Fixed JSON survey restoration and stale menu focus during scene replacement.

# Subterranea 0.6 - atmosphere and exploration

17 November 2026

- Three physically sealed observation windows with original drilling, ice-excavation and fusion-array scenery, plus damaged supports and caution markings.
- Nine collectible written logs and twelve captioned radio messages. A pause/deck journal preserves heard transmissions and tracks discoveries, vaults, trials and rescue progress.
- A crew refuge in each operation launches a physical, repairable rescue courier. It follows the route graph through doors and shafts, waits outside escort range, can take enemy fire and grants optional extraction rewards.
- Three one-time survey caches award salvage, supplies and Ember/Glacier/Solar liveries. The deck livery screen uses a separate rotating preview; colors apply to the actual hull, cockpit trim and engine trails.
- Recoiling and charging weapon mechanisms, ship and missile trails, hot explosion cores and streak sparks.
- Separate audio mix categories, transient voice limits, impact/radio ducking and interface cues that remain audible in pause menus.
- Backward-compatible profile and checkpoint fields for discoveries, paint, crew, courier route/integrity and story state. A courier already safe inside the arrival chamber can be recovered during extraction.

# Subterranea 0.5 - combat update

17 November 2026

- Three selectable primaries: rapid pulse, traveling plasma splash, and a charged piercing railgun. Default selection uses 1/2/3 or gamepad D-pad; V or D-pad right cycles. All weapon actions are remappable.
- Shared amplifier upgrades now affect all three primaries, with exact damage improvements in the upgrade bay. Violet energy supplies and alternating energy drops support sustained fights.
- Patrol waypoints, visible squad alerts, opposite flanks, separation, temporary retreats toward cover, and a two-attacker admission limit. Strikers predict aim from projectile travel time.
- Three destructible hazards per operation: cycling coolant, cycling arcs and volatile machinery. Weapon rays and projectiles stop at marked cells and close walls.
- Telegraphed response-team ambushes in each operation. Optional two-wave vault trials grant supplies, score, an extraction salvage bonus and a campaign completion mark.
- Helios trial Warden miniboss with frontal armor, spread attacks, radial overdrive, distinct armor geometry and a dedicated health display.
- Checkpoints preserve weapon selection, hazard destruction, ambush/trial progress and exact live wave identifiers. Custom 0.4 bindings take precedence over new weapon defaults; conflicts move to the freed assignment.
- New original plasma and rail audio, HUD cues and six in-engine previews.

Three campaign operations, training, difficulty factors and escape timers remain compatible with prior progress. Automated balancing supplements the route and regression suites; it does not replace human playtesting or physical gamepad validation.
