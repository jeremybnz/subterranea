extends SceneTree
var game
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func capture(name: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw; root.get_texture().get_image().save_png("res://exports/contact-preview/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://exports/contact-preview"))
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; await physics_frame; game.launch(); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false); d.position=Vector3(1000+d.spawn_id*4,1000,1000)
	game.player.position=Vector3(0,44,-99); game.player.rotation=Vector3.ZERO; game.player.update_view(0); game.notice_time=0; await physics_frame; game.fire_laser(); await capture("01-glass-strike")
	game.player.position=Vector3(8,1,-44); game.player.look_at(Vector3(8,1,-29)); game.player.update_view(0); await physics_frame; game.fire_laser(); await capture("02-metal-wall-strike")
	game.player.position=Vector3(0,1,-44); game.player.rotation=Vector3.ZERO; game.player.update_view(0)
	var target=game.spawn_drone(Vector3(0,1,-50),"bulwark"); target.set_physics_process(false); target.visual.look_at(game.player.position); await physics_frame; game.fire_laser(); await capture("03-armored-contact")
	game.queue_free(); await process_frame; await create_timer(0.2,true,false,true).timeout; quit()
