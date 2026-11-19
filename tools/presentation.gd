extends SceneTree
var game
var overlay
var trailer=false
var folder="res://exports/presskit"
func _initialize() -> void:
	root.set_meta("test_session",true)
	root.set_meta("cinematic",true)
	trailer="--trailer" in OS.get_cmdline_user_args()
	call_deferred("run")
func fresh(index: int,school: bool = false) -> void:
	if is_instance_valid(game):
		game.queue_free(); await process_frame; await process_frame
	root.set_meta("mission_selection",index)
	root.set_meta("training_requested",school)
	root.set_meta("front_view","title")
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await process_frame
	game.sound.music_volume=0 if trailer else 0.45
	game.sound.set_volume(0.85)
func view_at(pos: Vector3,at: Vector3) -> void:
	game.player.position=pos
	var direction=(at-pos).normalized()
	game.player.look_at(at,Vector3.UP if absf(direction.y)<0.98 else Vector3.FORWARD)
	game.player.camera.rotation=Vector3.ZERO
	game.nav_hint=game.route_hint()
func freeze() -> void:
	game.player.set_physics_process(false)
	for drone in game.drones:
		drone.set_physics_process(false)
		drone.visual.look_at(game.player.position)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false); game.boss.visual.look_at(game.player.position)
func capture(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/screenshots/"+name+".png")
	print("PRESS IMAGE: ",name)
func clip(title: String,subtitle: String,seconds: float,start: Vector3,end: Vector3,look: Vector3,mode: String = "") -> void:
	overlay.title=title; overlay.subtitle=subtitle; overlay.end_slate=mode=="end"
	var count=int(seconds*30)
	for i in range(count):
		var t=float(i)/(count-1)
		overlay.black=1-minf(1,minf(t*12,(1-t)*12))
		if mode!="end" and mode!="workshop":
			var at=look
			if mode=="combat" and not game.drones.is_empty(): at=game.drones[0].position
			if mode=="boss": at=game.boss.position
			view_at(start.lerp(end,t),at)
			game.player.velocity=(end-start)/seconds
			if mode=="combat" and i%9==0: game.fire_laser()
			if mode=="boss" and i in [50,95]: game.fire_missile()
			if mode=="ship": game.menu_ship.rotation.y+=0.004
		if mode=="workshop" and i==50: game.buy_upgrade("shields")
		await process_frame
	overlay.black=1
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder+"/screenshots"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder+"/source"))
	if trailer:
		var layer=CanvasLayer.new(); layer.layer=20; root.add_child(layer)
		overlay=load("res://tools/trailer_overlay.gd").new(); layer.add_child(overlay)
		overlay.black=1
		await fresh(0)
		game.sound.music.stream.save_to_wav(ProjectSettings.globalize_path(folder+"/source/score.wav"))
		game.sound.percussion.stream.save_to_wav(ProjectSettings.globalize_path(folder+"/source/rhythm.wav"))
		game.launch(); game.player.set_physics_process(false); game.hud.hide(); game.player.cockpit.hide(); game.menu_ship.show()
		await clip("SUBTERRANEA","A SIX-AXIS COMBAT FLIGHT INTO THE NEREID COMPLEX",3,Vector3(13,3,7),Vector3(8,2,2),Vector3(4,-0.5,-3),"ship")
		await fresh(0,true); game.launch(); game.player.set_physics_process(false); game.hud.hide()
		await clip("LEARN EVERY AXIS","FLIGHT SCHOOL / THRUST. STRAFE. ROLL. BOOST.",4,Vector3(0,2,12),Vector3(0,1,-12),Vector3(0,0,-35))
		await fresh(0); game.launch(); game.player.set_physics_process(false); game.hud.hide()
		await clip("BREAK THE SILENCE","EXPLORE VERTICAL MINES / DISABLE THE REACTOR",4,Vector3(6,3,-32),Vector3(-3,2,-44),Vector3(0,0,-55),"combat")
		await fresh(1); game.launch(); game.player.set_physics_process(false); game.hud.hide()
		await clip("RECOVER THE TRUTH","BOREAS ARCHIVES / THREE OPERATIONS. ONE WAY OUT.",4,Vector3(-49,2,-39),Vector3(-55,1,-46),Vector3(-55,0,-50))
		await fresh(2); game.launch(); game.player.set_physics_process(false); game.hud.hide(); game.player.shield=999
		for i in range(3): game.damage_object(game.targets[i].node,100)
		game.boss.phase=3; game.boss.health=500; game.boss.cooldown=0.5
		await clip("FACE THE OVERSEER","THREE BOSS PHASES / DODGE THE TARGETING BEAM",5,Vector3(12,4,-83),Vector3(7,5,-86),Vector3(0,0,-103),"boss")
		await fresh(0); game.campaign.data.salvage=1800; game.hud.front_view="workshop"; game.hud.rebuild_menu()
		await clip("BUILD YOUR KESTREL","EARN SALVAGE / INSTALL PERMANENT UPGRADES",3,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,"workshop")
		game.hud.hide()
		await clip("","",3,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,"end")
		print("TRAILER FRAMES COMPLETE")
	else:
		await fresh(0,true); game.launch(); freeze(); view_at(Vector3(-9,4,14),Vector3(0,0,-8)); await capture("01-flight-school")
		await fresh(0); game.launch(); view_at(Vector3(3,2,-37),Vector3(0,0,-53)); await capture("02-nereid-combat")
		await fresh(1); game.launch(); view_at(Vector3(-50,2,-40),Vector3(-55,0,-50)); await capture("03-boreas-archive")
		await fresh(2); game.launch(); view_at(Vector3(12,5,-80),Vector3(0,0,-103)); await capture("04-overseer")
		await fresh(0); game.campaign.data.salvage=1800; game.campaign.data.upgrades.shields=1; game.hud.front_view="workshop"; game.hud.rebuild_menu(); await capture("05-upgrade-bay")
		game.campaign.data.unlocked=2; game.hud.front_view="campaign"; game.hud.rebuild_menu(); await capture("06-campaign")
		game.hud.settings_open=true; game.hud.settings_tab="display"; game.hud.rebuild_menu(); await capture("07-display-options")
		game.hud.settings_tab="controls"; game.hud.binding_device="controller"; game.hud.rebuild_menu(); await capture("08-controller-bindings")
		game.hud.settings_open=false; game.hud.show_briefing(); await capture("09-mission-briefing")
		game.hud.front_view="credits"; game.hud.rebuild_menu(); await capture("10-credits")
	game.queue_free(); await process_frame
	quit()
