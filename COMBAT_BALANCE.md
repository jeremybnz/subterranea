# Subterranea 0.5 - combat measurements

17 November 2026. Windows, Godot 4.7.2. These are scripted scenarios using normal 100-point shields, no upgrades, live enemy AI, normal resource regeneration and real pickups. No enemy is frozen. Aiming and six-axis movement are automated. Each enemy uses a seeded starting phase and a cooldown within its normal range; the simulation uses time scale 6 and 120 physics ticks per real second. These settings make iteration faster and are not a human reaction-time model.

## Nereid nexus / 50 simulated seconds

| Difficulty | Primary | Kills | Damage taken | Shield left | Mean energy | Shots | Pickups |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pilot | pulse | 6 | 0.0 | 100.0 | 97.3 | 24 | 0 |
| Pilot | plasma | 6 | 0.0 | 100.0 | 87.7 | 19 | 1 |
| Pilot | rail | 6 | 15.6 | 84.4 | 88.2 | 6 | 1 |
| Standard | pulse | 6 | 0.0 | 100.0 | 97.3 | 24 | 0 |
| Standard | plasma | 6 | 0.0 | 100.0 | 91.5 | 16 | 1 |
| Standard | rail | 6 | 32.0 | 68.0 | 88.2 | 6 | 1 |
| Ace | pulse | 6 | 0.0 | 100.0 | 97.3 | 24 | 0 |
| Ace | plasma | 6 | 0.0 | 100.0 | 87.7 | 19 | 1 |
| Ace | rail | 6 | 41.6 | 58.4 | 88.2 | 6 | 1 |

All nine moving/firing scenarios survived. These light encounters favor the bot's perfect pulse aim; they do not establish a global weapon ranking. The bot actively seeks useful nearby shield/energy pickups. No scenario spent time below nine energy.

## Helios optional vault trial / Standard

| Primary | Trial result | Seconds | Kills | Damage taken | Mean energy | Shots | Pickups |
| --- | --- | --- | --- | --- | --- | --- | --- |
| pulse | cleared | 13.3 | 4 | 0.0 | 54.6 | 87 | 3 |
| plasma | cleared | 9.3 | 5 | 0.0 | 53.6 | 23 | 2 |
| rail | cleared | 13.4 | 4 | 7.0 | 46.5 | 8 | 2 |

All three primaries cleared both waves including the Warden, without installed upgrades. The vault exit stays open, so ordinary enemies can join; kill counts and damage dealt include them. These are encounter completion observations, not isolated DPS comparisons. Missiles were intentionally left unused (eight remained in each scenario) to expose primary-weapon energy behavior. Missile replenishment and the trial's +3 ammunition reward are separately covered by gameplay tests.

## Stationary / no-fire control

| Difficulty | Seconds until ship loss | Incoming damage | Enemy projectiles released |
| --- | --- | --- | --- |
| Pilot | 10.4 | 100.0 | 27 |
| Standard | 7.0 | 100.0 | 16 |
| Ace | 6.9 | 100.0 | 16 |

These deliberate ship losses are expected controls: they demonstrate that active enemies deliver real damage and that evasion/offense matter. They do not represent intended human completion times.

## Decisions and limits

- Retained the 65% / 100% / 130% incoming-damage factors and existing escape budgets. All three weapons can complete the trial with ordinary resources, and the route suite leaves escape headroom. Human evidence is needed before tighter timers or larger health changes.
- Strikers now lead by clamped projectile travel time rather than a fixed short prediction. Enemies share alerts and flank, while charging/bursting attackers are limited to two nearby drones and attacks remain telegraphed.
- Pulse offers immediate repeated hits. Plasma trades travel time for splash and armor bypass. Rail trades charging and energy for instant piercing; later targets retain 80% damage per penetration. Amplifier upgrades improve all three.
- Added violet +40 energy supplies and alternating energy drops. Trials reward +25 shields, +40 energy and +3 missiles; shields and energy obey their normal caps.
- Human aiming, navigation mistakes, controller feel, broader hardware and full combat playthroughs still need hands-on validation. Accelerated single-seed bot scenarios can miss exploits and cannot prove human balance.

Reproduce: run `tools/combat_balance.gd`. Raw results are in `tests/combat_balance.json`; the initial development sample is retained in `tests/combat_balance_initial.json`.
