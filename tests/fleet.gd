extends SceneTree
var game
var failures=0
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures+=1; push_error(label)
func select_button(label: String) -> bool:
	for control in game.hud.ui.get_children():
		if control is Button and control.text==label:
			control.pressed.emit(); return true
	return false
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame
	check(select_button("FLEET HANGAR") and game.hud.front_view=="fleet","Flight-deck Fleet Hangar button opens its isolated 3D viewer")
	var profile=game.campaign.data.duplicate(true)
	for i in range(7):
		select_button(game.hud.FLEET[i].name); await process_frame
		var model=game.hud.livery_model
		check(game.hud.fleet_index==i and model.scene_file_path.ends_with(game.hud.FLEET[i].id+".glb") and model.find_child("EnginePlumes",true,false)!=null,"Fleet selection loads the correct hull and live exhaust: "+game.hud.FLEET[i].id)
	var h=game.hud; var original=game.player.basis; var rotation=h.livery_model.rotation
	var button=InputEventMouseButton.new(); button.button_index=MOUSE_BUTTON_LEFT; button.pressed=true; h.preview_input(button)
	var motion=InputEventMouseMotion.new(); motion.relative=Vector2(50,20); h.preview_input(motion)
	button.pressed=false; h.preview_input(button)
	check(h.livery_model.rotation!=rotation and not h.preview_spin and game.player.basis==original,"Dragging turns only the preview hull and stops auto rotation")
	var distance=h.preview_camera.position.length(); button.button_index=MOUSE_BUTTON_WHEEL_UP; button.pressed=true; h.preview_input(button)
	check(h.preview_camera.position.length()<distance,"Mouse wheel moves the actual preview camera closer")
	for i in range(80): h.preview_input(button)
	check(h.preview_camera.position.length()>=5.49,"Preview zoom stops at a safe near limit")
	select_button("REAR"); check(h.preview_camera.position.z>0 and not h.preview_spin,"Rear view exposes the engine nozzles")
	select_button("AUTO ROTATE"); check(h.preview_spin and h.preview_camera.position.z<0,"Auto rotate restores the presentation view")
	check(game.campaign.data==profile,"Inspecting the entire fleet does not change campaign progress")
	var event=InputEventKey.new(); event.keycode=KEY_ESCAPE; event.pressed=true; game._input(event)
	check(h.front_view=="title" and game.state=="menu","Escape returns from the hangar to the flight deck")
	game.queue_free(); await process_frame; await create_timer(0.15,true,false,true).timeout
	print("FLEET TEST COMPLETE: ",failures," failures"); quit(1 if failures else 0)
