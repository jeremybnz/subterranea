extends SceneTree
var game
func _initialize() -> void:
	root.set_meta("test_session",true)
	call_deferred("run")
func capture(name: String) -> void:
	for i in range(7): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/"+name+".png")
	print("CAPTURE: ",name)
func fresh(index: int) -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
		await process_frame
	root.set_meta("mission_selection",index)
	root.set_meta("front_view","title")
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
func view_at(pos: Vector3,at: Vector3) -> void:
	game.player.position=pos
	game.player.velocity=Vector3.ZERO
	game.player.look_at(at)
	game.player.camera.rotation=Vector3.ZERO
	game.nav_hint=game.route_hint()
	for drone in game.drones:
		var direction=(pos-drone.position).normalized()
		drone.visual.look_at(pos,Vector3.UP if absf(direction.y)<0.98 else Vector3.RIGHT)
	if is_instance_valid(game.boss): game.boss.visual.look_at(pos)
func freeze() -> void:
	game.player.set_physics_process(false)
	for drone in game.drones: drone.set_physics_process(false)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false)
func run() -> void:
	await fresh(0)
	await capture("campaign_title")
	game.hud.front_view="campaign"
	game.hud.rebuild_menu()
	await capture("campaign_locked")
	game.campaign.data.unlocked=2
	game.campaign.data.records[0].completed=true
	game.hud.rebuild_menu()
	await capture("campaign_operations")
	game.campaign.data.salvage=1800
	game.campaign.data.upgrades.shields=1
	game.campaign.data.upgrades.cannons=2
	game.hud.front_view="workshop"
	game.hud.rebuild_menu()
	await capture("upgrade_bay")
	await fresh(1)
	game.launch()
	freeze()
	view_at(Vector3(-48,2,-38),Vector3(-55,0,-50))
	await capture("cryo_archive")
	view_at(Vector3(-55,0,-46),Vector3(-55,0,-50))
	game.update_interaction(0)
	await capture("archive_interface")
	view_at(Vector3(5,50,-88),Vector3(0,47,-104))
	await capture("cryo_upper")
	game.map_open=true
	await capture("cryo_map")
	await fresh(2)
	game.launch()
	freeze()
	view_at(Vector3(12,5,-80),Vector3(0,0,-103))
	await capture("overseer_shielded")
	for i in range(3): game.damage_object(game.targets[i].node,100)
	game.boss.hit(600,game.player.position)
	freeze()
	await capture("overseer_phase2")
	game.boss.warming=0
	game.boss.hit(600,game.player.position)
	game.boss.warming=0
	game.boss.cooldown=0
	game.boss._physics_process(0.016)
	await capture("overseer_beam")
	game.map_open=true
	await capture("fortress_map")
	game.queue_free()
	await process_frame
	quit()
