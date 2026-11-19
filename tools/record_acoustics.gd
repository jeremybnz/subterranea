extends SceneTree
var game
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func wait_seconds(seconds: float) -> void: await create_timer(seconds,true,false,true).timeout
func burst() -> void:
	for i in range(3):
		game.sound.play_at("laser",Vector3(0,1,-49),0.7)
		await wait_seconds(0.25)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; await physics_frame; game.launch(); game.set_process(false); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false); d.flight_state.set_process(false)
	game.player.position=Vector3(0,1,-44); game.player.rotation=Vector3.ZERO; game.player.update_view(0)
	var sound=game.sound; sound.music.stop(); sound.percussion.stop(); sound.hum.stop(); sound.alarm.stop(); sound.boost_audio.stop()
	for voice in get_nodes_in_group("ambient_loops"): voice.stop()
	sound.variations.laser=[sound.variations.laser[0]]; sound.effects_volume=1
	var record=AudioEffectRecord.new(); AudioServer.add_bus_effect(0,record); record.set_recording_active(true)
	await wait_seconds(0.25); await burst(); await wait_seconds(0.45)
	var wall=game.Forge.box(game,Vector3(0,1,-47),Vector3(4,4,0.3),Color.GRAY,0,true); await physics_frame
	await burst(); await wait_seconds(0.45)
	wall.queue_free(); await physics_frame; await burst(); await wait_seconds(0.45)
	record.set_recording_active(false); var captured=record.get_recording()
	var result=captured.save_to_wav("res://exports/v091-clear-muffled-clear.wav")
	print("ACOUSTIC RECORDING ",captured.get_length()," seconds, save=",result)
	game.queue_free(); await process_frame; await wait_seconds(0.2); quit(0 if result==OK else 1)
