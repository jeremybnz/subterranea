extends RefCounted
## Versioned campaign profile. Writes use a temporary file and keep a previous copy.
const Lore=preload("res://scripts/lore.gd")
const MISSIONS = [
	{"title":"THE NEREID INCIDENT","location":"NEREID / MINING COMPLEX","tag":"01 / BREAK THE SILENCE","brief":"Three relays feed a rogue reactor. Cut the power, destroy the core, and escape.","objective":"DISABLE POWER RELAYS","color":Color("76e9df"),"escape":75.0},
	{"title":"COLD SIGNAL","location":"BOREAS / CRYO ARCHIVE","tag":"02 / RECOVER THE TRUTH","brief":"Recover three encrypted archives. Upload the evidence and evade the response fleet.","objective":"RECOVER ENCRYPTED ARCHIVES","color":Color("9dbdff"),"escape":90.0},
	{"title":"HEART OF THE MACHINE","location":"HELIOS / REACTOR FORTRESS","tag":"03 / KILL THE OVERSEER","brief":"Destroy three shield nodes. Defeat the Overseer and escape the collapsing fortress.","objective":"DESTROY SHIELD NODES","color":Color("ffbd79"),"escape":90.0}]
const PARTS = {
	"shields":{"title":"AEGIS SHIELDS","description":"+25 maximum shields per level","base":500,"step":350},
	"engines":{"title":"VECTOR ENGINES","description":"Faster thrust, boost and acceleration","base":550,"step":350},
	"cannons":{"title":"PULSE AMPLIFIER","description":"Amplifies pulse, plasma and rail damage","base":650,"step":400},
	"missiles":{"title":"SEEKER RACK","description":"+25 blast damage, +2 starting missiles","base":550,"step":350}}
var path="user://campaign_v1.json"
var persistent=true
var data: Dictionary
var last_error=""
var recovered_backup=false

func _init(save_path: String = "user://campaign_v1.json",enable_storage: bool = true) -> void:
	path=save_path
	persistent=enable_storage
	reset_data()

func reset_data() -> void:
	data={"version":1,"unlocked":0,"selected":0,"salvage":0,"upgrades":{"shields":0,"engines":0,"cannons":0,"missiles":0},"records":[],"checkpoint":{},"claimed_runs":[],"training_complete":false,"logs":[],"caches":[],"radio":[],"paints":["abyss"],"paint":"abyss","manual_slots":[{},{},{}]}
	for i in range(3): data.records.append({"completed":false,"best_score":0,"best_time":0.0,"runs":0,"secret":false})

func level(part: String) -> int:
	return int(data.upgrades.get(part,0))

func cost(part: String) -> int:
	if not PARTS.has(part) or level(part)>=3: return 0
	return PARTS[part].base+level(part)*PARTS[part].step

func buy(part: String) -> bool:
	if not PARTS.has(part) or level(part)>=3 or data.salvage<cost(part): return false
	var previous=data.duplicate(true)
	data.salvage-=cost(part)
	data.upgrades[part]=level(part)+1
	if not save(): data=previous; return false
	return true

func complete(mission: int,score: int,seconds: float,kills: int,secret: bool,run: String,challenge: bool = false,rescue: bool = false,escort: bool = false,rating: Dictionary = {}) -> int:
	if mission<0 or mission>2 or run in data.claimed_runs: return 0
	var record=data.records[mission]
	var first=not record.completed
	var reward=650+mission*250+kills*35+(250 if secret else 0)+(500 if first else 0)+(300 if challenge else 0)+(250 if rescue else 0)+(300 if escort else 0)
	if not rating.is_empty():
		var best=record.get("medals",{})
		for category in ["combat","exploration","rescue","escape"]: best[category]=maxi(int(best.get(category,0)),int(rating.medals.get(category,0)))
		record["medals"]=best
		if int(rating.get("points",0))>=int(record.get("rating_points",0)):
			record["rating_points"]=int(rating.points); record["rank"]=str(rating.rank)
	record.completed=true
	record.best_score=maxi(record.best_score,score)
	if record.best_time<=0 or seconds<record.best_time: record.best_time=seconds
	record.runs+=1
	record.secret=record.secret or secret
	record["challenge"]=bool(record.get("challenge",false)) or challenge
	record["rescue"]=bool(record.get("rescue",false)) or rescue
	record["escort"]=bool(record.get("escort",false)) or escort
	data.salvage+=reward
	data.unlocked=maxi(data.unlocked,mini(2,mission+1))
	data.claimed_runs.append(run)

	data.checkpoint={}
	save()
	return reward

func sanitized(value: Variant) -> Dictionary:
	if not value is Dictionary or value.get("version",0)!=1: return {}
	var result={"version":1,"unlocked":0,"selected":0,"salvage":0,"upgrades":{},"records":[],"checkpoint":{},"claimed_runs":[],"training_complete":false,"logs":[],"caches":[],"radio":[],"paints":["abyss"],"paint":"abyss","manual_slots":[{},{},{}]}
	result.training_complete=bool(value.get("training_complete",false))
	result.unlocked=clampi(int(value.get("unlocked",0)),0,2)
	result.selected=clampi(int(value.get("selected",0)),0,result.unlocked)
	result.salvage=clampi(int(value.get("salvage",0)),0,10000000)
	var upgrades=value.get("upgrades",{})
	for part in PARTS: result.upgrades[part]=clampi(int(upgrades.get(part,0)),0,3) if upgrades is Dictionary else 0
	var records=value.get("records",[])
	for i in range(3):
		var r=records[i] if records is Array and i<records.size() and records[i] is Dictionary else {}
		result.records.append({"completed":bool(r.get("completed",false)),"best_score":maxi(0,int(r.get("best_score",0))),"best_time":maxf(0,float(r.get("best_time",0))),"runs":maxi(0,int(r.get("runs",0))),"secret":bool(r.get("secret",false)),"challenge":bool(r.get("challenge",false)),"rescue":bool(r.get("rescue",false)),"escort":bool(r.get("escort",false)),"medals":clean_medals(r.get("medals",{})),"rating_points":clampi(int(r.get("rating_points",0)),0,12),"rank":str(r.get("rank","--")) if str(r.get("rank","--")) in ["S","A","B","C","D"] else "--"})
	for kind in ["logs","caches","radio"]:
		for id in value.get(kind,[]) if value.get(kind,[]) is Array else []:
			if valid_discovery(kind,str(id)) and id not in result[kind]: result[kind].append(id)
	for paint in Lore.PAINTS:
		if paint.id in (value.get("paints",[]) if value.get("paints",[]) is Array else []) and paint.id not in result.paints: result.paints.append(paint.id)
	result.paint=str(value.get("paint","abyss")) if str(value.get("paint","abyss")) in result.paints else "abyss"
	var checkpoint=value.get("checkpoint",{})
	if checkpoint is Dictionary and not checkpoint.is_empty() and int(checkpoint.get("mission",-1)) in range(result.unlocked+1) and checkpoint.get("pilot",null) is Dictionary and checkpoint.get("targets",null) is Array:
		result.checkpoint=checkpoint
	var slots=value.get("manual_slots",[])
	if slots is Array:
		for i in range(mini(3,slots.size())):
			if slots[i] is Dictionary and valid_checkpoint(slots[i].get("checkpoint",{}),result.unlocked): result.manual_slots[i]={"checkpoint":slots[i].checkpoint.duplicate(true),"saved_at":maxi(0,int(slots[i].get("saved_at",0)))}
	var claims=value.get("claimed_runs",[])
	if claims is Array:
		for run in claims:
			if run is String: result.claimed_runs.append(run)
	return result

func read_profile(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {}
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path))!=OK: return {}
	return sanitized(parser.data)

func load_profile() -> bool:
	if not persistent: return true
	var loaded=read_profile(path)
	if loaded.is_empty():
		loaded=read_profile(path+".bak")
		recovered_backup=not loaded.is_empty()
	if loaded.is_empty():
		if FileAccess.file_exists(path): last_error="Profile could not be read; original files have been preserved."
		return false
	data=loaded
	return true

func save() -> bool:
	if not persistent: return true
	var temporary=path+".tmp"
	var file=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:
		last_error="Could not write campaign progress."
		return false
	file.store_string(JSON.stringify(data,"	"))
	file.flush()
	file.close()
	if not FileAccess.file_exists(temporary) or read_profile(temporary).is_empty():
		last_error="Campaign save validation failed."
		return false
	var absolute=ProjectSettings.globalize_path(path)
	# Rotate only a valid primary; preserve the backup if recovering from corruption.
	if not read_profile(path).is_empty():
		if FileAccess.file_exists(path+".bak"): DirAccess.remove_absolute(absolute+".bak")
		if DirAccess.rename_absolute(absolute,absolute+".bak")!=OK:
			last_error="Could not preserve the previous campaign save."
			return false
	elif FileAccess.file_exists(path):
		var damaged=absolute+".unreadable_"+str(Time.get_unix_time_from_system()).replace(".","_")
		if DirAccess.rename_absolute(absolute,damaged)!=OK: return false
	if DirAccess.rename_absolute(absolute+".tmp",absolute)!=OK:
		last_error="Could not finalize campaign save."
		return false
	last_error=""
	return true

func valid_discovery(kind: String,id: String) -> bool:
	for mission in range(3):
		if kind=="caches" and id==str(mission)+"_cache": return true
		if kind=="logs":
			for i in range(3):
				if id==str(mission)+"_"+str(i): return true
		if kind=="radio":
			for entry in Lore.RADIO[mission]:
				if id==entry.id: return true
	return false
func discover(kind: String,id: String,reward: int = 0,paint: String = "") -> bool:
	if not valid_discovery(kind,id): return false
	if id in data[kind]: return true
	var previous=data.duplicate(true)
	data[kind].append(id); data.salvage+=maxi(0,reward)
	if not paint.is_empty() and paint not in data.paints:
		for entry in Lore.PAINTS:
			if entry.id==paint: data.paints.append(paint)
	if not save(): data=previous; return false
	return true

func clean_medals(value: Variant) -> Dictionary:
	var output={}
	for category in ["combat","exploration","rescue","escape"]: output[category]=clampi(int(value.get(category,0)),0,3) if value is Dictionary else 0
	return output
func valid_checkpoint(value: Variant,unlocked: int) -> bool:
	if not value is Dictionary or value.is_empty(): return false
	if int(value.get("mission",-1)) not in range(unlocked+1) or not value.get("pilot",null) is Dictionary or not value.get("targets",null) is Array or value.targets.size()!=4: return false
	var pos=value.pilot.get("pos",[])
	if not pos is Array or pos.size()!=3: return false
	for coordinate in pos:
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)): return false
	return not str(value.get("run","")).is_empty()
func save_slot(index: int,checkpoint: Dictionary) -> bool:
	if index not in range(3) or not valid_checkpoint(checkpoint,data.unlocked): last_error="No valid active mission to save."; return false
	var previous=data.manual_slots[index].duplicate(true)
	data.manual_slots[index]={"checkpoint":checkpoint.duplicate(true),"saved_at":int(Time.get_unix_time_from_system())}
	if not save(): data.manual_slots[index]=previous; return false
	return true
func load_slot(index: int) -> bool:
	if index not in range(3) or data.manual_slots[index].is_empty() or not valid_checkpoint(data.manual_slots[index].get("checkpoint",{}),data.unlocked): last_error="That manual slot is empty or invalid."; return false
	var previous=data.checkpoint.duplicate(true); data.checkpoint=data.manual_slots[index].checkpoint.duplicate(true)
	if not save(): data.checkpoint=previous; return false
	return true
