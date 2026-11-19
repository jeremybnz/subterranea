"""Prepare CC0 Kenney Sci-fi Sounds derivatives and an auditable source manifest.
Requires the official archive in tools/runtime and the local ffmpeg helper.
"""
from pathlib import Path
import array,hashlib,json,math,subprocess,wave,zipfile
ROOT=Path(__file__).resolve().parents[1]
CACHE=ROOT/"tools/runtime/kenney_sfx_source";OUT=ROOT/"assets/audio/sfx";OUT.mkdir(parents=True,exist_ok=True)
RATE=44100; decoded={}; records=[]
def decode(name):
 if name not in decoded:
  path=CACHE/(name+".ogg")
  result=subprocess.run([str(ROOT/"tools/runtime/ffmpeg.exe"),"-v","error","-i",str(path),"-af","highpass=f=35,lowpass=f=14000","-f","s16le","-ac","1","-ar",str(RATE),"-"],capture_output=True,check=True)
  decoded[name]=[v/32768 for v in array.array("h",result.stdout)]
 return decoded[name]
def layer(name,gain=1.0,speed=1.0,seconds=None,delay=0):return dict(name=name,gain=gain,speed=speed,seconds=seconds,delay=delay)
def render(name,layers,seconds,peak=.72,loop=False,rise=False):
 total=int(seconds*RATE);samples=[0.0]*total
 for item in layers:
  original=decode(item["name"]); count=min(int((item["seconds"] or seconds)*RATE),int(len(original)/item["speed"]));start=int(item["delay"]*RATE)
  for i in range(min(count,total-start)):
   at=i*item["speed"];index=int(at);frac=at-index
   value=original[index]*(1-frac)+original[min(index+1,len(original)-1)]*frac
   samples[start+i]+=value*item["gain"]
 if loop:
  overlap=int(RATE*.15); blended=[samples[total-overlap+i]*(1-i/(overlap-1))+samples[i]*i/(overlap-1) for i in range(overlap)]
  samples=samples[overlap:total-overlap]+blended
 else:
  attack=int(RATE*.002);tail=int(RATE*min(.09,seconds*.15))
  for i in range(len(samples)):
   samples[i]*=min(1,i/max(1,attack),max(0,(len(samples)-1-i)/max(1,tail)))
   if rise:samples[i]*=(i/max(1,len(samples)-1))**.6
 current=max(abs(v) for v in samples) or 1;gain=peak/current
 samples=[v*gain for v in samples];pcm=array.array("h",(round(max(-.999,min(.999,v))*32767) for v in samples))
 path=OUT/(name+".wav")
 with wave.open(str(path),"wb") as file:file.setnchannels(1);file.setsampwidth(2);file.setframerate(RATE);file.writeframes(pcm.tobytes())
 records.append({"output":path.name,"sources":[{"file":i["name"]+".ogg","sha256":hashlib.sha256((CACHE/(i["name"]+".ogg")).read_bytes()).hexdigest(),"gain":i["gain"],"speed":i["speed"],"delay":i["delay"],"trim_seconds":i["seconds"]} for i in layers],"duration":len(samples)/RATE,"peak":max(abs(v) for v in pcm)/32768,"rms":math.sqrt(sum(v*v for v in samples)/len(samples)),"loop":loop,"sha256":hashlib.sha256(path.read_bytes()).hexdigest()})
 print(path.name,round(len(samples)/RATE,2),"seconds")
 return name+".wav"
bank={}
for kind in ["laser","enemy","plasma","rail","blast","hit","door_open","door_close"]:bank[kind]=[]
for i in range(3):
 bank["laser"].append(render("pulse_"+str(i),[layer("laserSmall_%03d"%i)],.34,.68))
 bank["enemy"].append(render("hostile_"+str(i),[layer("laserRetro_%03d"%i,speed=1.08)],.36,.6))
 bank["plasma"].append(render("plasma_"+str(i),[layer("laserLarge_%03d"%i,.85,.88),layer("lowFrequency_explosion_001",.22,1.3,.2)],.82,.72))
 bank["blast"].append(render("explosion_"+str(i),[layer("explosionCrunch_%03d"%i,.8),layer("lowFrequency_explosion_000",.62,1,1.5,.025)],1.6,.78))
 bank["hit"].append(render("metal_hit_"+str(i),[layer("impactMetal_%03d"%i,.9,1.1)],.5,.64))
 bank["door_open"].append(render("door_open_"+str(i),[layer("doorOpen_%03d"%i)],.56,.58))
 bank["door_close"].append(render("door_close_"+str(i),[layer("doorClose_%03d"%i)],.56,.58))
for i in range(2):bank["rail"].append(render("rail_"+str(i),[layer("laserLarge_%03d"%(3+i),.52,1.3),layer("impactMetal_004",.65,1.25),layer("lowFrequency_explosion_001",.22,1.4,.18)],.7,.76))
bank["hurt"]=[render("shield_impact",[layer("forceField_002",.22,1,.4),layer("impactMetal_003",.45,1.1,.25)],.46,.6)]
bank["missile"]=[render("missile_launch",[layer("thrusterFire_002",.85,1,.75),layer("lowFrequency_explosion_001",.2,1.4,.25)],.78,.7)]
bank["charge"]=[render("rail_charge",[layer("forceField_001",1,1,.55)],.55,.55,rise=True)]
bank["relay"]=[render("reactor_burst",[layer("explosionCrunch_003",.7,1.05,.9),layer("lowFrequency_explosion_001",.4)],1.1,.73)]
loops={"engine":render("engine_loop",[layer("spaceEngineSmall_000",.6),layer("spaceEngineLow_000",.23)],5,.6,loop=True),"boost":render("boost_loop",[layer("thrusterFire_001")],5,.65,loop=True),"machine":render("machine_loop",[layer("engineCircular_001")],5,.5,loop=True)}
source=json.loads((ROOT/"tools/runtime/kenney_audio_source.json").read_text())
manifest={"version":1,"source":source,"processing":"Decoded mono 44.1 kHz PCM16; 35 Hz high-pass / 14 kHz low-pass; layered, trimmed, peak-normalized and faded; loops use a 150 ms circular crossfade.","effects":bank,"loops":loops,"files":records}
(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2))
(ROOT/"scripts/sound_bank.gd").write_text('extends RefCounted\n## CC0 Kenney-derived effects; source and transformations are in assets/audio/sfx/manifest.json.\nconst EFFECTS='+json.dumps(bank,indent=2)+'\nconst LOOPS='+json.dumps(loops,indent=2)+'\n')
# A short offline preview of representative effects; this is not a recording of human play.
reel=[0.0]*int(RATE*14)
for name,at,gain in [("pulse_0",.3,.75),("pulse_1",.5,.75),("pulse_2",.7,.75),("plasma_0",1.6,.8),("rail_charge",2.7,.6),("rail_0",3.28,.8),("metal_hit_1",4.5,.8),("shield_impact",5.25,.8),("missile_launch",6.0,.8),("explosion_1",7.0,.85),("door_open_0",9.1,.8),("door_close_0",9.85,.8),("engine_loop",10.7,.35),("boost_loop",11.9,.5)]:
 with wave.open(str(OUT/(name+".wav")),"rb") as f: data=array.array("h",f.readframes(f.getnframes()))
 start=int(at*RATE)
 for i,v in enumerate(data[:len(reel)-start]):reel[start+i]+=v/32768*gain
end=int(.3*RATE)
for i in range(end):reel[-end+i]*=1-i/(end-1)
level=max(abs(v) for v in reel);mult=.8/max(1,level)
preview=ROOT/"exports/v09-sound-preview.wav"
with wave.open(str(preview),"wb") as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(array.array("h",(round(v*mult*32767) for v in reel)).tobytes())
print("Prepared",len(records),"effects/loops and",preview.name)
