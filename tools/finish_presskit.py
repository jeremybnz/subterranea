"""Encode the captured trailer, verify its streams, and package the local press kit."""
from pathlib import Path
import json, subprocess, zipfile, sys
root=Path(__file__).resolve().parents[1]
folder=root/"exports"/"presskit"
encoder=root/"tools"/"runtime"/"ffmpeg.exe"
source=folder/"source"
if "--package-only" not in sys.argv:
    command=[str(encoder),"-y","-i",str(source/"trailer.avi"),"-stream_loop","-1","-i",str(source/"score.wav"),"-stream_loop","-1","-i",str(source/"rhythm.wav"),"-filter_complex","[0:a]volume=1[sfx];[1:a]volume=1.4[pad];[2:a]volume=0.4[beat];[sfx][pad][beat]amix=inputs=3:duration=first:normalize=0,afade=t=in:d=0.6,afade=t=out:st=25:d=1.5[a]","-map","0:v","-map","[a]","-vf","scale=1280:720","-c:v","libx264","-preset","medium","-crf","20","-pix_fmt","yuv420p","-c:a","aac","-b:a","192k","-movflags","+faststart","-shortest",str(folder/"Subterranea-Trailer.mp4")]
    subprocess.run(command,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    # Decode the finished file in full to catch truncated streams or codec errors.
    subprocess.run([str(encoder),"-v","error","-i",str(folder/"Subterranea-Trailer.mp4"),"-f","null","-"],check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    for second in [2,6,10,14,19,23,25]:
        subprocess.run([str(encoder),"-v","error","-y","-ss",str(second),"-i",str(folder/"Subterranea-Trailer.mp4"),"-frames:v","1",str(source/("review-%02d.png"%second))],check=True)
(folder/"README.md").write_text("""# Subterranea — local release presentation kit

A six-degrees-of-freedom combat flight campaign for Windows PC.

## Files

- Subterranea-Trailer.mp4: 1280 x 720, 30 FPS, H.264 / AAC, with original music and sound effects.
- screenshots/: ten in-engine images covering training, combat, archives, boss, upgrades, campaign, options, controller bindings, briefing and credits.
- CAPTIONS.md: image captions and suggested release copy.

The trailer is captured in-engine with scripted camera paths and staged encounters. It shows the actual game environments, models, weapons, boss and UI. Menu screenshots illustrate earned campaign progress using an isolated presentation profile; they do not change the player's save. No content has been uploaded or published.

All game visuals and audio were authored for this project. Godot redistribution notices are included with the separate Windows game release. The media encoder is a build tool and is not included in either distribution archive.
""",encoding="utf-8")
(folder/"CAPTIONS.md").write_text("""# Suggested release copy

**Subterranea — The Nereid Campaign**

Descend into a silent mining complex. Fly in six axes through industrial mines, recover encrypted archives from a frozen station, and confront the Overseer inside a reactor fortress. Earn salvage, upgrade your Kestrel, and get back to the dock before containment fails.

- Three operations and an interactive flight school.
- Mouse/keyboard and gamepad controls, with saved remapping.
- Scouts, strikers, armored bulwarks and a three-phase final boss.
- Permanent ship upgrades, mission checkpoints and best records.
- Vertical shafts, hidden supplies and volumetric navigation.
- Performance presets, FOV and HUD options, and adjustable difficulty.

## Screenshot captions

1. **Flight school:** Learn thrust, strafe, lift, roll, boost, braking, weapons and navigation in a safe training hangar.
2. **Nereid:** Fight through an industrial mine in full six-degrees-of-freedom flight.
3. **Boreas:** Recover encrypted archives and upload the evidence before the response fleet arrives.
4. **Overseer:** Disable its shields and survive three different attack phases.
5. **Upgrade bay:** Spend earned salvage on shields, engines, pulse cannons and seekers.
6. **Campaign:** Unlock three operations and improve your scores and completion times.
7. **Options:** Adjust field of view, HUD size, graphics, difficulty and controller response.
8. **Controller bindings:** Remap buttons, triggers and sticks alongside keyboard and mouse controls.
9. **Briefing:** Review objectives and operation-specific advice before deployment.
10. **Credits:** Original art, models and synthesized audio, built with Godot Engine.

This is a local release kit. No storefront listing, public release date, rating, price or platform approval is implied.
""",encoding="utf-8")
zip_path=root/"exports"/"Subterranea-PressKit.zip"
with zipfile.ZipFile(zip_path,"w",zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
    for file in sorted(folder.rglob("*")):
        if file.is_file() and "source" not in file.relative_to(folder).parts: archive.write(file,file.relative_to(folder))
print(json.dumps({"trailer":str(folder/"Subterranea-Trailer.mp4"),"trailer_bytes":(folder/"Subterranea-Trailer.mp4").stat().st_size,"presskit":str(zip_path),"screenshots":len(list((folder/"screenshots").glob("*.png")))},indent=2))
