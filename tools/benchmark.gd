extends SceneTree
var results=[]
func _initialize() -> void:
	root.set_meta("test_session",true)
	call_deferred("run")
func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	var game
	for mission in range(3):
		root.set_meta("mission_selection",mission)
		var start=Time.get_ticks_usec()
		game=load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		var startup=(Time.get_ticks_usec()-start)/1000.0
		game.launch()
		game.player.set_physics_process(false)
		game.player.shield=9999
		game.player.position=[Vector3(0,1,-44),Vector3(0,1,-48),Vector3(8,4,-85)][mission]
		game.player.look_at([Vector3(0,0,-66),Vector3(-20,0,-48),Vector3(0,0,-103)][mission])
		for i in range(30): await process_frame
		var samples=[]
		for i in range(100):
			var now=Time.get_ticks_usec()
			await process_frame
			samples.append((Time.get_ticks_usec()-now)/1000.0)
		samples.sort()
		var total=0.0
		for sample in samples: total+=sample
		results.append({"mission":mission+1,"startup_ms":startup,"mean_ms":total/samples.size(),"p50_ms":samples[50],"p95_ms":samples[95],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})
		game.queue_free()
		await process_frame
		await process_frame
	var output="res://tests/performance_baseline.json" if "--baseline" in OS.get_cmdline_user_args() else "res://tests/performance_current.json"
	if "--combat-v05" in OS.get_cmdline_user_args(): output="res://tests/performance_v05.json"
	if "--exploration-v06" in OS.get_cmdline_user_args(): output="res://tests/performance_v06.json"
	if "--navigation-v07" in OS.get_cmdline_user_args(): output="res://tests/performance_v07.json"
	if "--fleet-v08" in OS.get_cmdline_user_args(): output="res://tests/performance_v08.json"
	if "--flight-v09" in OS.get_cmdline_user_args(): output="res://tests/performance_v09.json"
	if "--polish-v091" in OS.get_cmdline_user_args(): output="res://tests/performance_v091.json"
	var file=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"vsync":"off","viewport":str(root.get_visible_rect().size),"results":results},"	"))
	file.close()
	print("BENCHMARK ",JSON.stringify(results))
	quit()
