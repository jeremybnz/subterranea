extends SceneTree
var game
var folder="res://exports/fleet-preview"
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func capture(name: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")
	if game.hud.front_view in ["fleet","livery"]: game.hud.preview_camera.get_viewport().get_texture().get_image().save_png(folder+"/"+name+"-detail.png")
	print("FLEET IMAGE: ",name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame
	game.hud.front_view="fleet"
	for i in range(7):
		game.hud.fleet_index=i; game.hud.rebuild_menu(); game.hud.preview_spin=false
		await capture("0%d-%s" % [i+1,game.hud.FLEET[i].id])
	game.hud.fleet_index=0; game.hud.rebuild_menu(); game.hud.preview_view(1); await capture("08-kestrel-rear")
	game.campaign.discover("caches","0_cache",0,"ember"); game.exploration.select_paint("ember")
	game.hud.front_view="livery"; game.hud.rebuild_menu(); game.hud.preview_spin=false; await capture("09-ember-livery")
	game.launch(); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	game.player.position=Vector3(0,1,-30); game.player.look_at(Vector3(0,0,-48)); game.notice_time=0
	await capture("10-cockpit")
	var scout=game.drones.filter(func(d): return d.role=="scout")[0]; scout.position=Vector3(0,1,-41); scout.visual.look_at(game.player.position)
	game.player.look_at(scout.position); game.update_aim(); await capture("11-in-mine-scout")
	game.queue_free(); await process_frame; await create_timer(0.15).timeout; quit()
