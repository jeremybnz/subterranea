extends SceneTree
var game
var rows=[]
var failures=0
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); Engine.time_scale=3; Engine.physics_ticks_per_second=180; call_deferred("run")
func action(name: String,value: float) -> void:
	if value>0: Input.action_press("ship_"+name,value)
	else: Input.action_release("ship_"+name)
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures+=1; push_error(label)
func run_case(chase: bool,weapon: int) -> void:
	seed(9100); root.set_meta("mission_selection",0)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; await physics_frame
	game.launch(); game.difficulty=1; game.arsenal.select(weapon); game.player.chase_enabled=chase; game.player.position=game.nav_nodes.nexus+Vector3(0,0,4); game.player.update_view(0)
	seed(9100)
	for d in game.drones:
		var rng=RandomNumberGenerator.new(); rng.seed=9100+d.spawn_id; d.clock=rng.randf()*TAU; d.cooldown=rng.randf_range(1.1,2.4)
	var sample=0; var penetrations=0; var camera_samples=0; var external_frames=0; var fallback_frames=0; var max_pieces=0; var minimum=100.0; var release=0
	while game.state=="playing" and game.mission_time<24:
		var seconds=game.mission_time; minimum=minf(minimum,game.player.shield)
		var target=null; var closest=INF
		for d in game.drones:
			if d.dead or not game.clear_line(game.player.position,d.position): continue
			var distance=game.player.position.distance_to(d.position)
			if distance<closest: closest=distance; target=d
		if target!=null:
			var at=target.position
			if weapon==1: at+=target.velocity*minf(closest/42,0.65)
			for i in range(2):
				var offset=game.player.global_basis.y*game.player.camera.position.y if chase and not game.player.chase_obstructed else Vector3.ZERO
				var direction=(at-offset-game.player.position).normalized(); game.player.look_at(at-offset,Vector3.UP if absf(direction.y)<0.97 else Vector3.RIGHT)
			if weapon==2:
				if game.player.rail_charge>=0.95: release=2
				action("fire",1 if release==0 and seconds>2 else 0); release=maxi(0,release-1)
			else: action("fire",1 if seconds>2 else 0)
		else: action("fire",0)
		var center=game.nav_nodes.nexus; var goal=center+Vector3(sin(seconds*0.6)*5,sin(seconds*0.75)*2,cos(seconds*0.6)*5)
		for pickup in game.pickups:
			if pickup.pos.distance_to(center)<12 and ((pickup.kind=="shield" and game.player.shield<60) or (pickup.kind=="energy" and game.player.energy<35)): goal=pickup.pos; break
		var local=game.player.global_basis.inverse()*(goal-game.player.position).limit_length()*0.65
		for entry in [["right",local.x],["left",-local.x],["up",local.y],["down",-local.y],["reverse",local.z],["forward",-local.z]]: action(entry[0],maxf(0,entry[1]))
		if chase:
			if game.player.chase_obstructed: fallback_frames+=1
			else: external_frames+=1
		if sample%6==0:
			var q=PhysicsShapeQueryParameters3D.new(); var shape=SphereShape3D.new(); shape.radius=0.24; q.shape=shape; q.collision_mask=1; q.transform=Transform3D(Basis.IDENTITY,game.player.camera.global_position)
			if not game.get_world_3d().direct_space_state.intersect_shape(q).is_empty(): penetrations+=1
			camera_samples+=1
		max_pieces=maxi(max_pieces,game.effects.filter(func(e): return e.get("kind","")=="hull_debris").size())
		sample+=1; await physics_frame
	for name in game.controls.DEFAULTS: action(name,0)
	var row={"view":"chase" if chase else "cockpit","weapon":game.arsenal.NAMES[weapon],"seconds":snappedf(game.mission_time,0.1),"state":game.state,"shield":snappedf(game.player.shield,0.1),"minimum_shield":snappedf(minimum,0.1),"kills":game.kills,"camera_samples":camera_samples,"camera_penetrations":penetrations,"external_frames":external_frames,"fallback_frames":fallback_frames,"max_hull_fragments":max_pieces,"stats":game.combat_stats.duplicate(true)}
	rows.append(row); print("LIVE COMBAT ",JSON.stringify(row))
	check(game.combat_stats.shots[["pulse","plasma","rail"][weapon]]>0 and game.combat_stats.enemy_shots>0,"Both sides fire real weapons with "+row.view+" / "+row.weapon)
	check(game.kills>0,"The scripted pilot can destroy active enemies with "+row.view+" / "+row.weapon)
	check(penetrations==0 and max_pieces<=48,"Camera clearance and fragment limits hold during "+row.view+" / "+row.weapon)
	if chase: check(external_frames>0,"The active-fight scenario actually uses the external camera")
	game.queue_free(); await process_frame; await process_frame
func run() -> void:
	for weapon in range(3):
		await run_case(false,weapon); await run_case(true,weapon)
	var file=FileAccess.open("res://tests/chase_combat.json",FileAccess.WRITE); file.store_string(JSON.stringify({"setup":"Standard difficulty, normal shields, no upgrades, all enemy AI active; scripted orbit and aiming; first two simulation seconds do not fire; shots and camera checks use actual physics","time_scale":3,"physics_ticks":180,"failures":failures,"results":rows},"\t")); file.close()
	await create_timer(0.2,true,false,true).timeout
	print("LIVE COMBAT COMPLETE: ",failures," failures"); quit(1 if failures else 0)
