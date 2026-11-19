# Subterranea 0.7 - navigation and save guide

18 November 2026. All new routes are optional; normal mission objectives and escape timers still apply.

## 3D automap

Tab opens/closes the map. Flight, projectiles, enemies, doors, hazards, courier and mission/escape timers pause while it is open. Entered rooms and traversed shafts remain surveyed in checkpoints and manual saves. Older checkpoints begin a new survey at the ship's current location.

| Control | Function |
| --- | --- |
| Left mouse drag / right stick / arrow keys | Rotate the orthographic 3D view |
| Right mouse drag / left stick / WASD | Pan |
| Wheel / LB-RB | Zoom |
| R / Y | Recenter and reset view |
| Click surveyed node / A | Set navigation marker |
| Bracket keys / D-pad left-right | Select surveyed node |
| Enter | Pin selected node |
| 1 / 2 / 3 | Objective / contact / supply filters |
| X | Toggle filters together |
| Delete / Backspace / Clear Marker | Clear pin |
| Tab / Escape / B / Start | Close map |

A pin guides through currently accessible graph connections. Locked security gates and sealed reactor doors are respected. The escape route supersedes pins during containment. Reaching a pinned node clears it. Hidden vault nodes require breaching their maintenance plating. Map controls consume flight input while open.

## Security shortcuts

| Operation | Key location | Local override | Route opened |
| --- | --- | --- | --- |
| Nereid / blue | Lower foundry, near missile supplies | Upper pump service lift | Upper relay across the transfer corridor and down to pump hall |
| Boreas / yellow | Archive Beta | Archive Gamma | Gamma service shaft directly down to the uplink chamber |
| Helios / red | Crown shield chamber | West shield room | Breached reserve vault through the security exchange into the Overseer chamber |

Fly within two meters of the floating key to collect it. Alternatively hold the interaction control for 1.5 seconds near the marked local override. Either unlocks the matching gate. Each interaction grants 100 mission points once. The shortcut does not recover archives, disable generators or bypass the final objective's shield requirements. Helios reserve access still requires breaching maintenance plating.

## Robot foundries

Purple machines fabricate a drone after an initial 2.5-second charge, then recharge for eight seconds. The last two seconds warn with a pulsing lamp and fabrication caption. Production requires the pilot within 26 meters and clear sight; it suspends at three living linked drones. Killing one frees capacity. Two scouts alternate with every third reinforcement becoming a striker.

Foundries have 180 health. Any primary or missile can destroy them for 400 mission points. Shutdown is permanent for that run and prevents further production; existing drones remain. Evacuation stops production. Checkpoints retain machine health, production timer, shutdown and linked live drone identities. These machines use weapon collision, so their chassis does not block a flight corridor.

## Medals and ranks

Medals are awarded at successful extraction. Each category is worth 0-3 points (none, bronze, silver, gold).

| Category | Bronze | Silver | Gold |
| --- | --- | --- | --- |
| Combat | At least 30% of spawned drones destroyed | At least 60% | At least 90% |
| Exploration | At least 30% survey score | At least 60% | At least 90% |
| Rescue | Crew secured | Courier delivered with under 100 integrity | Courier delivered with at least 100 integrity |
| Escape | Successful extraction | At least 40% timer remaining | At least 70% timer remaining |

Survey score is 60% entered-room coverage plus 40% collected operation recorders. Previous permanent recorder discoveries count on a replay; room coverage belongs to the current run. Combat includes triggered reinforcements, so leaving a foundry running can lower coverage. Rescue is optional.

Overall rank: S = 12 points; A = 9-11; B = 6-8; C = 3-5; D = 0-2. Profiles preserve each category's best medal and the best overall score achieved in a single run. Category bests from different runs cannot combine into an unearned overall S. Medals add replay goals; existing salvage reward rules remain in force.

## Campaign profiles and manual saves

Open Profiles & Saves from the flight deck, then Campaign Profiles. Pilot 1 uses the existing campaign_v1.json directly. Pilots 2 and 3 use campaign_2_v1.json and campaign_3_v1.json. profiles.cfg remembers the active pilot. Each pilot has independent upgrades, salvage, discoveries, records, an autosave and three manual slots. Flight/audio/display settings remain shared in flight.cfg. Files live in %APPDATA%\Godot\app_userdata\SUBTERRANEA\.

From Pause > Manual Saves, choose Save Current Run. An occupied slot requires Confirm Overwrite; loading requires Confirm Load. Saving is disabled in training and outside paused flight. Loading restores the chosen mission state through a fresh scene, including survey, security gates and foundries. Permanent purchases, discoveries and reward claims stay current. Replaying an already rewarded run cannot duplicate its reward. Restart/death clear the autosave without deleting manual slots. Return to the flight deck to change profiles.

Profiles use validated temporary writes and a previous valid .bak copy. No profile deletion/reset is included. Malformed manual slots are ignored when loading. Automated tests use isolated local fixtures and never touch a player's campaign.
