extends SceneTree
const Bindings=preload("res://scripts/controls.gd")
var failures=0
var game
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else: failures+=1; push_error(message)
func _initialize() -> void:
	root.set_meta("test_session",true)
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func key(code: Key,pressed: bool) -> InputEventKey:
	var event=InputEventKey.new()
	event.keycode=code; event.physical_keycode=code; event.pressed=pressed
	Input.parse_input_event(event); Input.flush_buffered_events()
	return event
func motion(axis: JoyAxis,value: float) -> void:
	var event=InputEventJoypadMotion.new()
	event.device=0; event.axis=axis; event.axis_value=value
	Input.parse_input_event(event); Input.flush_buffered_events()
func button(index: JoyButton,pressed: bool) -> void:
	var event=InputEventJoypadButton.new()
	event.device=0; event.button_index=index; event.pressed=pressed
	Input.parse_input_event(event); Input.flush_buffered_events()
func action(name: String,pressed: bool,strength: float = 1.0) -> void:
	if pressed: Input.action_press("ship_"+name,strength)
	else: Input.action_release("ship_"+name)
func event_action(name: String) -> void:
	var event=InputEventAction.new()
	event.action="ship_"+name; event.pressed=true
	Input.parse_input_event(event); Input.flush_buffered_events()
func wait_step(expected: int,limit: int = 360) -> void:
	for i in range(limit):
		if game.training.step>=expected or game.state=="won": return
		await physics_frame
	check(false,"Timed out reaching training check "+str(expected+1))
func brake() -> void:
	action("forward",false); action("boost",false); action("left",false); action("up",false)
	action("brake",true)
	await frames(60)
	action("brake",false)
func fly(goal: Vector3) -> bool:
	for i in range(1200):
		var distance=game.player.position.distance_to(goal)
		if distance<1.5:
			await brake()
			return true
		var direction=(goal-game.player.position).normalized()
		game.player.look_at(goal,Vector3.UP if absf(direction.y)<0.98 else Vector3.FORWARD)
		action("forward",true,clampf(distance/10,0.12,1))
		action("boost",distance>12)
		await physics_frame
	await brake()
	return false
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame; await physics_frame
	check(game.batch_stats.input_meshes>1000 and game.batch_stats.batches<game.batch_stats.input_meshes/3,"Static geometry batches preserve the mine with fewer render objects")
	check(game.spread_direction(Vector3.UP,0.12).distance_to(game.spread_direction(Vector3.UP,-0.12))>0.2,"Vertical enemy shots retain a distinct spread")
	var c=game.controls
	var event=InputEventKey.new(); event.physical_keycode=KEY_S; event.pressed=true
	check(c.bind_event("forward",event,false) and c.bindings.reverse==["key",KEY_W],"Conflicting keyboard bindings swap instead of leaving an action unbound")
	event.physical_keycode=KEY_T
	c.bind_event("forward",event,false)
	key(KEY_T,true)
	check(c.held("forward"),"A remapped physical key activates the actual flight action")
	key(KEY_T,false)
	var mouse=InputEventMouseButton.new(); mouse.button_index=MOUSE_BUTTON_RIGHT; mouse.pressed=true
	check(c.bind_event("fire",mouse,false) and c.bindings.missile==["mouse",MOUSE_BUTTON_LEFT],"Mouse bindings can be remapped and conflicts are swapped")
	var path="res://tests/tmp_bindings_"+str(OS.get_process_id())+".cfg"
	var cfg=ConfigFile.new(); cfg.set_value("bindings","keys",c.bindings); cfg.save(path)
	var restored=ConfigFile.new(); restored.load(path)
	var other=Bindings.new(); other.load_bindings(restored.get_value("bindings","keys"),{})
	check(other.bindings.forward==["key",KEY_T],"Bindings survive a real configuration-file round trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	c.reset()
	game.launch()
	for drone in game.drones: drone.set_physics_process(false)
	motion(JOY_AXIS_LEFT_Y,0.06)
	check(c.strength("reverse")==0,"Controller deadzone rejects small stick drift")
	motion(JOY_AXIS_LEFT_Y,-0.8)
	await frames(20)
	check(game.player.position.z<7 and c.last_device=="controller","Virtual left-stick input moves the ship forward")
	motion(JOY_AXIS_LEFT_Y,0)
	var before=game.player.basis
	motion(JOY_AXIS_RIGHT_X,0.7)
	await frames(15)
	motion(JOY_AXIS_RIGHT_X,0)
	check(not game.player.basis.is_equal_approx(before),"Virtual right-stick input steers the ship")
	button(JOY_BUTTON_START,true); button(JOY_BUTTON_START,false)
	await process_frame
	check(game.state=="paused","Gamepad Start opens the pause menu")
	button(JOY_BUTTON_START,true); button(JOY_BUTTON_START,false)
	await process_frame
	check(game.state=="playing","Gamepad Start resumes flight")
	button(JOY_BUTTON_START,true); button(JOY_BUTTON_START,false)
	await process_frame; await process_frame
	button(JOY_BUTTON_A,true); await process_frame; button(JOY_BUTTON_A,false)
	await process_frame
	check(game.state=="playing","Gamepad A activates the focused Resume button")
	game.player.position=Vector3.ZERO; game.player.rotation=Vector3.ZERO; game.player.velocity=Vector3.ZERO
	game.player.base_fov=70
	await frames(50)
	check(absf(game.player.camera.fov-70)<0.5,"FOV adjustment changes the real flight camera")
	game.graphics_preset=0; game.apply_graphics()
	check(game.get_viewport().msaa_3d==Viewport.MSAA_DISABLED and not game.environment.glow_enabled,"Performance preset applies its render settings")
	game.graphics_preset=2; game.apply_graphics()
	check(game.get_viewport().msaa_3d==Viewport.MSAA_4X and game.environment.glow_enabled,"Quality preset restores antialiasing and glow")
	game.player.shield=100; game.difficulty=0; game.player.hurt(20)
	check(is_equal_approx(game.player.shield,87),"Pilot difficulty applies reduced incoming damage")
	game.difficulty=2; game.player.hurt(20)
	check(is_equal_approx(game.player.shield,61),"Ace difficulty applies its increased damage")
	game.state="menu"; game.hud.show_briefing()
	check(game.hud.front_view=="briefing" and game.hud.ui.get_child(0).text.begins_with("LAUNCH"),"Operation briefing offers an explicit launch action")
	print("PHYSICAL CONTROLLERS PRESENT: ",Input.get_connected_joypads().size())
	game.queue_free(); await process_frame; await process_frame
	root.set_meta("training_requested",true)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await process_frame; await physics_frame
	game.campaign.data.checkpoint={"mission":0,"pilot":{},"targets":[]}
	game.launch()
	check(game.training_mode and not game.campaign.data.checkpoint.is_empty(),"Starting training preserves the active campaign checkpoint")
	action("forward",true)
	await wait_step(1)
	await brake()
	check(game.training.step==1,"Real forward thrust reaches the first training marker")
	game.player.rotation=Vector3.ZERO
	action("left",true)
	await wait_step(2)
	await brake()
	check(game.training.step==2,"Real strafing completes the lateral flight check")
	game.player.rotation=Vector3.ZERO
	action("up",true)
	await wait_step(3)
	await brake()
	check(game.training.step==3,"Real lift input completes the rise check")
	action("roll_left",true); await frames(50); action("roll_left",false)
	check(game.training.step==4,"Sustained roll input completes the attitude check")
	check(await fly(Vector3(0,0,-12)),"Boosted ship reaches the forward training gate")
	await frames(5)
	check(game.training.step==6,"Boost and real airbraking complete their training checks")
	game.player.look_at(game.targets[0].pos)
	action("fire",true); await wait_step(7); action("fire",false)
	check(game.training.step==7,"Pulse fire destroys the live training target")
	game.player.look_at(game.targets[1].pos)
	action("missile",true); await frames(2); action("missile",false)
	await wait_step(8)
	check(game.training.step==8,"A moving missile destroys the missile training target")
	event_action("map"); await wait_step(9)
	check(game.training.step==9,"Opening the map completes its training check")
	event_action("map"); await process_frame
	check(not game.map_open,"Closing the map restores flight control for the next training check")
	check(await fly(Vector3(0,0,-58)),"Flight course conduit is physically traversable")
	check(await fly(Vector3(0,46,-58)),"Ship flies through the full vertical training shaft")
	check(game.training.step==10,"Reaching the upper deck completes vertical-flight training")
	check(await fly(Vector3(0,46,-65)),"Ship reaches the service interface")
	action("interact",true); await frames(150); action("interact",false)
	check(game.state=="won" and game.campaign.data.training_complete,"Holding interact completes certification")
	check(not game.campaign.data.checkpoint.is_empty() and game.campaign.data.unlocked==0,"Certification preserves campaign progress without granting mission rewards")
	print("READINESS TEST COMPLETE: ",failures," failures")
	game.queue_free(); await process_frame; await process_frame
	quit(1 if failures else 0)
