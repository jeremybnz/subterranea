extends SceneTree
var game
var folder="res://exports/combat-preview"
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true)
	call_deferred("run")
func fresh(mission: int) -> void:
	if is_instance_valid(game): game.queue_free(); await process_frame; await process_frame
	root.set_meta("mission_selection",mission)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await process_frame; game.launch(); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false)
func view(pos: Vector3,at: Vector3) -> void:
	game.player.position=pos; game.player.look_at(at); game.nav_hint=game.route_hint()
func capture(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")
	print("COMBAT IMAGE: ",name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	await fresh(0)
	view(Vector3(0,2,-31),Vector3(0,0,-50)); game.arsenal.select(1)
	game.arsenal.fire_plasma()
	for i in range(10): await process_frame
	await capture("01-plasma")
	game.arsenal.select(2); game.arsenal.fire_rail(1)
	await capture("02-rail")
	var h=game.director.hazards[0]; h.clock=3.2; h._physics_process(0.01); h.set_physics_process(false)
	view(Vector3(43,1,-34),h.position); game.arsenal.select(1)
	await capture("03-coolant-hazard")
	await fresh(2); game.secret_door.breach(); game.player.position=game.secret_center
	game.director.start_challenge()
	for d in game.drones.duplicate():
		if d.spawn_id in game.director.wave_ids: d.hit(10000,Vector3.INF,true)
	game.director.update(2.1)
	var warden=game.drones.filter(func(d): return d.role=="warden")[0]
	warden.set_physics_process(false); warden.visual.look_at(game.secret_center+Vector3(3,0,-6))
	view(game.secret_center+Vector3(3,0,-6),warden.position); game.arsenal.select(2)
	await create_timer(1.1).timeout
	game.kill_confirm=0; game.notice_time=0
	await capture("04-warden")
	warden.health=210; warden.decide_target(0.15); warden.attack_state="burst"; warden.attack_timer=0; warden.shots_left=1; warden.update_attack(0.01,true)
	await capture("05-warden-overdrive")
	game.state="paused"; game.hud.settings_open=true; game.hud.settings_tab="controls"; game.hud.binding_device="controller"; game.hud.rebuild_menu()
	await capture("06-expanded-controller-bindings")
	game.queue_free(); await process_frame; quit()
