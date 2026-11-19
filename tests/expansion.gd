extends SceneTree
var failures=0
var game
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else:
		failures+=1
		push_error(message)
func _initialize() -> void:
	root.set_meta("test_session",true)
	call_deferred("run")
func passable(a: Vector3,b: Vector3) -> bool:
	var query=PhysicsShapeQueryParameters3D.new()
	var sphere=SphereShape3D.new()
	sphere.radius=0.7
	query.shape=sphere
	query.transform=Transform3D(Basis.IDENTITY,a)
	query.motion=b-a
	query.collision_mask=1
	var result=game.get_world_3d().direct_space_state.cast_motion(query)
	return result[0]>0.99
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game.launch()
	for drone in game.drones: drone.set_physics_process(false)
	game.player.set_physics_process(false)
	check(game.map_rooms.size()==20 and game.map_links.size()==3,"Mine contains twenty room sections and three vertical shafts including the optional service route")
	check(passable(Vector3(0,0,-44),Vector3(0,44,-44)),"Ship-sized clearance through nexus ceiling and turbine shaft")
	check(passable(Vector3(-43,0,-44),Vector3(-43,-43,-44)),"Ship-sized clearance through foundry floor and descent shaft")
	check(passable(Vector3(0,44,-44),Vector3(0,44,-53)),"Upper deck approaches its moving door without obstruction")
	check(not passable(Vector3(0,0,-70),Vector3(0,0,-82)),"Reactor front entrance is physically locked")
	check(not passable(Vector3(24,0,-91),Vector3(12,0,-91)),"Reactor loop entrance cannot bypass the relay lock")
	var transit=game.doors[2]
	game.player.position=Vector3(43,0,-52)
	await frames(55)
	check(transit.openness>0.99 and passable(Vector3(43,0,-52),Vector3(43,0,-83)),"Proximity door opens with matching collision and admits the ship to pump hall")
	game.player.position=Vector3.ZERO
	await frames(55)
	check(transit.openness<0.01,"Transit door closes after the safety zone clears")
	game.player.position=Vector3(43,0,-58)
	await frames(55)
	check(transit.openness>0.99,"Door stays open while the ship occupies its safety zone")
	game.player.position=Vector3.ZERO
	check(game.secret_door.locked and not game.secret_found,"Supply vault starts hidden and locked")
	game.damage_object(game.secret_door.panels[0].node,18)
	await frames(55)
	check(game.secret_door.revealed and passable(Vector3(-54,-43,-44),Vector3(-83,-43,-44)),"Shooting fractured plating opens the concealed supply route")
	game.player.shield=30
	game.player.position=Vector3(-83,-43,-44)
	var before=game.score
	await process_frame
	await process_frame
	check(game.secret_found and game.player.shield==100 and game.score==before+1000,"Secret vault awards full repairs and one discovery bonus")
	var rewarded=game.score
	await process_frame
	await process_frame
	check(game.score==rewarded,"Secret reward cannot be collected twice")
	game.player.position=Vector3(0,0,14)
	game.player.rotation=Vector3(0,PI,0)
	game.player.camera.rotation=Vector3.ZERO
	await physics_frame
	var projectile_count=game.projectiles.size()
	game.fire_missile()
	check(game.projectiles.size()==projectile_count,"Missiles detonate at close walls instead of spawning through them")
	game.player.rotation=Vector3.ZERO
	var roles={}
	for drone in game.drones: roles[drone.role]=true
	check(roles.size()==3,"Scout, striker, and bulwark enemy roles are present")
	var heavy
	for drone in game.drones:
		if drone.role=="bulwark": heavy=drone; break
	game.player.position=Vector3.ZERO
	heavy.position=Vector3(0,0,-8)
	heavy.visual.look_at(game.player.position)
	var hp=heavy.health
	heavy.hit(18,Vector3.ZERO)
	check(is_equal_approx(hp-heavy.health,8.1),"Bulwark front armor reduces pulse damage")
	hp=heavy.health
	heavy.hit(18,Vector3(0,0,-16))
	check(is_equal_approx(hp-heavy.health,18),"Flanking bypasses bulwark front armor")
	hp=heavy.health
	heavy.hit(110,Vector3.ZERO,true)
	check(is_equal_approx(hp-heavy.health,110),"Explosive missiles bypass front armor")
	heavy.hit(100,Vector3.ZERO,true)
	var kills=game.kills
	heavy.hit(100,Vector3.ZERO,true)
	check(game.kills==kills,"Destroyed enemies cannot award duplicate kills")
	await physics_frame
	game.player.shield=100
	game.enemy_shot(Vector3(4,0,0),Vector3.LEFT,22,9)
	await frames(15)
	check(game.player.shield==91 and game.player.damage_direction.x>0.9,"Enemy projectiles apply real damage with source direction")
	game.player.position=Vector3(0,0,-44)
	var hint=game.route_hint()
	check(hint.pos==Vector3(-43,0,-44),"Navigation routes into the foundry branch before descending")
	game.player.position=Vector3(-43,-20,-44)
	hint=game.route_hint()
	check(hint.pos.y < -32,"Vertical guide continues all the way to the lower deck")
	game.targets[0].alive=false
	game.targets[1].alive=false
	game.player.position=Vector3(0,20,-44)
	hint=game.route_hint()
	check(hint.pos.y>34,"Vertical guide continues all the way to the upper deck")
	game.targets[0].alive=true
	game.targets[1].alive=true
	var scout=game.drones[0]
	scout.position=Vector3(0,0,-12)
	scout.home=scout.position
	scout.cooldown=0
	game.player.position=Vector3.ZERO
	scout.set_physics_process(true)
	await frames(10)
	check(scout.attack_state=="charging" and scout.charge>0,"Enemy attacks visibly telegraph before firing")
	var shots=game.projectiles.size()
	await frames(42)
	check(game.projectiles.size()>shots or game.player.shield<91,"Telegraphed enemy attack releases a projectile")
	scout.set_physics_process(false)
	for i in range(3): game.damage_object(game.targets[i].node,100)
	game.player.position=Vector3(23,0,-91)
	await frames(55)
	check(passable(Vector3(24,0,-91),Vector3(12,0,-91)),"Relay completion opens the second reactor route physically")
	game.reactor_down=true
	game.player.position=Vector3(43,0,-91)
	hint=game.route_hint()
	check(hint.pos==Vector3(43,0,-44),"Escape navigation uses the pump hall loop")
	check(game.sound.music.stream.stereo and game.sound.percussion.stream.loop_mode!=0,"Score contains looping stereo music and a separate combat rhythm layer")
	var effect_audio=game.sound.play_at("hit",Vector3.ZERO)
	check(effect_audio is AudioStreamPlayer3D and effect_audio.playing,"Combat effects use playing positional audio sources")
	game.state="playing"
	game.reactor_down=true
	game.escape_time=0.001
	game.player.position=Vector3(0,0,-85)
	await process_frame
	await process_frame
	check(game.state=="lost","Containment timeout ends the mission when extraction is missed")
	print("EXPANSION TEST COMPLETE: ",failures," failures")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
