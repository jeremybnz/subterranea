extends SceneTree
const Profile=preload("res://scripts/campaign.gd")
var game
var failures=0
var routes=[]
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true)
	Engine.time_scale=4; Engine.physics_ticks_per_second=120
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures+=1; push_error(label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func action(name: String,on: bool,strength: float = 1.0) -> void:
	if on: Input.action_press("ship_"+name,strength)
	else: Input.action_release("ship_"+name)
func fresh(index: int) -> void:
	if is_instance_valid(game): game.queue_free(); await process_frame; await process_frame
	root.set_meta("mission_selection",index)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await process_frame; await physics_frame
	game.launch(); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false)
func follow() -> bool:
	game.player.set_physics_process(true); game.player.velocity=Vector3.ZERO
	game.player.shield=10000
	var started=game.mission_time
	for i in range(3000):
		var courier=game.exploration.escort
		if courier.status=="delivered":
			action("forward",false); game.player.set_physics_process(false)
			routes.append({"mission":game.mission_index+1,"seconds":game.mission_time-started,"status":courier.status})
			return true
		for d in game.drones: d.set_physics_process(false)
		var distance=game.player.position.distance_to(courier.position)
		if distance>0.3:
			var dir=(courier.position-game.player.position).normalized()
			game.player.look_at(courier.position,Vector3.UP if absf(dir.y)<0.98 else Vector3.RIGHT)
		action("forward",distance>3.5,clampf((distance-3)/6,0.1,0.8))
		await physics_frame
	push_error("Escort blocked: "+str(game.exploration.escort.position)+" waypoint "+str(game.exploration.escort.waypoint)+" pilot "+str(game.player.position))
	action("forward",false); game.player.set_physics_process(false)
	return false
func window_blocks(index: int) -> bool:
	var origin=[Vector3(0,44,-103),Vector3(52,0,-64),Vector3(0,0,-127)][index]
	var query=PhysicsShapeQueryParameters3D.new(); var s=SphereShape3D.new(); s.radius=0.65
	query.shape=s; query.transform=Transform3D(Basis.IDENTITY,origin+Vector3(0,0,3)); query.motion=Vector3(0,0,-8); query.collision_mask=1
	return game.get_world_3d().direct_space_state.cast_motion(query)[0]<0.7
func find_paint(node: Node,color: Color) -> bool:
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var material=node.get_surface_override_material(i)
			if material is StandardMaterial3D and material.albedo_color.is_equal_approx(color): return true
	for child in node.get_children():
		if find_paint(child,color): return true
	return false
func run() -> void:
	var old={"version":1,"unlocked":0,"selected":0,"upgrades":{},"records":[]}
	var profile=Profile.new("",false)
	var data=profile.sanitized(old)
	check(data.logs.is_empty() and data.paints==["abyss"] and data.paint=="abyss","Version 0.5 profiles migrate with intact defaults for exploration and livery")
	check(not profile.discover("logs","bad") and profile.discover("caches","0_cache",200,"ember"),"Only canonical discoveries can award cache rewards")
	profile.discover("caches","0_cache",200,"ember")
	check(profile.data.salvage==200 and profile.data.paints.has("ember"),"A cache awards salvage and its paint once per profile")
	var folder="res://tests/tmp_exploration_"+str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path=folder+"/profile.json"
	var stored=Profile.new(path); stored.discover("logs","0_0"); stored.discover("caches","1_cache",200,"glacier"); stored.data.paint="glacier"; stored.save()
	var loaded=Profile.new(path); loaded.load_profile()
	check(loaded.data.logs==["0_0"] and loaded.data.paint=="glacier" and loaded.data.paints.has("glacier"),"Discoveries and equipped paint survive a real profile write/read")
	for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	for index in range(3):
		await fresh(index)
		check(game.exploration.items.size()==5 and window_blocks(index),"Operation %d has all discovery actors and a physically sealed observation window" % (index+1))
		var ex=game.exploration
		for item in ex.items:
			if item.kind!="log": continue
			game.player.position=item.pos+Vector3(0,0,1.8); action("interact",true); ex.tick=0; ex.update(1.6); action("interact",false)
			check(item.claimed and item.id in game.campaign.data.logs,"Operation %d recorder %d downloads through held interaction" % [index+1,item.index+1])
		var cache=ex.items.filter(func(i): return i.kind=="cache")[0]
		game.player.position=cache.pos; ex.update(0.1)
		check(cache.claimed and game.campaign.data.salvage==200,"Operation %d cache grants its one-time discovery reward" % (index+1))
		check(ex.select_paint(ex.Lore.PAINTS[index+1].id) and find_paint(game.menu_ship,ex.paint().hull),"Unlocked operation %d paint changes actual Kestrel hull materials" % (index+1))
		check(not ex.select_paint("unknown"),"Unknown liveries cannot be equipped")
		var pod=ex.items.filter(func(i): return i.kind=="pod")[0]
		game.player.position=pod.pos+Vector3(0,0,2); action("interact",true); ex.tick=0; ex.update(1.6); action("interact",false)
		check(ex.crew_rescued and ex.escort.status=="following","Operation %d refuge interaction secures crew and launches the courier" % (index+1))
		var courier=ex.escort; game.player.position=courier.position+Vector3(0,0,25)
		await frames(8)
		check(courier.status=="waiting","Courier waits when the pilot leaves its escort radius")
		courier.hurt(10000)
		check(courier.status=="disabled" and courier.integrity==0,"A disabled courier remains available for repair")
		game.player.position=courier.position+Vector3(0,0,2); action("interact",true); ex.tick=0; ex.update(1.6); action("interact",false)
		check(courier.status=="following" and courier.integrity==100,"Held interaction repairs the courier and resumes its route")
		if index==0:
			game.store_checkpoint(); var saved=game.campaign.data.duplicate(true)
			await fresh(0); game.campaign.data=saved; check(game.restore_checkpoint(),"Checkpoint restores an active exploration run")
			ex=game.exploration; courier=ex.escort
			check(ex.crew_rescued and courier.status=="following" and courier.route.size()>4 and courier.integrity==100,"Checkpoint retains crew, courier route, integrity and progress")
			check(game.campaign.data.logs.size()==3 and game.campaign.data.paint=="ember","Restored profile retains journal discoveries and paint")
			game.player.position=courier.position+Vector3(0,0,25)
			await frames(5); courier.integrity=160
			game.enemy_shot(courier.position+Vector3(4,0,0),Vector3.LEFT,22,12)
			await frames(12)
			check(courier.integrity<160,"Enemy projectile collision applies real damage to the courier")
			courier.integrity=160
			game.player.position=courier.position+Vector3(0,0,3)
			var attacker=game.spawn_drone(courier.position+Vector3(4,0,0),"striker"); attacker.set_physics_process(false); attacker.spawn_id=900
			check(attacker.attack_target()==courier,"Eligible enemy squads can select the active rescue courier")
			game.state="paused"; game.hud.show_journal(); check(game.hud.front_view=="journal","Journal can be reviewed from pause without restarting the run")
			var event=InputEventKey.new(); event.keycode=KEY_ESCAPE; event.pressed=true; game._input(event)
			check(game.state=="paused" and game.hud.front_view=="title","Escape from the journal returns to the pause menu")
			game.resume()
		game.player.position=courier.position+Vector3(0,0,3)
		check(await follow(),"Operation %d courier and pilot physically traverse the rescue route to extraction" % (index+1))
		var score=game.score; courier.deliver()
		check(game.score==score,"A delivered courier cannot grant its score reward twice")
		var base=650+index*250+game.kills*35+500
		var reward=game.campaign.complete(index,0,100,game.kills,false,"rescue-check-"+str(index),false,true,true)
		check(reward==base+550 and game.campaign.data.records[index].rescue and game.campaign.data.records[index].escort,"Extraction awards crew and courier salvage plus permanent rescue records")
		game.exploration.queue_radio("escape",true); var history=game.campaign.data.radio.size(); game.exploration.queue_radio("escape",true)
		check(game.exploration.radio_current.id==str(index)+"_escape" and history==game.campaign.data.radio.size(),"Urgent escape radio captions interrupt once and remain in the journal")
		game.sound._process(0.01)
		check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))==-4 and game.sound.music.bus=="Music","Radio captions duck the separate music mix")
	game.state="paused"
	game.sound.play_tone("ui",0.4); game.sound._process(0.01)
	var cue=get_nodes_in_group("mix_Interface")[-1]
	check(not cue.stream_paused,"Interface sounds remain audible in pause and journal screens")
	game.state="playing"
	game.result_recorded=false; game.exploration.crew_rescued=true; game.exploration.escort.status="following"; game.exploration.escort.position=game.extraction+Vector3(0,0,-7)
	game.finish(true,"EVACUATED","Rescue complete.")
	check(game.exploration.escort.status=="delivered","Extraction safely recovers a nearby courier already inside the arrival chamber")
	for i in range(30): game.sound.play_tone("laser",0.1)
	check(get_nodes_in_group("mix_Weapons").size()<=20,"Weapon sound voice limits remain bounded during bursts")
	var file=FileAccess.open("res://tests/exploration_routes.json",FileAccess.WRITE); file.store_string(JSON.stringify({"failures":failures,"routes":routes},"\t")); file.close()
	print("EXPLORATION TEST COMPLETE: ",failures," failures")
	game.queue_free(); await process_frame; await process_frame; quit(1 if failures else 0)
