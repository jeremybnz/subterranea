extends SceneTree
var game
var rows=[]
var failures=0
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); Engine.time_scale=4; Engine.physics_ticks_per_second=120; call_deferred("run")
func run() -> void:
	for mission in range(3):
		root.set_meta("mission_selection",mission); game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; game.launch()
		var foundry=game.systems.foundries[0]; game.player.position=foundry.position+Vector3(0,0,4)
		var shutdown=0.0; var produced_at_shutdown=0
		while game.state=="playing" and game.mission_time<35:
			var target=null; var best=INF
			for d in game.drones:
				if not d.dead and game.clear_line(game.player.position,d.position) and game.player.position.distance_to(d.position)<best:
					target=d; best=game.player.position.distance_to(d.position)
			if foundry.produced>=2 and not foundry.destroyed: target=foundry
			if target!=null:
				var dir=(target.position-game.player.position).normalized(); game.player.look_at(target.position,Vector3.UP if absf(dir.y)<0.98 else Vector3.RIGHT)
				Input.action_press("ship_fire")
			else: Input.action_release("ship_fire")
			if foundry.destroyed and shutdown==0: shutdown=game.mission_time; produced_at_shutdown=foundry.produced
			if shutdown>0 and game.mission_time-shutdown>9: break
			await physics_frame
		Input.action_release("ship_fire")
		var ok=game.state=="playing" and foundry.destroyed and foundry.produced>=2 and foundry.produced==produced_at_shutdown
		if not ok: failures+=1; push_error("Active foundry scenario failed on mission "+str(mission+1))
		var row={"mission":mission+1,"ok":ok,"seconds":snappedf(game.mission_time,0.1),"shutdown_seconds":snappedf(shutdown,0.1),"produced":foundry.produced,"kills":game.kills,"shield":snappedf(game.player.shield,0.1),"stats":game.combat_stats.duplicate(true)}
		rows.append(row); print("FOUNDRY BALANCE ",JSON.stringify(row))
		game.queue_free(); await process_frame; await process_frame
	var file=FileAccess.open("res://tests/foundry_balance.json",FileAccess.WRITE); file.store_string(JSON.stringify({"setup":"Standard difficulty, normal shields, no upgrades, all enemy AI active; stationary scripted pulse pilot; observe two production cycles, shoot foundry, then observe nine seconds","results":rows},"\t")); file.close()
	await create_timer(0.15,true,false,true).timeout
	print("FOUNDRY BALANCE COMPLETE: ",failures," failures"); quit(1 if failures else 0)
