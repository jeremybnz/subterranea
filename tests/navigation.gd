extends SceneTree
const Campaign=preload("res://scripts/campaign.gd")
const Profiles=preload("res://scripts/profiles.gd")
var game
var failures=0
var routes=[]
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); Engine.time_scale=4; Engine.physics_ticks_per_second=120; call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures+=1; push_error(label)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func action(name: String,on: bool,strength: float = 1) -> void:
	if on: Input.action_press("ship_"+name,strength)
	else: Input.action_release("ship_"+name)
func fresh(index: int) -> void:
	if is_instance_valid(game): game.queue_free(); await process_frame; await process_frame
	root.set_meta("mission_selection",index); game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; await physics_frame; game.launch()
	game.campaign.data.unlocked=2; game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	for f in game.systems.foundries: f.set_physics_process(false)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false)
func passable(a: Vector3,b: Vector3) -> bool:
	var q=PhysicsShapeQueryParameters3D.new(); var shape=SphereShape3D.new(); shape.radius=0.65; q.shape=shape; q.transform=Transform3D(Basis.IDENTITY,a); q.motion=b-a; q.collision_mask=1
	return game.get_world_3d().direct_space_state.cast_motion(q)[0]>0.99
func fly(goal: Vector3) -> bool:
	for i in range(1800):
		for d in game.drones: d.set_physics_process(false)
		var distance=game.player.position.distance_to(goal)
		if distance<1.3:
			action("forward",false); action("brake",true); await frames(12); action("brake",false); return true
		var dir=(goal-game.player.position).normalized(); game.player.look_at(goal,Vector3.UP if absf(dir.y)<0.98 else Vector3.RIGHT)
		action("forward",true,clampf(distance/8,0.1,1))
		await physics_frame
	action("forward",false); push_error("Shortcut blocked at "+str(game.player.position)+" goal "+str(goal)); return false
func mouse(button: MouseButton,pressed: bool,at: Vector2) -> void:
	var e=InputEventMouseButton.new(); e.button_index=button; e.pressed=pressed; e.position=at; game._input(e)
func run() -> void:
	await fresh(0)
	var survey=game.survey; game.player.position=Vector3.ZERO; survey.update(1)
	check(survey.seen.size()>0 and survey.seen.size()<game.map_rooms.size(),"Automap initially reveals only the entered room")
	game.player.position=Vector3(0,24,-44); survey.update(1)
	check(survey.seen_links.size()>0,"Survey discovers and remembers a traversed vertical shaft")
	survey.seen=range(game.map_rooms.size()); survey.seen_links=range(game.map_links.size())
	game.player.position=game.nav_nodes.nexus; game.player.velocity=Vector3(2,0,-4); game.player.set_physics_process(true)
	var pilot=game.player.position; var clock=game.mission_time; var enemy=game.drones[0]; enemy.set_physics_process(true); enemy.cooldown=3
	game.toggle_map(); await frames(10)
	check(game.player.position==pilot and game.mission_time==clock and enemy.cooldown==3,"Inspecting the automap freezes ship movement, mission time and enemy attacks")
	var yaw=survey.yaw; var orientation=game.player.basis
	mouse(MOUSE_BUTTON_LEFT,true,Vector2(600,400)); var motion=InputEventMouseMotion.new(); motion.relative=Vector2(45,20); game._input(motion); mouse(MOUSE_BUTTON_LEFT,false,Vector2(645,420))
	check(survey.yaw!=yaw and game.player.basis.is_equal_approx(orientation),"Mouse dragging rotates the 3D map without steering the ship")
	var zoom=survey.zoom; mouse(MOUSE_BUTTON_WHEEL_UP,true,Vector2(600,400)); check(survey.zoom>zoom,"Mouse wheel zooms the automap")
	var e=InputEventKey.new(); e.keycode=KEY_1; e.pressed=true; game._input(e); check(not survey.objectives,"Map filters respond to keyboard input without switching weapons")
	check(survey.place_marker("pump") and game.route_hint().name.begins_with("PIN /"),"A surveyed map marker drives accessible in-flight route guidance")
	game.reactor_down=true; check(not game.route_hint().name.begins_with("PIN /"),"Extraction guidance takes priority over optional map pins")
	game.reactor_down=false; var data=survey.snapshot(); survey.seen.clear(); survey.pin=""; survey.restore(data)
	check(survey.pin=="pump" and survey.seen.size()==game.map_rooms.size(),"Survey coverage, view and marker survive a checkpoint round trip")
	game.toggle_map(); game.player.set_physics_process(false)
	for index in range(3):
		await fresh(index)
		var system=game.systems; var edge=system.gate_edge
		var path=game.path_to(edge[0],edge[1]); check(system.gate.locked and path.size()!=2,"Operation %d service route starts locked in the navigation graph" % (index+1))
		var crossing=[[Vector3(11,44,-90),Vector3(18,44,-90)],[Vector3(0,29,-96),Vector3(0,23,-96)],[Vector3(-36,0,-100),Vector3(-28,0,-100)]][index]
		check(not passable(crossing[0],crossing[1]),"Operation %d security gate physically blocks a ship before unlocking" % (index+1))
		game.player.position=system.key_pos; system.update(0.1)
		check(system.has_key and not system.key_node.visible and not system.gate.locked,"Operation %d colored key pickup unlocks its own service gate" % (index+1))
		game.player.position=crossing[0]; await frames(35)
		check(passable(crossing[0],crossing[1]),"Operation %d unlocked gate opens its actual collision" % (index+1))
		check(game.path_to(edge[0],edge[1]).size()==2,"Operation %d unlocked shortcut becomes a direct graph connection" % (index+1))
		game.player.set_physics_process(true); game.player.velocity=Vector3.ZERO; game.player.shield=10000
		var start=game.mission_time
		if index==0:
			game.player.position=game.nav_nodes.upper
			check(await fly(game.nav_nodes.transfer) and await fly(game.nav_nodes.pump),"Ship flies the upper-relay to pump-hall security shortcut and shaft")
		elif index==1:
			game.player.position=game.nav_nodes.archive
			check(await fly(game.nav_nodes.transfer) and await fly(game.nav_nodes.core),"Ship descends through the archive service gate into the uplink chamber")
		else:
			game.secret_door.breach(); game.player.position=game.nav_nodes.vault
			check(await fly(game.nav_nodes.service) and await fly(game.nav_nodes.core),"Ship traverses the reserve-to-Overseer service bypass")
		routes.append({"mission":index+1,"seconds":game.mission_time-start,"key":system.key_name})
		game.player.set_physics_process(false)
		check(game.relays_down==0 and not game.reactor_down,"Optional shortcut access does not complete or bypass mandatory mission objectives")
		var saved=system.snapshot(); system.has_key=false; system.restore(saved); check(system.has_key and not system.gate.locked,"Security keys and gate state survive restoration")
		# The override is an alternate way to open the same gate, independent of the key.
		await fresh(index); system=game.systems; game.player.position=system.switch_pos; action("interact",true); await frames(55); action("interact",false)
		check(system.overridden and not system.has_key and not system.gate.locked,"Operation %d local switch opens its service gate without collecting the key" % (index+1))
		var factory=system.foundries[0]; game.player.position=factory.position+Vector3(0,0,-4)
		factory.timer=0.01; factory._physics_process(0.02)
		check(factory.produced==1 and factory.ids.size()==1,"Operation %d foundry creates a live reinforcement" % (index+1))
		for i in range(4): factory.timer=0.01; factory._physics_process(0.02)
		var alive=game.drones.filter(func(d): return d.spawn_id in factory.ids)
		check(alive.size()==3,"Foundry production never exceeds three living reinforcements")
		alive[0].hit(1000,Vector3.INF,true); factory.timer=0.01; factory._physics_process(0.02)
		check(factory.produced==4,"Foundry resumes production after a reinforcement is destroyed")
		var fstate=factory.snapshot(); factory.hit(10000); var score=game.score; factory.hit(10000); factory._physics_process(10)
		check(factory.destroyed and factory.collision_layer==0 and game.score==score,"Destroyed foundries stop production and cannot award duplicate shutdown score")
		game.store_checkpoint(); check(game.campaign.data.checkpoint.systems.foundries[0].destroyed,"A checkpoint preserves a shut-down foundry")
	# Medal thresholds and record retention are exercised with distinct run outcomes.
	await fresh(0); game.kills=game.total_drones; game.survey.seen=range(game.map_rooms.size())
	for i in range(3): game.campaign.discover("logs","0_"+str(i))
	game.exploration.crew_rescued=true; game.exploration.escort.status="delivered"; game.exploration.escort.integrity=160; game.escape_time=70
	var rating=game.Ratings.evaluate(game)
	check(rating.rank=="S" and rating.points==12,"Full combat, survey, rescue and escape performance earns four gold medals and S rank")
	game.exploration.escort.integrity=60; check(game.Ratings.evaluate(game).medals.rescue==2,"Courier integrity distinguishes silver from gold rescue performance")
	game.exploration.escort.status="waiting"; check(game.Ratings.evaluate(game).medals.rescue==1,"Secured crew without a courier delivery earns bronze rescue credit")
	game.campaign.complete(0,1000,100,10,true,"medal-run",true,true,true,rating)
	game.campaign.complete(0,500,200,1,false,"lesser-run",false,false,false,{"medals":{"combat":0,"exploration":0,"rescue":0,"escape":1},"points":1,"rank":"D"})
	check(game.campaign.data.records[0].rank=="S" and game.campaign.data.records[0].medals.combat==3,"Lower-rated replays preserve best medals and highest overall rank")
	var file=FileAccess.open("res://tests/navigation_routes.json",FileAccess.WRITE); file.store_string(JSON.stringify({"failures":failures,"routes":routes},"\t")); file.close()
	game.queue_free(); await process_frame; await process_frame
	await create_timer(0.15,true,false,true).timeout
	print("NAVIGATION TEST COMPLETE: ",failures," failures"); quit(1 if failures else 0)
