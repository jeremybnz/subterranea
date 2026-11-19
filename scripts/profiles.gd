extends RefCounted
const Campaign=preload("res://scripts/campaign.gd")
const FILES=["campaign_v1.json","campaign_2_v1.json","campaign_3_v1.json"]
var folder="user://"
var persistent=true
var active=0
var error=""
func _init(directory: String = "user://",storage: bool = true):
	folder=directory; persistent=storage
	if persistent:
		var cfg=ConfigFile.new()
		if cfg.load(folder.path_join("profiles.cfg"))==OK: active=clampi(int(cfg.get_value("profiles","active",0)),0,2)
func path_for(index: int) -> String: return folder.path_join(FILES[clampi(index,0,2)])
func current_path() -> String: return path_for(active)
func activate(index: int) -> bool:
	if index not in range(3): return false
	if persistent:
		var cfg=ConfigFile.new(); cfg.set_value("profiles","active",index)
		var temporary=folder.path_join("profiles.cfg.tmp")
		if cfg.save(temporary)!=OK: error="Could not save profile selection."; return false
		var target=ProjectSettings.globalize_path(folder.path_join("profiles.cfg"))
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),target)!=OK: error="Could not update profile selection."; return false
	active=index; error=""; return true
func summaries() -> Array:
	var rows=[]
	for i in range(3):
		var profile=Campaign.new(path_for(i),persistent); profile.load_profile()
		var runs=0
		for record in profile.data.records: runs+=record.runs
		rows.append({"index":i,"active":i==active,"exists":FileAccess.file_exists(path_for(i)) if persistent else i==active,"unlocked":profile.data.unlocked+1,"salvage":profile.data.salvage,"runs":runs,"checkpoint":not profile.data.checkpoint.is_empty(),"error":profile.last_error})
	return rows
