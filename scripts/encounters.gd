extends RefCounted
const Hazard=preload("res://scripts/hazard.gd")
const Forge=preload("res://scripts/forge.gd")
var game
var hazards: Array=[]
var ambush_state="dormant"
var ambush_timer=0.0
var challenge_state="ready"
var wave=0
var wave_ids: Array=[]
var wave_timer=0.0
var interact_progress=0.0
var console_pos=Vector3.ZERO
var console_label: Label3D
var challenge_node: Node3D
var ambush_pos=Vector3.ZERO
var beacons: Array=[]
func _init(owner): game=owner
func build() -> void:
	var layouts=[[[47,0,-41,"coolant"],[-48,-43,-39,"arc"],[8,2,-88,"machine"]],[[5,47,-94,"coolant"],[-59,1,-45,"arc"],[7,0,-89,"machine"]],[[18,0,-100,"arc"],[57,-40,-20,"coolant"],[-57,1,-28,"machine"]]]
	for item in layouts[game.mission_index]:
		var h=Hazard.new(); h.game=game; h.kind=item[3]; h.hazard_id=hazards.size(); game.level.add_child(h); h.position=Vector3(item[0],item[1],item[2]); hazards.append(h)
	ambush_pos=[Vector3(43,0,-44),Vector3(0,47,-48),Vector3(0,0,-100)][game.mission_index]
	game.spawn_pickup(game.targets[3].pos+Vector3(-7,0,5),"energy")
	game.spawn_pickup(game.secret_center+Vector3(3,0,0),"energy")
	console_pos=game.secret_center+Vector3(0,0,-5)
	challenge_node=Node3D.new(); game.level.add_child(challenge_node); challenge_node.position=console_pos
	Forge.box(challenge_node,Vector3.ZERO,Vector3(2.6,1.3,1),Color("3e405b"))
	Forge.box(challenge_node,Vector3(0,0.3,0.55),Vector3(2.2,0.6,0.1),Color("b299ff"),1.1)
	console_label=Forge.sign_text(challenge_node,Vector3(0,2,0),"OPTIONAL / COMBAT TRIAL",20,Color("b299ff"))
	console_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
func update(delta: float) -> void:
	if game.reactor_down:
		for beacon in beacons:
			if is_instance_valid(beacon): beacon.queue_free()
		beacons.clear()
		if ambush_state=="warning": ambush_state="complete"
		if challenge_state!="cleared": console_label.text="TRIAL CLOSED / EVACUATE"
		return
	if ambush_state=="dormant" and game.mission_time>8 and game.player.position.distance_to(ambush_pos)<15:
		ambush_state="warning"; ambush_timer=2
		game.announce("RESPONSE TEAM / INCOMING IN TWO SECONDS",3)
		show_arrival()
	elif ambush_state=="warning":
		ambush_timer-=delta
		if ambush_timer<=0:
			ambush_state="complete"
			for beacon in beacons: if is_instance_valid(beacon): beacon.queue_free()
			beacons.clear()
			for i in range(2):
				var d=game.spawn_drone(ambush_pos+Vector3(-5 if i==0 else 5,3 if i==0 else -3,-5),"scout" if i==0 else "striker")
				d.alert_time=5; d.last_seen=game.player.position; d.cooldown=1.5+i*0.7
	var nearby=not game.systems.interacting and not game.exploration.interacting and game.is_secret_open() and game.player.position.distance_to(console_pos)<5
	if challenge_state=="ready":
		if nearby:
			console_label.text="HOLD "+game.controls.label("interact")+" / BEGIN TWO-WAVE TRIAL"
			if game.controls.held("interact"): interact_progress+=delta
			else: interact_progress=maxf(0,interact_progress-delta)
			if interact_progress>=2: start_challenge()
	elif challenge_state=="active":
		var alive=false
		for d in game.drones:
			if not d.dead and d.spawn_id in wave_ids: alive=true
		if not alive:
			wave_timer-=delta
			if wave_timer<=0:
				if wave<2: spawn_wave()
				else: clear_challenge()
		console_label.text="COMBAT TRIAL / WAVE %d OF 2" % wave
func show_arrival() -> void:
	for beacon in beacons:
		if is_instance_valid(beacon): beacon.queue_free()
	beacons.clear()
	for offset in [Vector3(-5,3,-5),Vector3(5,-3,-5)]:
		beacons.append(Forge.ring(game,ambush_pos+offset,1.5,0.07,Color("ff9e75"),2))

func start_challenge() -> void:
	if challenge_state!="ready": return
	challenge_state="active"; console_label.hide(); wave=0; spawn_wave()
	game.announce("OPTIONAL COMBAT TRIAL / TWO WAVES / RETREAT IS OPEN",4)
	game.store_checkpoint()
func spawn_wave() -> void:
	wave+=1; wave_ids.clear(); wave_timer=2
	var roles=["scout","striker"] if wave==1 else (["warden"] if game.mission_index==2 else ["striker","bulwark"])
	for i in range(roles.size()):
		var pos=game.secret_center+Vector3(-5 if i==0 else 5,2 if i==0 else -2,2)
		var d=game.spawn_drone(pos,roles[i]); d.cooldown=1.8+i*0.6; d.alert_time=6; d.last_seen=game.player.position; wave_ids.append(d.spawn_id)
	game.announce("WARDEN / VAULT GUARDIAN" if roles[0]=="warden" else "COMBAT TRIAL / WAVE %d OF 2" % wave,3)
func clear_challenge() -> void:
	if challenge_state=="cleared": return
	challenge_state="cleared"; console_label.show(); console_label.text="COMBAT TRIAL / CLEARED"
	game.score+=1500 if game.mission_index==2 else 1000
	game.player.shield=minf(game.player.shield_max,game.player.shield+25)
	game.player.energy=minf(100,game.player.energy+40); game.player.missiles+=3
	game.announce("TRIAL CLEARED / REPAIR +25 / MISSILES +3 / BONUS SALVAGE ON EXTRACTION",5)
	game.store_checkpoint()
func attack_allowed(drone) -> bool:
	var attackers=0
	for other in game.drones:
		if other!=drone and not other.dead and other.position.distance_to(drone.position)<35 and other.attack_state in ["charging","burst"]: attackers+=1
	return attackers<2
func alert_squad(observer) -> void:
	for other in game.drones:
		if other!=observer and not other.dead and other.position.distance_to(observer.position)<25 and game.clear_line(observer.position,other.position):
			other.alert_time=maxf(other.alert_time,4); other.last_seen=game.player.position
func snapshot() -> Dictionary:
	var state={"ambush":ambush_state,"ambush_timer":ambush_timer,"challenge":challenge_state,"wave":wave,"wave_ids":wave_ids.duplicate(),"wave_timer":wave_timer,"hazards":[]}
	for h in hazards: state.hazards.append({"health":h.health,"destroyed":h.destroyed})
	return state
func restore(state: Dictionary) -> void:
	ambush_state=str(state.get("ambush","dormant")); ambush_timer=float(state.get("ambush_timer",0))
	if ambush_state=="warning": show_arrival()
	challenge_state=str(state.get("challenge","ready")); wave=clampi(int(state.get("wave",0)),0,2); wave_ids=state.get("wave_ids",[]).duplicate(); wave_timer=float(state.get("wave_timer",2))
	console_label.visible=challenge_state!="active"
	if challenge_state=="cleared": console_label.text="COMBAT TRIAL / CLEARED"
	for i in range(mini(hazards.size(),state.get("hazards",[]).size())): hazards[i].restore(state.hazards[i])
