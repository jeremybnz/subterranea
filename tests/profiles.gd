extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
const Profiles=preload("res://scripts/profiles.gd")
var game
var failures=0
var folder="res://tests/tmp_profiles_"+str(OS.get_process_id())
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); root.set_meta("profile_fixture",folder); call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures+=1; push_error(label)
func settle() -> void:
	for i in range(5): await process_frame
	game=current_scene
	game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	for f in game.systems.foundries: f.set_physics_process(false)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var legacy=Campaign.new(folder.path_join("campaign_v1.json")); legacy.data.salvage=2345; legacy.data.unlocked=1; legacy.data.upgrades.engines=1; legacy.save()
	var original=FileAccess.get_file_as_string(legacy.path)
	var profiles=Profiles.new(folder)
	check(profiles.active==0 and profiles.current_path()==legacy.path,"Existing campaign remains Pilot 1 without migration")
	check(profiles.activate(1) and profiles.activate(2) and profiles.activate(0) and Profiles.new(folder).active==0,"Profile selection survives repeated atomic replacement and restart")
	check(FileAccess.get_file_as_string(legacy.path)==original,"Selecting profiles leaves original campaign bytes intact")
	change_scene_to_file("res://scenes/main.tscn"); await settle()
	check(game.campaign.data.salvage==2345 and game.campaign.level("engines")==1,"Legacy upgrades and salvage load in the actual game")
	game.launch(); game.state="paused"; game.player.position=game.nav_nodes.nexus; game.score=321; game.mission_time=42
	game.survey.seen=range(game.map_rooms.size()); game.survey.place_marker("pump")
	game.systems.has_key=true; game.systems.gate.unlock(); game.systems.foundries[0].hit(1000)
	game.score=321
	var token=game.run_token
	game.hud.show_saves(); game.hud.request_slot_save(0)
	check(not game.campaign.data.manual_slots[0].is_empty(),"Pause menu saves a real mission into an empty manual slot")
	var saved=game.campaign.data.manual_slots[0].checkpoint.duplicate(true)
	game.score=654; game.store_checkpoint()
	check(game.campaign.data.checkpoint.score==654 and game.campaign.data.manual_slots[0].checkpoint.score==321,"Autosave advances independently of manual snapshots")
	game.hud.request_slot_save(0)
	check(game.hud.confirm_slot==0 and game.campaign.data.manual_slots[0].checkpoint.score==321,"Occupied slot requires explicit overwrite confirmation")
	game.hud.request_slot_save(0)
	check(game.campaign.data.manual_slots[0].checkpoint.score==654,"Second overwrite click commits the replacement")
	check(game.manual_save(1) and game.manual_save(2),"All three manual slots accept independent snapshots")
	game.campaign.data.manual_slots[0].checkpoint=saved; game.campaign.save()
	game.campaign.discover("logs","0_0",100); game.campaign.buy("shields")
	var balance=game.campaign.data.salvage
	game.hud.request_slot_load(0)
	check(game.hud.confirm_load==0 and game.score==654,"Loading a slot first requests confirmation without replacing the run")
	game.hud.request_slot_load(0); await settle()
	check(game.state=="playing" and game.run_token==token and game.score==321 and game.mission_time>=42 and game.mission_time<43,"Confirmed load restores the manual run through a scene reload")
	check(game.player.position.distance_to(game.nav_nodes.nexus)<0.1 and game.systems.has_key and game.systems.foundries[0].destroyed and game.survey.pin=="pump" and game.survey.seen.size()==game.map_rooms.size(),"Manual load restores location, security, foundry shutdown and map pin")
	check(game.campaign.level("shields")==1 and game.campaign.data.salvage==balance and "0_0" in game.campaign.data.logs,"Loading an older run retains permanent purchases and discoveries")
	game.campaign.complete(0,100,90,2,false,token)
	var reward_balance=game.campaign.data.salvage
	check(game.campaign.load_slot(0) and game.campaign.complete(0,100,90,2,false,token)==0 and game.campaign.data.salvage==reward_balance,"Replaying a completed manual save cannot claim its reward twice")
	game.campaign.data.checkpoint={}; game.campaign.save()
	check(not game.campaign.data.manual_slots[0].is_empty(),"Clearing the autosave leaves manual slots available")
	game.state="menu"; check(game.switch_profile(1),"Campaign deck switches to Pilot 2"); await settle()
	check(game.profile_store.active==1 and game.campaign.data.salvage==0 and game.campaign.data.manual_slots[0].is_empty(),"Pilot 2 starts with isolated campaign progress and saves")
	game.campaign.data.salvage=700; game.campaign.save(); check(game.switch_profile(2),"Campaign deck switches to Pilot 3"); await settle()
	check(game.campaign.data.salvage==0 and game.profile_store.active==2,"Pilot 3 remains independent of both other profiles")
	game.campaign.data.salvage=900; game.campaign.save(); game.switch_profile(0); await settle()
	check(game.campaign.data.salvage==reward_balance and not game.campaign.data.manual_slots[0].is_empty(),"Returning to Pilot 1 restores its progress and slots")
	var rows=game.profile_store.summaries()
	check(rows.size()==3 and rows[1].salvage==700 and rows[2].salvage==900,"Profile cards read the matching campaign summaries")
	game.state="paused"; check(not game.switch_profile(1),"Profile changes cannot replace a paused active flight")
	var corrupt=game.campaign.data.duplicate(true); corrupt.manual_slots=[{"checkpoint":{"mission":0,"pilot":{"pos":[0,0,0]},"targets":[],"run":"bad"}},5,{}]
	check(game.campaign.sanitized(corrupt).manual_slots[0].is_empty(),"Malformed manual checkpoints are rejected on load")
	game.queue_free(); current_scene=null; await process_frame; await process_frame
	for file in DirAccess.get_files_at(folder): DirAccess.remove_absolute(ProjectSettings.globalize_path(folder.path_join(file)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	print("PROFILES TEST COMPLETE: ",failures," failures"); quit(1 if failures else 0)
