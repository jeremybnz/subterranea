extends SceneTree
var game
var results=[]
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); Engine.time_scale=5; Engine.physics_ticks_per_second=120; call_deferred("run")
func action(name: String,value: float) -> void:
	if value>0: Input.action_press("ship_"+name,value)
	else: Input.action_release("ship_"+name)
func run_case(index: int,difficulty: int) -> void:
	root.set_meta("mission_selection",index)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; await physics_frame
	game.difficulty=difficulty; game.launch()
	var ex=game.exploration; var pod=ex.items.filter(func(i): return i.kind=="pod")[0]
	game.player.position=pod.pos+Vector3(0,1,3); ex.interact(pod)
	var seconds=0.0; var minimum=160.0; var repairs=0; var disabled_before=false
	while game.state=="playing" and seconds<75 and ex.escort.status!="delivered":
		seconds=game.mission_time; minimum=minf(minimum,ex.escort.integrity)
		var target=null; var best=INF
		for d in game.drones:
			if d.dead or not game.clear_line(game.player.position,d.position): continue
			var dist=game.player.position.distance_to(d.position)
			if dist<best: best=dist; target=d
		var to=ex.escort.position-game.player.position
		var at=target.position if target!=null else ex.escort.position
		if game.player.position.distance_to(at)>0.1:
			var dir=(at-game.player.position).normalized(); game.player.look_at(at,Vector3.UP if absf(dir.y)<0.98 else Vector3.RIGHT)
		action("fire",1 if target!=null else 0)
		action("missile",1 if target!=null and target.elite and game.player.missiles>0 else 0)
		var moving=to.normalized()*clampf((to.length()-3)/6,0,0.8)
		var local=game.player.global_basis.inverse()*moving
		for entry in [["right",local.x],["left",-local.x],["up",local.y],["down",-local.y],["reverse",local.z],["forward",-local.z]]: action(entry[0],maxf(0,entry[1]))
		var disabled=ex.escort.status=="disabled"
		if disabled and not disabled_before: repairs+=1
		disabled_before=disabled
		action("interact",1 if disabled and to.length()<4.2 else 0)
		await physics_frame
	for name in game.controls.DEFAULTS: action(name,0)
	var row={"mission":index+1,"difficulty":["Pilot","Standard","Ace"][difficulty],"seconds":snappedf(seconds,0.1),"ship_state":game.state,"ship_shield":snappedf(game.player.shield,0.1),"courier":ex.escort.status,"minimum_integrity":snappedf(minimum,0.1),"end_integrity":snappedf(ex.escort.integrity,0.1),"disable_events":repairs,"kills":game.kills,"missiles_left":game.player.missiles,"stats":game.combat_stats.duplicate(true)}
	results.append(row); print("RESCUE BALANCE ",JSON.stringify(row))
	game.queue_free(); await process_frame; await process_frame
func run() -> void:
	for index in range(3): await run_case(index,1)
	await run_case(0,0); await run_case(0,2)
	var file=FileAccess.open("res://tests/rescue_balance.json",FileAccess.WRITE); file.store_string(JSON.stringify({"setup":"normal shields, no upgrades, all enemy AI active, scripted pilot begins at refuge pod and escorts with pulse and missiles","time_scale":5,"physics_ticks":120,"results":results},"\t")); file.close()
	print("RESCUE BALANCE COMPLETE"); quit()
