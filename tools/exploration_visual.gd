extends SceneTree
var game
var folder="res://exports/exploration-preview"
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func fresh(index: int) -> void:
	if is_instance_valid(game): game.queue_free(); await process_frame; await process_frame
	root.set_meta("mission_selection",index); game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await process_frame; game.launch(); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false)
func view(pos: Vector3,at: Vector3) -> void:
	game.player.position=pos; game.player.look_at(at); game.nav_hint=game.route_hint()
func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png"); print("EXPLORATION IMAGE: ",name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for index in range(3):
		await fresh(index)
		var origin=[Vector3(0,44,-103),Vector3(52,0,-64),Vector3(0,0,-127)][index]
		view(origin+Vector3(0,-0.5,4),origin+Vector3(0,0,-30)); game.exploration.queue_radio("arrival",true)
		await capture(["01-nereid-drill","02-boreas-ice-face","03-helios-fusion"][index])
	await fresh(0)
	var pod=game.exploration.items.filter(func(i): return i.kind=="pod")[0]
	view(pod.pos+Vector3(1,0,5),pod.pos); game.exploration.tick=0; game.exploration.update(0.1)
	await capture("04-crew-refuge")
	game.exploration.interact(pod); game.exploration.escort.set_physics_process(false)
	view(pod.pos+Vector3(2,1,6),game.exploration.escort.position)
	await capture("05-rescue-courier")
	for index in range(3): game.campaign.discover("logs","0_"+str(index))
	game.state="paused"; game.hud.show_journal(); await capture("06-journal")
	game.hud.journal_radio=true; game.hud.rebuild_menu(); await capture("07-radio-transcripts")
	game.campaign.discover("caches","0_cache",200,"ember"); game.exploration.select_paint("ember")
	game.state="menu"; game.player.cockpit.hide(); game.menu_ship.show(); game.hud.front_view="livery"; game.hud.rebuild_menu(); await capture("08-ember-livery")
	await fresh(0)
	view(Vector3(0,1,-35),Vector3(0,1,-48)); game.arsenal.select(2)
	game.player.set_physics_process(true); Input.action_press("ship_fire")
	for i in range(55): await physics_frame
	await capture("09-charged-rail-mechanism")
	Input.action_release("ship_fire"); await physics_frame; game.player.set_physics_process(false)
	game.fire_missile()
	for i in range(10): await process_frame
	game.explosion(Vector3(2,1,-45),Color("ffae70"),1.4)
	await capture("10-impact-and-missile-trail")
	game.queue_free(); await process_frame; quit()
