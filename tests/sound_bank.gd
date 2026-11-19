extends SceneTree
var game
var failures=0
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures+=1; push_error(label)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; game.launch(); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	var sound=game.sound
	check(sound.variations.size()==12,"All twelve licensed effect categories load from the new sound bank")
	var valid=true
	for kind in sound.variations:
		for clip in sound.variations[kind]:
			valid=valid and clip is AudioStreamWAV and clip.mix_rate==44100 and not clip.stereo and clip.get_length()>0.1
	check(valid,"Every new effect decodes as spatial-ready mono 44.1 kHz audio")
	check(sound.hum.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and sound.boost_audio.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and sound.streams.machine.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Engine, boost and machinery resources have real looping playback bounds")
	var previous=null; var repeated=false
	for i in range(30):
		var clip=sound.choose_stream("laser"); repeated=repeated or clip==previous; previous=clip
	check(not repeated,"Rapid pulse fire never repeats the same variant immediately")
	check(sound.streams.laser!=sound.streams.plasma and sound.streams.plasma!=sound.streams.rail,"Pulse, plasma and rail use distinct prepared weapon resources")
	check(sound.streams.door_open!=sound.streams.door_close,"Door opening and closing use distinct mechanical recordings")
	var shots=game.combat_stats.shots.pulse
	Input.action_press("ship_fire"); game.player.set_physics_process(true); await frames(12); Input.action_release("ship_fire"); game.player.set_physics_process(false)
	var voices=get_nodes_in_group("mix_Weapons")
	check(game.combat_stats.shots.pulse>shots and voices.any(func(v): return v.stream.resource_path.ends_with(".wav")),"The actual primary trigger plays the imported weapon bank")
	for i in range(45): sound.play_tone("laser",0.1)
	check(get_nodes_in_group("mix_Weapons").size()<=20,"Imported weapon tails retain the twenty-voice concurrency limit")
	sound.impact_duck=0; game.exploration.radio_time=0; sound.effects_volume=1; sound._process(0.01)
	var music=AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")); var effects=AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Weapons"))
	sound.effects_volume=0.5; sound._process(0.01)
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Weapons"))<effects-5.9 and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),music),"Effects volume changes the SFX buses without changing music volume")
	game.player.boosting=true; game.player.thrust_level=1
	for i in range(10): sound._process(0.05)
	check(sound.boost_mix>0.95 and sound.boost_audio.volume_db>-21,"Afterburner input raises the separate reactive boost sound")
	game.player.boosting=false
	for i in range(20): sound._process(0.05)
	check(sound.boost_mix<0.005 and sound.boost_audio.volume_db<=-79,"Releasing boost smoothly silences its extra audio layer")
	game.state="paused"; sound.play_tone("ui"); sound._process(0.01)
	check(sound.hum.stream_paused and sound.boost_audio.stream_paused and get_nodes_in_group("mix_Weapons").all(func(v): return v.stream_paused),"Pause freezes engine, boost and weapon playback")
	check(get_nodes_in_group("mix_Interface").any(func(v): return not v.stream_paused and v.playing),"Interface cues remain audible during pause")
	var limiters=0
	for i in range(AudioServer.get_bus_effect_count(0)):
		if AudioServer.get_bus_effect(0,i) is AudioEffectLimiter: limiters+=1
	check(limiters==1,"A single master limiter protects the final mix from transient overload")
	game.hud.settings_open=true; game.hud.settings_tab="flight"; game.hud.rebuild_menu()
	check(game.hud.ui.get_children().filter(func(n): return n is HSlider).size()==4,"Flight settings expose separate sensitivity, master, music and effects controls")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/sfx/manifest.json"))
	check(manifest.source.license=="CC0-1.0" and manifest.files.size()==30,"Every prepared sound and loop has recorded CC0 source provenance")
	game.queue_free(); await process_frame; await process_frame; await create_timer(0.2,true,false,true).timeout
	print("SOUND BANK TEST COMPLETE: ",failures," failures"); quit(1 if failures else 0)
