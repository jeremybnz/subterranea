extends SceneTree
var game
var failures=0
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true)
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures+=1; push_error(label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func action(name: String,on: bool) -> void:
	if on: Input.action_press("ship_"+name)
	else: Input.action_release("ship_"+name)
func fresh(mission: int) -> void:
	if is_instance_valid(game): game.queue_free(); await process_frame; await process_frame
	root.set_meta("mission_selection",mission)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await process_frame; await physics_frame
	game.launch()
	for d in game.drones: d.set_physics_process(false)
func clear_shots() -> void:
	for shot in game.projectiles.duplicate(): game.remove_projectile(shot)
func run() -> void:
	await fresh(0)
	check(game.director.hazards.size()==3,"Each operation builds three interactive hazards")
	game.controls.load_bindings({"forward":["key",KEY_2]}, {})
	check(game.controls.bindings.forward==["key",KEY_2] and game.controls.bindings.plasma_weapon==["key",KEY_W],"Legacy custom keys retain precedence over new weapon defaults without duplicate bindings")
	game.controls.reset()
	game.player.position=Vector3.ZERO; game.player.rotation=Vector3.ZERO
	var target=game.spawn_drone(Vector3(0,0,-9),"bulwark"); target.set_physics_process(false)
	target.visual.look_at(Vector3.ZERO)
	game.arsenal.select(1); game.player.energy=100
	action("fire",true); await frames(1); action("fire",false)
	check(game.projectiles.any(func(s): return s.get("kind","")=="plasma"),"Plasma fires a traveling projectile through the actual trigger")
	await frames(20)
	check(target.health<120 and game.player.energy<100,"Plasma splash damages an armored target and consumes energy")
	clear_shots()
	# Shoot into the arrival wall: close geometry must block projectile spawning.
	game.player.position=Vector3(13.4,0,0); game.player.look_at(Vector3(20,0,0))
	var before=game.projectiles.size(); game.arsenal.fire_plasma()
	check(game.projectiles.size()==before,"Plasma cannot spawn through close walls")
	var behind=game.spawn_drone(Vector3(17,0,0),"bulwark"); behind.set_physics_process(false)
	game.arsenal.fire_rail(1)
	check(behind.health==150,"Rail damage cannot reach enemies through solid walls")
	game.player.position=Vector3.ZERO; game.player.rotation=Vector3.ZERO
	target.position=Vector3(0,0,-7); target.health=150
	var second=game.spawn_drone(Vector3(0,0,-11),"bulwark"); second.set_physics_process(false); second.visual.look_at(Vector3.ZERO)
	game.arsenal.select(2); game.player.energy=100; game.player.fire_timer=0
	action("fire",true); await frames(58)
	check(game.player.rail_charge>0.9 and target.health==150,"Railgun charges without firing while the trigger is held")
	action("fire",false); await frames(2)
	check(target.health<60 and second.health<90,"Released rail shot pierces two enemies and bypasses frontal armor")
	check(game.player.energy<80 and game.player.rail_charge==0,"Rail release spends charge-dependent energy and resets its charge")
	game.player.fire_timer=0; action("fire",true); await frames(10); game.arsenal.select(0); action("fire",false)
	check(game.player.rail_charge==0,"Switching weapons cancels a pending rail shot")
	game.campaign.data.upgrades.cannons=3; game.player.apply_upgrades(); game.arsenal.select(1)
	check(game.player.cannon_damage==30 and game.player.cannon_interval<0.135,"Amplifier upgrades retain pulse damage and fire-rate improvements")
	game.arsenal.fire_plasma()
	check(game.projectiles[-1].damage==76,"Amplifier upgrades also increase plasma damage")
	clear_shots()
	# AI decisions run in real geometry, with attack admission shared across a squad.
	target.position=Vector3(3,0,-8); second.position=Vector3(-3,0,-8)
	target.health=target.max_health; second.health=second.max_health
	target.cooldown=0; second.cooldown=0
	target.attack_state="charging"; second.attack_state="burst"
	var scout=game.spawn_drone(Vector3(0,0,-11),"scout"); scout.set_physics_process(false)
	check(not game.director.attack_allowed(scout),"Squads limit nearby simultaneous charging and bursting attackers")
	target.attack_state="idle"; second.attack_state="idle"
	scout.decide_target(0.15)
	check(scout.visible_target and scout.tactical_state=="flank","Scouts choose a lateral flanking position on visual contact")
	second.alert_time=0; game.director.alert_squad(scout)
	check(second.alert_time>0 and second.last_seen==game.player.position,"A visible squad member shares the player's last known position")
	scout.health=10; scout.decide_target(0.15)
	check(scout.tactical_state=="retreat" and scout.retreat_timer>0,"Damaged drones retreat toward cover instead of attacking continuously")
	scout.position=Vector3(0,0,-90); scout.home=scout.position; scout.retreat_timer=0; scout.alert_time=0
	scout.decide_target(0.15)
	check(scout.tactical_state=="patrol" and scout.move_target!=scout.home,"Unalerted enemies follow physical patrol waypoints")
	var h=game.director.hazards[0]
	game.player.position=h.position+Vector3(0,1.5,0); game.player.shield=100; game.player.set_physics_process(false)
	h.clock=2.2; h.damage_clock=0; h._physics_process(0.01)
	check(h.warning and not h.active and game.player.shield==100,"Hazards warn before their damaging active interval")
	h.clock=3.1; h._physics_process(0.01)
	check(h.active and game.player.shield<100,"Live coolant applies actual shield damage inside its field")
	h.hit(100)
	var shield=game.player.shield; h._physics_process(1)
	check(h.destroyed and h.collision_layer==0 and game.player.shield==shield,"Destroying a hazard cell disables both damage and weapon collision")
	var machine=game.director.hazards[2]
	var victim=game.spawn_drone(machine.position+Vector3(2,0,0),"striker"); victim.set_physics_process(false)
	game.player.position=Vector3.ZERO
	machine.hit(100)
	check(victim.dead,"Destroying volatile machinery can kill nearby enemies")
	game.mission_time=12; game.player.position=game.director.ambush_pos
	game.director.update(0.01)
	check(game.director.ambush_state=="warning","Crossing an encounter trigger announces a delayed ambush")
	var pending=game.director.snapshot(); game.director.restore(pending)
	check(game.director.beacons.size()==2 and game.director.ambush_timer>0,"Restoring a pending ambush also restores its visible arrival warning")
	var count=game.drones.size(); game.director.update(2.1)
	check(game.director.ambush_state=="complete" and game.drones.size()==count+2,"The telegraphed ambush spawns its response team once")
	game.director.update(3)
	check(game.drones.size()==count+2,"Returning to an ambush trigger cannot spawn duplicate teams")
	# Trials remain optional and do not lock the vault exit.
	game.secret_door.breach(); game.player.position=game.director.console_pos
	action("interact",true); game.director.update(2.1); action("interact",false)
	check(game.director.challenge_state=="active" and game.director.wave==1 and not game.secret_door.locked,"Holding interact starts a trial while leaving retreat open")
	for d in game.drones.duplicate():
		if d.spawn_id in game.director.wave_ids: d.hit(10000,Vector3.INF,true)
	game.director.update(2.1)
	check(game.director.wave==2,"Clearing the first trial wave starts the next wave")
	for d in game.drones.duplicate():
		if d.spawn_id in game.director.wave_ids: d.hit(10000,Vector3.INF,true)
	game.player.shield=50; game.player.energy=20; var ammo=game.player.missiles
	game.director.update(2.1)
	check(game.director.challenge_state=="cleared" and game.player.shield==75 and game.player.missiles==ammo+3,"Finishing a trial grants repair, energy and ammunition")
	var score=game.score; game.director.clear_challenge()
	check(game.score==score,"Trial rewards cannot be claimed twice")
	game.arsenal.select(2); game.player.position=Vector3.ZERO
	game.store_checkpoint(); var saved=game.campaign.data.checkpoint.duplicate(true)
	await fresh(0); game.campaign.data.checkpoint=saved
	check(game.restore_checkpoint(),"New encounter state restores alongside an ordinary mission checkpoint")
	check(game.director.challenge_state=="cleared" and game.director.ambush_state=="complete" and game.director.hazards[0].destroyed and game.player.primary_weapon==2,"Checkpoint preserves trial rewards, ambush completion, destroyed hazards and selected weapon")
	check(game.next_drone_id>game.drones.map(func(d): return d.spawn_id).max(),"Restored encounter enemies cannot reuse a live spawn identifier")
	var profile=game.campaign
	var reward=profile.complete(0,0,100,0,false,"trial-bonus",true)
	check(reward==1450,"A cleared optional trial adds 300 salvage on extraction")
	check(profile.complete(0,0,100,0,false,"trial-bonus",true)==0,"The challenge extraction bonus obeys the duplicate-run guard")
	await fresh(2)
	game.secret_door.breach(); game.player.set_physics_process(false); game.player.position=game.secret_center
	game.director.start_challenge()
	for d in game.drones.duplicate():
		if d.spawn_id in game.director.wave_ids: d.hit(10000,Vector3.INF,true)
	game.director.update(2.1)
	var wardens=game.drones.filter(func(d): return d.role=="warden")
	check(wardens.size()==1 and wardens[0].max_health==460,"Helios trial culminates in the armored Warden miniboss")
	game.arsenal.select(1); wardens[0].health=320
	game.store_checkpoint(); var active_trial=game.campaign.data.checkpoint.duplicate(true)
	await fresh(2); game.player.set_physics_process(false); game.campaign.data.checkpoint=active_trial
	check(game.restore_checkpoint(),"An active trial checkpoint restores successfully")
	wardens=game.drones.filter(func(d): return d.role=="warden")
	check(wardens.size()==1 and wardens[0].health==320 and wardens[0].spawn_id in game.director.wave_ids and game.director.wave==2,"Active trial restore keeps its exact Warden and wave identifiers without duplicating enemies")
	var warden=wardens[0]; warden.set_physics_process(false)
	warden.health=200; warden.decide_target(0.15)
	check(warden.enraged,"The Warden enters overdrive below half health")
	warden.attack_state="burst"; warden.shots_left=1; warden.attack_timer=0; clear_shots(); warden.update_attack(0.01,true)
	check(game.projectiles.size()==8,"Warden overdrive releases its distinct radial attack")
	game.reactor_down=true; game.director.update(0.1)
	check(game.director.console_label.text.contains("EVACUATE"),"Containment closes unfinished trials and directs the pilot to evacuate")
	print("COMBAT TEST COMPLETE: ",failures," failures")
	game.queue_free(); await process_frame; await process_frame
	await create_timer(0.2,true,false,true).timeout
	quit(1 if failures else 0)
