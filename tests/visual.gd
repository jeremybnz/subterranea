extends SceneTree
var game
func _initialize() -> void:
	root.set_meta("test_session",true)
	root.set_meta("cinematic",true)
	call_deferred("run")
func capture(title: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/"+title+".png")
	print("CAPTURE: ",title)
func view_at(pos: Vector3,at: Vector3) -> void:
	game.player.position=pos
	game.player.velocity=Vector3.ZERO
	game.player.look_at(at,Vector3.UP if absf((at-pos).normalized().y)<0.98 else Vector3.FORWARD)
	game.player.camera.rotation=Vector3.ZERO
	game.nav_hint=game.route_hint()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(20): await process_frame
	await capture("title")
	game.launch()
	game.player.set_physics_process(false)
	for drone in game.drones: drone.set_physics_process(false)
	await capture("cockpit")
	view_at(Vector3(0,1,-36),Vector3(0,3,-54))
	await capture("nexus")
	game.hud_scale=0.8
	await capture("compact-hud")
	game.hud_scale=1.0
	view_at(Vector3(0,15,-44),Vector3(0,42,-44))
	await capture("shaft")
	view_at(Vector3(5,45,-36),Vector3(0,44,-55))
	await capture("turbines")
	view_at(Vector3(-37,-40,-35),Vector3(-46,-43,-52))
	await capture("foundry")
	view_at(Vector3(40,2,-79),Vector3(45,1,-98))
	await capture("pump")
	game.map_open=true
	await capture("map")
	game.map_open=false
	game.secret_door.breach()
	view_at(Vector3(-78,-43,-41),Vector3(-87,-43,-48))
	await capture("secret")
	for i in range(3): game.damage_object(game.targets[i].node,100)
	view_at(Vector3(7,4,-81),Vector3(0,0,-96))
	await capture("reactor")
	game.player.hurt(5,Vector3(20,0,-90))
	await capture("damage")
	game.state="paused"
	game.hud.rebuild_menu()
	await capture("pause")
	game.hud.settings_open=true
	game.hud.rebuild_menu()
	await capture("settings")
	game.hud.settings_open=false
	game.finish(true,"SURFACE REACHED","Nereid is silent. Your ship made it home.")
	await capture("results")
	game.queue_free()
	await process_frame
	quit()
