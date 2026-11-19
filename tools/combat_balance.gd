extends SceneTree
var game
var results=[]
var failures=0
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true)
	Engine.time_scale=6; Engine.physics_ticks_per_second=120
	call_deferred("run")
func action(name: String,value: float) -> void:
	if value>0: Input.action_press("ship_"+name,value)
	else: Input.action_release("ship_"+name)
func run_case(mission: int,weapon: int,difficulty: int,trial: bool = false,passive: bool = false) -> void:
	root.set_meta("mission_selection",mission)
	seed(5100+mission)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await process_frame; await physics_frame
	seed(5100+mission)
	game.difficulty=difficulty; game.launch(); game.arsenal.select(weapon)
	var center=game.nav_nodes.nexus
	if trial:
		game.secret_door.breach(); center=game.secret_center
		game.player.position=center+Vector3(0,0,-3)
		game.director.start_challenge()
	else: game.player.position=center+Vector3(0,0,4)
	var energy_sum=0.0; var samples=0; var dry_frames=0
	var seconds=0.0; var charge_release=0
	var seeded_enemies={}
	while game.state=="playing" and seconds<50:
		seconds=game.mission_time
		var target=null; var best=INF
		for enemy in game.drones:
			if not seeded_enemies.has(enemy.spawn_id):
				var rng=RandomNumberGenerator.new(); rng.seed=5100+mission*100+enemy.spawn_id
				enemy.clock=rng.randf()*TAU; enemy.cooldown=rng.randf_range(1.1,2.4); seeded_enemies[enemy.spawn_id]=true
			if enemy.dead or not game.clear_line(game.player.position,enemy.position): continue
			var distance=game.player.position.distance_to(enemy.position)
			if distance<best: best=distance; target=enemy
		if target!=null and not passive:
			var at=target.position
			if weapon==1: at+=target.velocity*minf(best/42,0.7)
			var dir=(at-game.player.position).normalized()
			game.player.look_at(at,Vector3.UP if absf(dir.y)<0.97 else Vector3.RIGHT)
			if weapon==2:
				if game.player.rail_charge>=0.95: charge_release=2
				action("fire",0 if charge_release>0 else 1)
				charge_release=maxi(0,charge_release-1)
			else: action("fire",1)
		else:
			game.player.rail_charge=0; action("fire",0)
		var goal=center+Vector3(sin(seconds*0.42)*6,sin(seconds*0.7)*2.5,cos(seconds*0.42)*6)
		# Collect real nearby supplies when useful; pickups retain their normal radius.
		for pickup in game.pickups:
			if pickup.pos.distance_to(center)<13 and ((pickup.kind=="shield" and game.player.shield<70) or (pickup.kind=="energy" and game.player.energy<35)):
				goal=pickup.pos; break
		var local=Vector3.ZERO if passive else game.player.global_basis.inverse()*(goal-game.player.position).limit_length()*0.75
		for entry in [["right",local.x],["left",-local.x],["up",local.y],["down",-local.y],["reverse",local.z],["forward",-local.z]]: action(entry[0],maxf(0,entry[1]))
		energy_sum+=game.player.energy; samples+=1
		if game.player.energy<9: dry_frames+=1
		if trial and game.director.challenge_state=="cleared": break
		await physics_frame
	for name in game.controls.DEFAULTS: action(name,0)
	var result={"mission":mission+1,"weapon":["pulse","plasma","rail"][weapon],"difficulty":["Pilot","Standard","Ace"][difficulty],"scenario":"Stationary control" if passive else ("Helios vault trial" if trial else "Nereid nexus"),"missiles_left":game.player.missiles,"seconds":snappedf(seconds,0.1),"state":game.state,"kills":game.kills,"shield_left":snappedf(game.player.shield,0.1),"mean_energy":snappedf(energy_sum/maxi(1,samples),0.1),"dry_percent":snappedf(100.0*dry_frames/maxi(1,samples),0.1),"trial":game.director.challenge_state,"stats":game.combat_stats.duplicate(true)}
	results.append(result)
	print("BALANCE ",JSON.stringify(result))
	if passive:
		if result.stats.damage_taken<=0: failures+=1
	elif result.stats.shots[result.weapon]==0 or result.stats.damage_dealt<=0: failures+=1
	game.queue_free(); await process_frame; await process_frame
func run() -> void:
	for difficulty in range(3):
		for weapon in range(3): await run_case(0,weapon,difficulty)
	for weapon in range(3): await run_case(2,weapon,1,true)
	for difficulty in range(3): await run_case(0,0,difficulty,false,true)
	var file=FileAccess.open("res://tests/combat_balance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed":5100,"normal_shields":true,"upgrades":0,"enemy_ai":"active","time_scale":6,"physics_ticks":120,"failures":failures,"results":results},"\t")); file.close()
	print("BALANCE COMPLETE: ",failures," invalid scenarios")
	quit(1 if failures else 0)
