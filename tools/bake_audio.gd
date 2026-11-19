extends SceneTree
func _initialize() -> void:
	root.set_meta("bake_audio",true)
	call_deferred("run")
func run() -> void:
	var sound=load("res://scripts/sound.gd").new()
	root.add_child(sound)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/audio"))
	var weapons_only="--weapons-only" in OS.get_cmdline_user_args()
	for name in sound.streams:
		if weapons_only and name not in ["plasma","rail"]: continue
		ResourceSaver.save(sound.streams[name],"res://assets/audio/"+name+".res",ResourceSaver.FLAG_COMPRESS)
	if not weapons_only:
		ResourceSaver.save(sound.hum.stream,"res://assets/audio/engine.res",ResourceSaver.FLAG_COMPRESS)
		ResourceSaver.save(sound.alarm.stream,"res://assets/audio/alarm.res",ResourceSaver.FLAG_COMPRESS)
		ResourceSaver.save(sound.music.stream,"res://assets/audio/score.res",ResourceSaver.FLAG_COMPRESS)
		ResourceSaver.save(sound.percussion.stream,"res://assets/audio/rhythm.res",ResourceSaver.FLAG_COMPRESS)
	sound.queue_free()
	await process_frame
	print("Baked original audio effects and score for fast startup.")
	quit()
