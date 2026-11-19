extends SceneTree
var game
var failures=0
var report=[]
var chase="--chase-v09" in OS.get_cmdline_user_args()
func _initialize() -> void:
	root.set_meta("test_session",true)
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else: failures+=1; push_error(message)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func action(name: String,value: float) -> void:
	if value>0: Input.action_press("ship_"+name,value)
	else: Input.action_release("ship_"+name)
func fly(goal: Vector3) -> bool:
	for i in range(1800):
		if game.state=="won":
			action("forward",0); action("boost",0)
			return true
		if game.player.position.distance_to(goal)<1.4:
			action("forward",0); action("boost",0); action("brake",1)
			await frames(18); action("brake",0)
			return true
		var dir=(goal-game.player.position).normalized()
		game.player.look_at(goal,Vector3.UP if absf(dir.y)<0.98 else Vector3.FORWARD)
		action("forward",clampf(game.player.position.distance_to(goal)/9,0.12,1))
		action("boost",1 if game.player.position.distance_to(goal)>12 and game.player.boost>8 else 0)
		await physics_frame
	action("forward",0); action("boost",0)
	push_error("Route blocked at "+str(game.player.position)+" toward "+str(goal))
	return false
func traverse(goal: String) -> bool:
	var start="dock"
	var nearest=INF
	for node in game.nav_nodes:
		if node in ["secret","vault"]: continue
		var distance=game.player.position.distance_to(game.nav_nodes[node])
		if distance<nearest: nearest=distance; start=node
	var path=game.path_to(start,goal)
	if path.is_empty(): return false
	for node in path:
		if not await fly(game.nav_nodes[node]): return false
	return true
func aim_and_shoot(target: Dictionary) -> bool:
	for i in range(3600):
		if not target.alive: action("fire",0); action("missile",0); return true
		game.player.look_at(target.pos)
		var waiting=target.kind=="boss" and game.boss.warming>0
		action("fire",0 if waiting else 1)
		action("missile",1 if target.kind=="boss" and not waiting and game.player.missiles>0 else 0)
		for drone in game.drones:
			drone.set_physics_process(false)
			drone.collision_layer=0
		await physics_frame
	action("fire",0)
	return false
func run() -> void:
	for mission in range(3):
		root.set_meta("mission_selection",mission)
		game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
		await process_frame; await physics_frame
		game.launch()
		if chase: game.player.chase_enabled=true; game.player.update_view(0)
		# This scenario measures navigation and objective flow, not human combat skill.
		game.player.shield=99999
		for drone in game.drones:
			drone.set_physics_process(false); drone.collision_layer=0
		if is_instance_valid(game.boss): game.boss.set_physics_process(false)
		var start=game.mission_time
		for i in range(3):
			var reached=await traverse(game.nav_goals[i])
			check(reached,"Operation %d physical route to objective %d" % [mission+1,i+1])
			if not reached: break
			if mission==1:
				var goal=game.targets[i].pos+Vector3(0,0,3.5)
				check(await fly(goal),"Archive interaction position is reachable")
				action("interact",1); await frames(150); action("interact",0)
				check(not game.targets[i].alive,"Archive is recovered through the live interaction loop")
			else: check(await aim_and_shoot(game.targets[i]),"Pulse weapons destroy the reachable shield/relay objective")
		if game.relays_down==3:
			if mission==2:
				check(await traverse("access"),"Fortress return from crown reaches the approach")
				check(await fly(Vector3(10,3,-83)),"Boss combat position is reachable")
				game.boss.set_physics_process(true)
				check(await aim_and_shoot(game.targets[3]),"Real weapons complete all three boss phases")
			else:
				check(await traverse("core"),"Unlocked final objective is physically accessible")
				if mission==1:
					check(await fly(game.targets[3].pos+Vector3(0,0,3.5)),"Uplink interaction position is reachable")
					action("interact",1); await frames(210); action("interact",0)
					check(game.reactor_down,"Uplink upload initiates extraction")
				else: check(await aim_and_shoot(game.targets[3]),"Reactor destruction initiates extraction")
			var escape_start=game.escape_time
			check(await traverse("dock"),"Operation %d extraction route is physically traversable" % (mission+1))
			if game.state!="won": await fly(game.extraction)
			check(game.state=="won","Operation %d completes through its live extraction trigger" % (mission+1))
			report.append({"mission":mission+1,"scenario_seconds":game.mission_time-start,"escape_seconds":escape_start-game.escape_time,"escape_budget":game.mission_info().escape,"state":game.state,"upgraded":false,"combat_setup":"high test shields; ordinary enemies frozen and nonblocking","camera":"chase requested, automatic clearance fallback" if chase else "cockpit"})
		game.queue_free(); await process_frame; await process_frame
	var file=FileAccess.open("res://tests/campaign_routes_chase.json" if chase else "res://tests/campaign_routes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"scenarios":report},"	")); file.close()
	print("CAMPAIGN ROUTE TEST COMPLETE: ",failures," failures")
	quit(1 if failures else 0)
