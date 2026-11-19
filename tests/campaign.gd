extends SceneTree
const Profile=preload("res://scripts/campaign.gd")
var failures=0
var scene=preload("res://scenes/main.tscn")
var game
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else: failures+=1; push_error(message)
func _initialize() -> void:
	root.set_meta("test_session",true)
	call_deferred("run")
func key(code: Key,pressed: bool) -> void:
	var event=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func fresh(index: int) -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
		await process_frame
	root.set_meta("mission_selection",index)
	root.set_meta("front_view","title")
	game=scene.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game.launch()
	game.player.set_physics_process(false)
	for drone in game.drones: drone.set_physics_process(false)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false)
func passable(a: Vector3,b: Vector3) -> bool:
	var query=PhysicsShapeQueryParameters3D.new()
	var sphere=SphereShape3D.new()
	sphere.radius=0.7
	query.shape=sphere
	query.transform=Transform3D(Basis.IDENTITY,a)
	query.motion=b-a
	query.collision_mask=1
	return game.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99
func run() -> void:
	var folder="res://tests/tmp_profile_"+str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path=folder+"/campaign.json"
	var profile=Profile.new(path)
	check(profile.data.unlocked==0 and profile.data.salvage==0,"A new campaign starts at operation one with no free upgrades")
	check(not profile.buy("shields") and not profile.buy("unknown"),"Purchases reject insufficient salvage and invalid parts")
	profile.data.salvage=1800
	check(profile.buy("shields") and profile.level("shields")==1 and profile.data.salvage==1300,"Upgrade purchases deduct their listed cost")
	var loaded=Profile.new(path)
	check(loaded.load_profile() and loaded.level("shields")==1 and loaded.data.salvage==1300,"Upgrade and currency data survive a fresh profile load")
	var reward=profile.complete(0,3200,140,10,true,"first-run")
	check(reward==1750 and profile.data.unlocked==1 and profile.data.records[0].completed,"First mission awards salvage and unlocks operation two")
	var balance=profile.data.salvage
	check(profile.complete(0,9999,1,99,true,"first-run")==0 and profile.data.salvage==balance,"The same mission run cannot claim its reward twice")
	profile.complete(0,1000,200,3,false,"replay-run")
	check(profile.data.records[0].best_score==3200 and profile.data.records[0].best_time==140 and profile.data.records[0].runs==2,"Replays preserve best score and best completion time")
	profile.complete(1,4000,120,12,false,"second-run")
	profile.complete(2,6000,180,14,false,"third-run")
	check(profile.data.unlocked==2 and profile.data.records[2].completed,"Completing the campaign preserves all three operation records")
	profile.data.salvage=50000
	for part in Profile.PARTS:
		while profile.level(part)<3:
			var next_level=profile.level(part)+1
			check(profile.buy(part),"Install "+part+" level "+str(next_level))
	balance=profile.data.salvage
	check(not profile.buy("shields") and profile.data.salvage==balance,"Maximum-level upgrades cannot consume more salvage")
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string("{broken profile")
	file.close()
	loaded=Profile.new(path)
	check(loaded.load_profile() and loaded.recovered_backup,"A damaged primary profile recovers from the previous save")
	check(loaded.save() and not loaded.read_profile(path).is_empty(),"Recovered progress can be saved without losing the backup")
	for filename in DirAccess.get_files_at(folder): DirAccess.remove_absolute(ProjectSettings.globalize_path(folder.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	await fresh(0)
	game.player.position=Vector3(0,0,-44)
	game.player.rotation=Vector3(0.2,1.0,0.4)
	game.player.shield=63
	game.player.energy=42
	game.player.boost=57
	game.player.missiles=3
	game.damage_object(game.targets[0].node,100)
	game.damage_object(game.drones[0],100)
	game.secret_door.breach()
	game.score=777
	game.campaign.data.upgrades.shields=1
	var count=game.drones.size()
	check(game.store_checkpoint(),"Active flight captures a mission checkpoint")
	var snapshot=game.campaign.data.duplicate(true)
	await fresh(0)
	game.campaign.data=snapshot
	game.player.apply_upgrades()
	check(game.restore_checkpoint(),"A fresh mission instance restores its saved checkpoint")
	check(game.player.position.distance_to(Vector3(0,0,-44))<0.01 and game.player.rotation.distance_to(Vector3(0.2,1,0.4))<0.01,"Checkpoint restores ship position and orientation")
	check(game.player.shield==63 and game.player.shield_max==125 and game.player.missiles==3 and game.player.energy==42,"Checkpoint restores resources and permanent upgrades together")
	check(game.relays_down==1 and not game.targets[0].alive and game.score==777 and game.drones.size()==count,"Checkpoint preserves objectives, score and remaining enemies")
	check(game.secret_door.revealed,"Checkpoint preserves breached secret access")
	game.state="menu"
	game.hud.front_view="workshop"
	game.campaign.data.salvage=10000
	game.hud.rebuild_menu()
	for part in ["shields","engines","cannons","missiles"]:
		var before=game.campaign.level(part)
		var index=["shields","engines","cannons","missiles"].find(part)
		game.hud.ui.get_child(index).pressed.emit()
		check(game.campaign.level(part)==before+1,"Upgrade bay button purchases the correct "+part+" component")
	check(game.player.cannon_damage>18 and game.player.engine_factor>1 and game.player.missile_damage>110,"Installed upgrades alter actual flight and weapon statistics")
	await fresh(1)
	check(game.mission_index==1 and game.targets[0].kind=="archive","Operation two builds a distinct archive-recovery mission")
	check(passable(Vector3(0,0,-48),Vector3(0,47,-48)),"Cryo station vertical access has ship-sized clearance")
	game.damage_object(game.targets[0].node,999)
	check(game.targets[0].alive,"Archive recovery requires interaction rather than weapon damage")
	game.player.position=game.targets[3].pos+Vector3(0,0,4)
	key(KEY_R,true)
	for i in range(40): game.update_interaction(0.1)
	key(KEY_R,false)
	check(not game.reactor_down,"Uplink cannot transmit before the three archives are recovered")
	for index in range(3):
		game.player.position=game.targets[index].pos+Vector3(0,0,4)
		key(KEY_R,true)
		for i in range(23): game.update_interaction(0.1)
		key(KEY_R,false)
	check(game.relays_down==3 and not game.core_door.locked,"Holding R recovers archives and unlocks the uplink")
	game.player.position=game.targets[3].pos+Vector3(0,0,4)
	key(KEY_R,true)
	for i in range(33): game.update_interaction(0.1)
	key(KEY_R,false)
	check(game.reactor_down and not game.targets[3].alive,"Uploading evidence starts the interception escape sequence")
	game.player.position=game.extraction
	game._process(0.016)
	check(game.state=="won" and game.campaign.data.unlocked==2,"Archive mission extraction awards progression to the fortress")
	await fresh(2)
	check(game.mission_index==2 and is_instance_valid(game.boss),"Operation three builds the fortress and its authored boss")
	check(not game.path_to("dock","crown").is_empty(),"The crown shield node remains reachable before the boss shield is disabled")
	check(passable(Vector3(52,0,-25),Vector3(52,-40,-25)),"Fortress descent shaft has ship-sized clearance")
	check(passable(Vector3(0,0,-100),Vector3(0,40,-100)),"Boss chamber ascent reaches the crown shield node")
	var boss=game.boss
	boss.hit(999,Vector3.ZERO,true)
	check(boss.health==1500,"Overseer is invulnerable while shield generators remain")
	for i in range(3): game.damage_object(game.targets[i].node,100)
	var shots=game.projectiles.size()
	boss.phase=1
	boss.fire_attack()
	check(game.projectiles.size()==shots+3,"Overseer first phase fires an aimed spread")
	shots=game.projectiles.size()
	boss.phase=2
	boss.fire_attack()
	check(game.projectiles.size()==shots+12,"Overseer second phase fires a radial barrage")
	for shot in game.projectiles.duplicate(): game.remove_projectile(shot)
	game.player.position=Vector3(0,0,-83)
	game.player.shield=100
	await frames(2)
	boss.phase=3
	boss.locked_aim=game.player.position
	boss.fire_attack()
	check(game.player.shield==74,"Overseer beam deals real raycast damage")
	var shields=game.player.shield
	game.player.position=Vector3(9,0,-83)
	await frames(2)
	boss.fire_attack()
	check(game.player.shield==shields,"Moving out of the marked beam line avoids damage")
	boss.phase=1
	boss.health=1500
	boss.warming=0
	boss.hit(2000,Vector3.ZERO)
	check(boss.phase==2 and boss.health==1000 and boss.reinforcements,"Boss phase transition summons escorts and prevents phase skipping")
	boss.hit(2000,Vector3.ZERO)
	check(boss.health==1000,"Boss transition shield prevents instant phase bypass")
	boss.warming=0
	boss.hit(2000,Vector3.ZERO)
	check(boss.phase==3 and boss.health==500,"Boss advances to its final beam phase")
	boss.warming=0
	boss.hit(600,Vector3.ZERO)
	check(boss.dead and game.reactor_down and not game.targets[3].alive,"Defeating the Overseer starts the final escape")
	game.player.position=game.extraction
	game._process(0.016)
	check(game.state=="won" and game.campaign.data.records[2].completed,"Final extraction records campaign completion")
	print("CAMPAIGN TEST COMPLETE: ",failures," failures")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
