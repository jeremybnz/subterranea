# Subterranea 0.9.1 - sound bank and credits

18 November 2026

## Source and license

The additional effects are derived from Kenney's Sci-fi Sounds 1.0 pack (Kenney / www.kenney.nl), licensed under Creative Commons Zero (CC0). The official page is https://kenney.nl/assets/sci-fi-sounds and the dedication is https://creativecommons.org/publicdomain/zero/1.0/. The pack's original license text is included as licenses/KENNEY_SCI_FI_LICENSE.txt. Credit is shown in the game's credits and THIRD_PARTY_NOTICES.md.

The project keeps its original synthesized stereo score, percussion layer, interface/pickup cues and critical warning. No Descent audio or commercial game's sound recordings are included.

## Prepared effects

| Use | Source recordings | Preparation |
| --- | --- | --- |
| Pulse | laserSmall 000-002 | Three short variants |
| Enemy shots | laserRetro 000-002 | Three filtered variants |
| Plasma | laserLarge 000-002 + lowFrequency explosion 001 | Slower laser body with low-frequency attack |
| Rail | laserLarge 003-004 + impactMetal 004 + lowFrequency explosion 001 | Two layered transient variants |
| Explosions | explosionCrunch 000-002 + lowFrequency explosion 000 | Three layered body/tail variants |
| Shield hit | forceField 002 + impactMetal 003 | Short energy/metal impact |
| Metal hit | impactMetal 000-002 | Three compact impact variants |
| Missile | thrusterFire 002 + lowFrequency explosion 001 | Launch roar and low-end attack |
| Door | doorOpen 000-002 / doorClose 000-002 | Separate opening and closing variants |
| Charge / reactor | forceField 001 / explosionCrunch 003 + lowFrequency explosion 001 | Riser and heavier objective burst |
| Engine | spaceEngineSmall 000 + spaceEngineLow 000 | Seamless layered hum |
| Boost | thrusterFire 001 | Separate seamless afterburner layer |
| Machinery | engineCircular 001 | Seamless positional machinery loop |

There are 27 one-shots and three loops. Files are mono PCM16 at 44.1 kHz for positional playback. Preparation uses a 35 Hz high-pass, 14 kHz low-pass, trimming, gain/pitch changes, layering, short fades and peak normalization. The loops use a 150 ms circular crossfade. Exact source hashes, processing choices, output hashes, levels and file mappings are recorded in assets/audio/sfx/manifest.json.

## Mix controls

Flight Settings has separate Master, Music and Sound Effects controls. These save in flight.cfg. Weapon and impact voices remain positional where appropriate. Consecutive multi-variant effects avoid immediately choosing the same recording; small playback-pitch changes add variation. Boost fades in/out as the pilot engages/releases the afterburner. Pause stops engines, ambient loops and weapon voices while interface cues remain available. Music keeps its existing combat layer and radio/impact ducking.

Voice caps remain 20 weapons, 10 impacts and eight other transient voices per bus. A single master limiter provides transient peak protection. All prepared files were decoded and checked for zero full-scale clipped samples, peaks under 0.8 full scale and bounded loop-boundary discontinuities. This is technical validation, not a claim of listening tests on multiple speaker systems.

## Positional acoustics and contacts

World effects use a direct source-to-listener collision ray against walls, doors and glass. Blocked sources fade toward 14 dB attenuation and route through a 1.8 kHz low-pass filter. Moving into a clear path restores their dry level and original category bus. Interface/pickup cues remain clear. The muffled buses send into Weapons, Impacts or Ambience, so existing effects volume, ducking and master limiting still apply.

New sources initialize occlusion when created. Ongoing checks update at most eight sources every 80 ms, rotating through active sources and skipping distant/queued voices. Pause and the automap suspend ongoing ray casts and motion-related playback. The direct-line model follows actual world collision rather than room labels.

Weapon contacts distinguish metal, reinforced observation glass, frontal armor, intact shield surfaces, damaged hulls and objectives. Pulse/rail misses against walls now make positional impacts. Glass uses a brighter resonance, armor a lower clang, and shields use the prepared energy-hit recording. These use the existing credited bank and playback processing. Hit colors follow the contact; wall strikes do not count as enemy damage. A 55 ms per-contact-type cooldown prevents simultaneous contacts from flooding the mix. Weapon damage and armor rules retain their definitions.

A recording made with Godot's internal master-bus recorder is exports/v091-clear-muffled-clear.wav (MP3 also supplied). It captures three pulse bursts with a clear path, a real intervening wall, then a clear path again. No microphone/system audio is captured. The blocked sample measures about 15 dB below the clear sections, and the returning clear level matches within 0.1 dB. tests/acoustic_recording.json records the measurements. This validates routing and attenuation; speaker/headphone listening remains useful for subjective balance.

## Rebuild and preview

Run python tools/fetch_sfx.py to obtain the official free pack using the site's public download action, then python tools/prepare_sfx.py with the local ffmpeg helper. Only the prepared game clips and provenance manifest belong in the game assets; the full original archive and source OGGs remain in tools/runtime. The Windows release includes license notices and needs no external media tools.

exports/v09-sound-preview.wav is a 14-second offline sequence: pulse burst, plasma, rail charge/shot, metal and shield hits, missile/explosion, door opening/closing, engine and boost. It is a sequenced sample, not a live gameplay recording. tests/sound_bank.gd validates loaded resources, variation, actual trigger playback, loop bounds, volume separation, boost response, pause, voice limits, limiter and settings. tests/audio_levels.json records the per-file PCM checks.

For the 0.9.1 acoustic checks run tests/acoustics.gd. tools/record_acoustics.gd recreates the internal-mix comparison; tools/contact_visual.gd captures actual glass/metal/armor contacts.
