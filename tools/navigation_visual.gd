extends SceneTree
var game
var folder="res://exports/navigation-preview"
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func fresh(index: int) -> void:
	if is_instance_valid(game): game.queue_free(); await process_frame; await process_frame
	root.set_meta("mission_selection",index); game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await process_frame; game.launch(); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	for f in game.systems.foundries: f.set_physics_process(false)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false)
func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png"); print("NAVIGATION IMAGE: ",name)
func view(pos: Vector3,at: Vector3) -> void:
	game.player.position=pos; game.player.look_at(at); game.nav_hint=game.route_hint()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	await fresh(0); game.survey.update(1); game.toggle_map(); await capture("01-explored-map")
	game.survey.seen=range(game.map_rooms.size()); game.survey.seen_links=range(game.map_links.size()); game.survey.place_marker("pump"); game.survey.zoom=4.1
	await capture("02-3d-map"); game.survey.yaw=0.6; game.survey.pitch=0.38; await capture("03-map-rotation")
	game.toggle_map(); view(Vector3(7,44,-90),Vector3(20,44,-90)); await capture("04-security-lock")
	view(game.systems.key_pos+Vector3(0,0,4),game.systems.key_pos); await capture("05-blue-key")
	view(game.systems.switch_pos+Vector3(-1,0,4),game.systems.switch_pos); game.systems.update(0.1); await capture("06-local-override")
	var factory=game.systems.foundries[0]; view(factory.position+Vector3(-6,0,4),factory.position); factory.timer=1.2; factory._physics_process(0.01); await capture("07-foundry-online")
	factory.hit(1000); await capture("08-foundry-disabled")
	game.state="paused"; game.hud.show_saves(); game.manual_save(0); game.manual_save(1); await capture("09-manual-saves")
	game.hud.request_slot_save(0); await capture("10-save-confirmation")
	game.state="menu"; game.hud.save_message=""; game.hud.front_view="profiles"; game.hud.rebuild_menu(); await capture("11-pilot-profiles")
	game.kills=game.total_drones; game.exploration.crew_rescued=true; game.exploration.escort.status="delivered"; game.exploration.escort.integrity=160; game.escape_time=70
	for i in range(3): game.campaign.discover("logs","0_"+str(i))
	game.rating=game.Ratings.evaluate(game); game.state="won"; game.reward=3000; game.end_title="OPERATION COMPLETE"; game.hud.front_view="title"; game.hud.rebuild_menu(); await capture("12-medal-debrief")
	game.queue_free(); await process_frame; quit()
