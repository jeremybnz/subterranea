extends SceneTree
var game
var folder="res://exports/flight-preview"
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func frame(name: String) -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png"); print("FLIGHT IMAGE: ",name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; game.launch()
	game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	game.player.position=Vector3(0,1,-43); game.player.rotation=Vector3.ZERO; game.player.toggle_view(); game.notice_time=0
	await frame("01-chase-view")
	game.player.thrust_level=1; game.player.boosting=true
	for i in range(15): game.player.flight_state.update_state(0.02); await process_frame
	await frame("02-boost-exhaust")
	game.player.boosting=false; game.player.shield=22; game.player.flight_state.update_state(0.1); game.player.flight_state.flash(game.player.position+Vector3(0,0,4))
	game.player.flight_state.set_process(false); game.player.flight_state.shield_mesh.material_override.set_shader_parameter("age",0.2)
	await frame("03-player-shield-damage"); game.player.flight_state.set_process(true)
	await create_timer(0.8).timeout
	game.set_process(false); await frame("04-critical-ship-smoke"); game.set_process(true)
	game.player.shield=100; game.player.chase_enabled=false; game.player.update_view(0)
	var target=game.drones[0]; target.position=Vector3(0,1,-49); target.visual.look_at(game.player.position); target.health=target.max_health*0.2; target.flight_state.flash(game.player.position)
	game.player.look_at(target.position); target.flight_state.set_process(false); target.flight_state.shield_mesh.material_override.set_shader_parameter("age",0.2)
	await frame("05-enemy-hit-shield"); target.flight_state.set_process(true)
	game.player.position=Vector3(0,3,-43); game.player.look_at(target.position); target.visual.rotation=Vector3(0,PI,0)
	await create_timer(0.5).timeout; game.set_process(false); await frame("06-enemy-scorch-smoke"); game.set_process(true)
	game.player.position=Vector3(0,1,-43); game.player.look_at(target.position)
	target.hit(10000,game.player.position,true); await frame("07-ship-breakup")
	await create_timer(0.25).timeout; await frame("08-engine-debris")
	game.player.position=Vector3(0,0,-18); game.player.rotation=Vector3(0,PI,0); game.player.chase_enabled=true; game.player.update_view(0); await frame("09-tight-corridor")
	game.state="paused"; game.hud.settings_open=true; game.hud.settings_tab="controls"; game.hud.rebuild_menu(); await frame("10-view-bindings")
	game.hud.settings_tab="flight"; game.hud.rebuild_menu(); await frame("11-audio-and-view-settings")
	game.queue_free(); await process_frame; await create_timer(0.15).timeout; quit()
