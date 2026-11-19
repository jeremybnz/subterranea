extends SceneTree
var failures = 0
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else:
		failures += 1
		push_error(message)
func key(code: Key,pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func mouse(pressed: bool) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _initialize() -> void:
	root.set_meta("test_session",true)
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game.hud.front_view="campaign"
	game.launch()
	check(game.hud.front_view=="title","Deploying from campaign selection clears the menu overlay")
	game.player.flight_assist=true
	game.player.invert_mouse=false
	for entry in [[KEY_W,Vector3.FORWARD],[KEY_S,Vector3.BACK],[KEY_A,Vector3.LEFT],[KEY_D,Vector3.RIGHT],[KEY_SPACE,Vector3.UP],[KEY_CTRL,Vector3.DOWN]]:
		game.player.position=Vector3.ZERO
		game.player.velocity=Vector3.ZERO
		key(entry[0],true)
		for i in range(15): await physics_frame
		key(entry[0],false)
		check(game.player.position.dot(entry[1])>0.2,"Flight input "+OS.get_keycode_string(entry[0])+" moves in correct ship-local direction")
	game.player.position=Vector3.ZERO
	game.player.velocity=Vector3.ZERO
	key(KEY_W,true)
	key(KEY_SHIFT,true)
	for i in range(40): await physics_frame
	key(KEY_W,false)
	key(KEY_SHIFT,false)
	check(game.player.velocity.length()>game.player.CRUISE_SPEED and game.player.boost<100,"Afterburner increases speed and spends boost")
	var boost_speed=game.player.velocity.length()
	game.player.flight_assist=false
	for i in range(15): await physics_frame
	check(game.player.velocity.length()>boost_speed*0.85,"Drift mode retains momentum after thrust release")
	key(KEY_C,true)
	for i in range(30): await physics_frame
	key(KEY_C,false)
	check(game.player.velocity.length()<0.1,"Airbrake stops the ship even in drift mode")
	game.player.flight_assist=true
	game.player.velocity=Vector3.RIGHT*10
	for i in range(30): await physics_frame
	check(game.player.velocity.length()<0.1,"Flight assist brakes automatically after thrust release")
	game.player.velocity=Vector3.ZERO
	game.player.position=Vector3.ZERO
	key(KEY_Q,true)
	for i in range(15): await physics_frame
	key(KEY_Q,false)
	check(absf(game.player.rotation.z)>0.15,"Q rolls the ship")
	var motion = InputEventMouseMotion.new()
	motion.relative=Vector2(40,-20)
	game.player._unhandled_input(motion)
	check(absf(game.player.rotation.y)>0.03 and absf(game.player.rotation.x)>0.02,"Mouse steers yaw and pitch")
	check(absf(game.player.basis.determinant()-1)<0.001,"Flight rotation maintains an orthonormal basis")
	game.player.rotation=Vector3.ZERO
	var drone = game.drones[0]
	drone.set_physics_process(false)
	drone.position=Vector3(0,0,-8)
	await physics_frame
	var health_before=drone.health
	mouse(true)
	for i in range(12): await physics_frame
	mouse(false)
	check(drone.health<health_before,"Left mouse fires real raycast damage at aimed drone")
	key(KEY_TAB,true)
	key(KEY_TAB,false)
	await process_frame
	check(game.map_open,"Tab toggles tactical map")
	key(KEY_ESCAPE,true)
	key(KEY_ESCAPE,false)
	await process_frame
	check(not game.map_open and game.state=="playing","Escape closes the automap before opening pause")
	key(KEY_ESCAPE,true); key(KEY_ESCAPE,false); await process_frame
	check(game.state=="paused","Escape opens pause menu")
	var has_resume=false
	for control in game.hud.ui.get_children():
		if control is Button and control.text=="RESUME FLIGHT": has_resume=true
	check(has_resume,"Pause after campaign deployment offers Resume rather than starting a new run")
	var frozen = game.mission_time
	for i in range(5): await physics_frame
	check(game.mission_time==frozen,"Mission simulation freezes during pause")
	game.resume()
	for i in range(3): await process_frame
	check(game.state=="playing" and game.mission_time>frozen,"Resume continues mission simulation")
	print("FLIGHT TEST COMPLETE: ",failures," failures")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
