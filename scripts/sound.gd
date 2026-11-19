extends Node
## Kenney CC0 effects, original layered score and positional mine audio.
const Bank=preload("res://scripts/sound_bank.gd")
var game: Node3D
var streams: Dictionary = {}
var volume = 0.65
var music_volume = 0.45
var hum: AudioStreamPlayer
var music: AudioStreamPlayer
var percussion: AudioStreamPlayer
var alarm: AudioStreamPlayer
var intensity = 0.0
var warning_time = 0.0
var impact_duck=0.0
var mix_gains={}
var variations={}
var last_variant={}
var effects_volume=0.85
var boost_audio: AudioStreamPlayer
var boost_mix=0.0
var occlusion_timer=0.0
var occlusion_cursor=0
var occlusion_checks=0
func blocked_source(pos: Vector3) -> bool:
	if not is_instance_valid(game) or not is_instance_valid(game.player): return false
	var listener=game.player.camera.global_position
	if pos.distance_to(listener)<0.35: return false
	occlusion_checks+=1
	return not game.clear_line(pos+(listener-pos).normalized()*0.08,listener)
func refresh_occlusion() -> void:
	var voices=get_tree().get_nodes_in_group("spatial_audio")
	if voices.is_empty(): return
	for i in range(mini(8,voices.size())):
		var player=voices[posmod(occlusion_cursor,voices.size())]; occlusion_cursor+=1
		if not is_instance_valid(player) or player.is_queued_for_deletion(): continue
		if player.get_meta("source_bus","")=="Interface": continue
		if player.global_position.distance_to(game.player.camera.global_position)>player.max_distance: continue
		player.set_meta("occlusion_target",1.0 if blocked_source(player.global_position) else 0.0)
func update_spatial_mix(delta: float,active: bool) -> void:
	if active:
		occlusion_timer-=delta
		if occlusion_timer<=0: occlusion_timer=0.08; refresh_occlusion()
	for player in get_tree().get_nodes_in_group("spatial_audio"):
		if player.is_queued_for_deletion(): continue
		var base=str(player.get_meta("source_bus","Ambience"))
		var amount=float(player.get_meta("occlusion",0))
		if active: amount=lerpf(amount,float(player.get_meta("occlusion_target",0)),1-exp(-delta*12))
		player.set_meta("occlusion",amount)
		var level=float(player.get_meta("dry_db",-8))-14*amount
		if not is_equal_approx(player.volume_db,level): player.volume_db=level
		var route="Muffled_"+base if base!="Interface" and amount>0.5 else base
		if player.bus!=route: player.bus=route

func install_bank() -> void:
	for kind in Bank.EFFECTS:
		variations[kind]=[]
		for file in Bank.EFFECTS[kind]: variations[kind].append(load("res://assets/audio/sfx/"+file))
		streams[kind]=variations[kind][0]
	streams["door"]=streams.door_open
	streams["shield_hit"]=streams.hurt
	streams["machine"]=load_loop(Bank.LOOPS.machine)
func load_loop(file: String) -> AudioStreamWAV:
	var stream=load("res://assets/audio/sfx/"+file).duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD; stream.loop_begin=0; stream.loop_end=stream.data.size()/(4 if stream.stereo else 2)
	return stream
func choose_stream(kind: String) -> AudioStream:
	if not variations.has(kind): return streams[kind]
	var pool=variations[kind]; var index=randi_range(0,pool.size()-1)
	if pool.size()>1 and index==last_variant.get(kind,-1): index=(index+1)%pool.size()
	last_variant[kind]=index
	return pool[index]


func _ready() -> void:
	var protected_mix=false
	for i in range(AudioServer.get_bus_effect_count(0)):
		if AudioServer.get_bus_effect(0,i) is AudioEffectLimiter: protected_mix=true
	if not protected_mix:
		var limiter=AudioEffectLimiter.new(); limiter.ceiling_db=-1; limiter.threshold_db=-5; limiter.soft_clip_db=-3; AudioServer.add_bus_effect(0,limiter)
	for bus in ["Weapons","Impacts","Ambience","Music","Interface"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	for base in ["Weapons","Impacts","Ambience"]:
		var muffled="Muffled_"+base
		if AudioServer.get_bus_index(muffled)<0:
			AudioServer.add_bus(); var index=AudioServer.bus_count-1; AudioServer.set_bus_name(index,muffled); AudioServer.set_bus_send(index,base)
			var filter=AudioEffectLowPassFilter.new(); filter.cutoff_hz=1800; AudioServer.add_bus_effect(index,filter)
	var cached=not get_tree().root.get_meta("bake_audio",false) and ResourceLoader.exists("res://assets/audio/score.res")
	for kind in ["laser","enemy","blast","hurt","pickup","relay","ui","missile","door","charge","hit","plasma","rail"]:
		streams[kind]=load("res://assets/audio/"+kind+".res") if cached and ResourceLoader.exists("res://assets/audio/"+kind+".res") else synth(kind)
	streams["machine"]=load("res://assets/audio/machine.res") if cached else loop_sound("machine")
	streams["shield_hit"]=streams.hurt
	streams["warning"]=streams.charge
	streams["door_open"]=streams.door; streams["door_close"]=streams.door
	if cached and ResourceLoader.exists("res://assets/audio/sfx/engine_loop.wav"): install_bank()
	hum = loop_player(load("res://assets/audio/engine.res") if cached else loop_sound("engine"),-28)
	if not variations.is_empty():
		hum.stream=load_loop(Bank.LOOPS.engine); hum.play()
		boost_audio=loop_player(load_loop(Bank.LOOPS.boost),-80); boost_audio.bus="Ambience"
	alarm = loop_player(load("res://assets/audio/alarm.res") if cached else loop_sound("alarm"),-80)
	var layers = [load("res://assets/audio/score.res"),load("res://assets/audio/rhythm.res")] if cached else compose_score()
	music = loop_player(layers[0],-24)
	percussion = loop_player(layers[1],-80)
	hum.bus="Ambience"; alarm.bus="Interface"; music.bus="Music"; percussion.bus="Music"
	set_volume(volume)

func wave(data: PackedByteArray,rate: int,looped: bool = false,stereo: bool = false) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=rate
	wav.stereo=stereo
	wav.data=data
	if looped:
		wav.loop_mode=AudioStreamWAV.LOOP_FORWARD
		wav.loop_end=data.size()/(4 if stereo else 2)
	return wav

func loop_player(stream: AudioStream,db: float) -> AudioStreamPlayer:
	var player=AudioStreamPlayer.new()
	add_child(player)
	player.stream=stream
	player.volume_db=db
	player.play()
	return player

func loop_sound(kind: String) -> AudioStreamWAV:
	var rate=16000
	var data=PackedByteArray()
	data.resize(rate*2*2)
	for i in range(rate*2):
		var t=float(i)/rate
		var sample=0.0
		match kind:
			"engine": sample=sin(TAU*55*t)*0.2+sin(TAU*110*t)*0.07+sin(TAU*82.5*t)*0.05
			"machine": sample=(sin(TAU*42*t)*0.2+sin(TAU*126*t)*0.05+randf_range(-0.018,0.018))*(0.8+sin(TAU*2*t)*0.2)
			"alarm": sample=sin(TAU*(420*t-65*cos(TAU*t)/TAU))*0.15*(0.6+sin(TAU*t)*0.4)
		data.encode_s16(i*2,int(clampf(sample,-1,1)*24000))
	return wave(data,rate,true)

func compose_score() -> Array:
	var rate=16000
	var pad=PackedByteArray()
	var drums=PackedByteArray()
	pad.resize(rate*8*4)
	drums.resize(rate*8*2)
	var notes=[220.0,261.6256,293.6648,329.6276,391.9954,329.6276,293.6648,261.6256]
	for i in range(rate*8):
		var t=float(i)/rate
		var beat=fmod(t,0.5)
		var step=fmod(t,0.25)
		var note=notes[int(t*2)%8]
		var env=sin(PI*t/8)*sin(PI*t/8)
		var note_env=pow(sin(PI*step/0.25),2)*exp(-step*8)
		var melody=sin(TAU*note*step)*note_env*0.08
		var bass=(sin(TAU*55*t)+sin(TAU*82.5*t)*0.35)*0.06
		var pad_tone=(sin(TAU*110*t)+sin(TAU*164.8138*t)*0.4+sin(TAU*220*t)*0.25)*0.035*env
		var left=bass+pad_tone+melody
		var right=bass+pad_tone*0.85+sin(TAU*note*step+0.22)*note_env*0.08
		pad.encode_s16(i*4,int(clampf(left,-1,1)*26000))
		pad.encode_s16(i*4+2,int(clampf(right,-1,1)*26000))
		var kick=sin(TAU*62*beat)*exp(-beat*24)*0.28
		var hat=randf_range(-1,1)*exp(-step*95)*0.07
		var snare=randf_range(-1,1)*exp(-beat*27)*0.12 if int(t*2)%2==1 else 0.0
		drums.encode_s16(i*2,int((kick+hat+snare)*23000))
	return [wave(pad,rate,true,true),wave(drums,rate,true)]

func synth(kind: String) -> AudioStreamWAV:
	var duration=0.18
	if kind in ["blast","relay"]: duration=0.85
	if kind in ["missile","charge"]: duration=0.5
	if kind=="door": duration=0.65
	var data=PackedByteArray()
	data.resize(int(duration*22050)*2)
	var phase=0.0
	for i in range(data.size()/2):
		var t=float(i)/22050
		var u=t/duration
		var freq=lerpf(1100,150,u)
		var noise=randf_range(-1,1)
		var sample=0.0
		match kind:
			"plasma": sample=(sin(TAU*(190*t-100*t*t))*0.65+randf_range(-0.2,0.2))*exp(-t*12)
			"rail": sample=(randf_range(-1,1)*0.65+sin(TAU*70*t)*0.35)*exp(-t*24)
			"laser": sample=sin(phase)*0.45+sin(phase*2.01)*0.12
			"enemy": freq=lerpf(430,100,u); sample=sin(phase)*0.45
			"blast","relay": freq=lerpf(110,28,u); sample=noise*0.5+sin(phase)*0.55
			"hurt": freq=lerpf(180,65,u); sample=noise*0.25+sin(phase)*0.5
			"pickup","ui": freq=660 if u<0.5 else 990; sample=sin(phase)*0.35
			"missile": freq=lerpf(180,60,u); sample=noise*0.5+sin(phase)*0.2
			"door": freq=lerpf(75,45,u); sample=noise*0.2+sin(phase)*0.25
			"charge": freq=lerpf(230,720,u); sample=sin(phase)*0.3*u
			"hit": freq=lerpf(2200,700,u); sample=noise*0.35+sin(phase)*0.2
		phase+=TAU*freq/22050
		sample*=pow(1-u,2)*minf(1,t*180)
		data.encode_s16(i*2,int(clampf(sample,-1,1)*24000))
	return wave(data,22050)

func play_tone(kind: String,strength: float = 1.0) -> void:
	if not streams.has(kind): return
	var player=AudioStreamPlayer.new()
	add_child(player)
	player.bus=category(kind)
	limit_voices(player.bus)
	player.add_to_group("mix_"+player.bus)
	player.stream=choose_stream(kind)
	player.volume_db=linear_to_db(maxf(0.001,strength))-7
	player.pitch_scale=randf_range(0.95,1.05)
	player.add_to_group("transient_audio")
	player.finished.connect(player.queue_free)
	player.play()

func play_at(kind: String,pos: Vector3,strength: float = 1.0,looped: bool = false) -> AudioStreamPlayer3D:
	if not streams.has(kind): return null
	var player=AudioStreamPlayer3D.new()
	game.add_child(player)
	player.position=pos
	player.bus=category(kind)
	if not looped:
		limit_voices(player.bus)
		player.add_to_group("mix_"+player.bus)
	player.stream=choose_stream(kind)
	player.unit_size=8
	player.max_distance=65
	player.volume_db=linear_to_db(maxf(0.001,strength))-8
	player.set_meta("dry_db",player.volume_db); player.set_meta("source_bus",player.bus); player.set_meta("sound_kind",kind)
	var blocked=player.bus!="Interface" and blocked_source(pos)
	player.set_meta("occlusion",1.0 if blocked else 0.0); player.set_meta("occlusion_target",1.0 if blocked else 0.0)
	if blocked: player.volume_db-=14; player.bus="Muffled_"+str(player.get_meta("source_bus"))
	player.add_to_group("spatial_audio")
	if looped: player.add_to_group("ambient_loops")
	if not looped:
		player.add_to_group("transient_audio")
		player.finished.connect(player.queue_free)
	player.play()
	return player

func attach_ambience() -> void:
	for source in game.ambient_sources: play_at(source.kind,source.pos,source.volume,true)

func set_volume(value: float) -> void:
	volume=value
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(value,0.0001)))

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player): return
	impact_duck=maxf(0,impact_duck-delta)
	var radio_active=is_instance_valid(game.exploration) and game.exploration.radio_time>0
	set_mix_gain("Weapons",-2 if impact_duck>0 else 0)
	set_mix_gain("Impacts",-2)
	set_mix_gain("Ambience",-4 if radio_active or impact_duck>0 else -1)
	set_mix_gain("Music",-4 if radio_active else (-2 if impact_duck>0 else 0))
	set_mix_gain("Interface",0)
	var active=game.state=="playing" and not game.map_open
	update_spatial_mix(delta,active)
	var threat=0.0
	if active:
		for drone in game.drones:
			if is_instance_valid(drone) and drone.alert_time>0: threat=maxf(threat,1-clampf(drone.position.distance_to(game.player.position)/55,0,1))
		if game.reactor_down or (is_instance_valid(game.boss) and not game.boss.dead and game.boss.alert_time>0): threat=1
	intensity=lerpf(intensity,threat,1-exp(-delta*2))
	var music_gain=linear_to_db(maxf(music_volume,0.0001))
	music.volume_db=music_gain-13-(0 if active or game.state=="menu" else 6)
	percussion.volume_db=music_gain-12+linear_to_db(maxf(intensity,0.0001))
	var speed_ratio=clampf(game.player.velocity.length()/25,0,1) if active else 0.0
	hum.pitch_scale=lerpf(hum.pitch_scale,0.85+speed_ratio*0.6,1-exp(-delta*5))
	hum.volume_db=-32+speed_ratio*12+(game.player.thrust_level*3 if active else 0)
	hum.stream_paused=not active and game.state!="menu"
	if is_instance_valid(boost_audio):
		boost_mix=lerpf(boost_mix,1.0 if active and game.player.boosting else 0.0,1-exp(-delta*10))
		boost_audio.volume_db=-80 if boost_mix<0.005 else -20+linear_to_db(boost_mix)
		boost_audio.pitch_scale=1+speed_ratio*0.2
		boost_audio.stream_paused=not active and game.state!="menu"
	alarm.volume_db=-16 if active and game.reactor_down else -80
	warning_time-=delta
	if active and game.player.shield<game.player.shield_max*0.25 and warning_time<=0:
		warning_time=1.8
		play_tone("warning",0.22)
	for player in get_tree().get_nodes_in_group("transient_audio"): player.stream_paused=player.get_meta("source_bus",player.bus)!="Interface" and not active and game.state!="menu"
	for player in get_tree().get_nodes_in_group("ambient_loops"): player.stream_paused=not active and game.state!="menu"

func category(kind: String) -> String:
	if kind in ["laser","plasma","rail","enemy","missile","charge"]: return "Weapons"
	if kind in ["blast","relay","hit","shield_hit"]:
		impact_duck=0.3
		return "Impacts"
	if kind in ["ui","pickup","hurt","warning"]: return "Interface"
	return "Ambience"
func limit_voices(bus: String) -> void:
	var voices=get_tree().get_nodes_in_group("mix_"+bus)
	var cap=20 if bus=="Weapons" else (10 if bus=="Impacts" else 8)
	if voices.size()>=cap:
		voices[0].remove_from_group("mix_"+bus)
		voices[0].stop(); voices[0].queue_free()

func set_mix_gain(bus: String,value: float) -> void:
	var gain=value+(0.0 if bus=="Music" else linear_to_db(maxf(effects_volume,0.0001)))
	if not mix_gains.has(bus) or not is_equal_approx(mix_gains[bus],gain):
		mix_gains[bus]=gain
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus),gain)
