extends CharacterBody3D
const Forge = preload("res://scripts/forge.gd")
var game: Node3D
var role = "scout"
var spawn_id=0
var health = 48.0
var max_health = 48.0
var home = Vector3.ZERO
var clock = 0.0
var cooldown = 2.0
var visual: Node3D
var flight_state: Node
var elite = false
var dead = false
var charge = 0.0
var attack_state = "idle"
var attack_timer = 0.0
var shots_left = 0
var speed = 6.5
var ideal_range = 12.0
var last_seen = Vector3.ZERO
var alert_time = 0.0
var eye: MeshInstance3D
var eye_light: OmniLight3D
var hit_flash = 0.0
var armor_ping = 0.0
var tactical_state="patrol"
var patrol_index=0
var decision_timer=0.0
var squad_timer=0.0
var retreat_timer=0.0
var retreat_used=false
var visible_target=false
var move_target=Vector3.ZERO
var cover_goal=Vector3.ZERO
var enraged=false

func _ready() -> void:
	match role:
		"scout": max_health=48; speed=6.5; ideal_range=12
		"striker": max_health=78; speed=4.8; ideal_range=17
		"bulwark": max_health=150; speed=2.8; ideal_range=21
		"warden": max_health=460; speed=3.2; ideal_range=10
	health = max_health
	elite = role in ["bulwark","warden"]
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var c = CollisionShape3D.new()
	var s = SphereShape3D.new()
	s.radius = 1.15 if elite else 0.95
	c.shape = s
	add_child(c)
	visual = Node3D.new()
	add_child(visual)
	var color = Color("ff7758") if role=="scout" else (Color("cba4ff") if role=="striker" else Color("ffbf70"))
	var model=load("res://assets/models/"+role+".glb").instantiate()
	visual.add_child(model)
	preload("res://scripts/ship_visuals.gd").attach(model,role,color)
	flight_state=preload("res://scripts/flight_state.gd").new(); flight_state.setup(game,self,model,role)
	if role=="warden": model.scale=Vector3.ONE*1.1
	eye=Forge.sphere(visual,Vector3(0,0,-1.02),0.15,color,1.2)
	eye_light=Forge.light(visual,Vector3(0,0,-1.1),color,0.4,4)
	home = position
	clock = randf()*TAU
	cooldown = randf_range(1.1,2.4)

func _physics_process(delta: float) -> void:
	if game.state != "playing" or game.map_open or dead: return
	clock+=delta; cooldown-=delta; decision_timer-=delta; squad_timer-=delta
	retreat_timer=maxf(0,retreat_timer-delta)
	hit_flash=maxf(0,hit_flash-delta*5); armor_ping=maxf(0,armor_ping-delta*3)
	if decision_timer<=0:
		decision_timer=0.15
		decide_target(0.15)
	var move_dir=(move_target-global_position).limit_length()
	if not game.clear_line(global_position,global_position+move_dir*2.4):
		var side=move_dir.cross(Vector3.UP).normalized()
		if side.is_zero_approx(): side=Vector3.RIGHT
		for alternative in [side,-side,Vector3.UP,Vector3.DOWN]:
			if game.clear_line(global_position,global_position+alternative*2.4): move_dir=alternative; break
	var separation=Vector3.ZERO
	for other in game.drones:
		if other==self or other.dead: continue
		var offset=position-other.position
		if offset.length()>0.05 and offset.length()<3: separation+=offset.normalized()*(1-offset.length()/3)
	move_dir=(move_dir+separation*0.65).limit_length()
	velocity=velocity.lerp(move_dir*(speed*(1.2 if enraged else 1) if alert_time>0 else 1.7),1-exp(-delta*3))
	move_and_slide()
	var to_player=game.player.global_position-global_position
	var face=game.player.global_position if alert_time>0 else global_position+velocity
	if face.distance_to(global_position)>0.1:
		var direction=(face-global_position).normalized()
		visual.look_at(face,Vector3.UP if absf(direction.y)<0.95 else Vector3.RIGHT)
	visual.rotate_object_local(Vector3.BACK,sin(clock*2)*0.06)
	update_attack(delta,visible_target and tactical_state!="retreat")
	eye.scale=Vector3.ONE*(1+charge*0.5+hit_flash*0.3)
	eye_light.light_energy=0.3+charge*2+hit_flash
func decide_target(delta: float) -> void:
	var to_player=game.player.position-position
	visible_target=to_player.length()<46 and game.clear_line(position,game.player.position)
	if visible_target:
		last_seen=game.player.position; alert_time=4
		if squad_timer<=0:
			squad_timer=0.7; game.director.alert_squad(self)
	else: alert_time=maxf(0,alert_time-delta)
	if role=="warden" and not enraged and health<max_health*0.5:
		enraged=true; cooldown=0.6
		game.announce("WARDEN / OVERDRIVE / KEEP MOVING",3)
	if health<max_health*0.3 and role!="warden" and visible_target and not retreat_used:
		retreat_used=true; retreat_timer=3.8; cover_goal=find_cover(to_player)
	if retreat_timer>0:
		tactical_state="retreat"; move_target=cover_goal
	elif visible_target:
		var forward=to_player.normalized()
		var side=forward.cross(Vector3.UP).normalized()
		if side.is_zero_approx(): side=Vector3.RIGHT
		var polarity=1 if spawn_id%2 else -1
		tactical_state="flank" if role=="scout" else "crossfire"
		move_target=game.player.position-forward*ideal_range+side*polarity*(6 if role=="scout" else 4)+Vector3.UP*sin(clock*0.8)*2
	elif alert_time>0:
		tactical_state="search"; move_target=last_seen
	else:
		tactical_state="patrol"
		var patrol=[Vector3(3,1,0),Vector3(0,-1,-3),Vector3(-3,1,0),Vector3(0,0,3)]
		if position.distance_to(home+patrol[patrol_index])<1: patrol_index=(patrol_index+1)%4
		move_target=home+patrol[patrol_index]
func find_cover(to_player: Vector3) -> Vector3:
	var fallback=home-to_player.normalized()*4
	for offset in [Vector3(6,0,0),Vector3(-6,0,0),Vector3(0,3,6),Vector3(0,-3,-6)]:
		var point=position+offset
		if game.clear_line(position,point) and not game.clear_line(game.player.position,point): return point
	return fallback

func update_attack(delta: float,visible: bool) -> void:
	if not visible:
		attack_state="idle"
		charge=0
		return
	attack_timer -= delta
	match attack_state:
		"idle":
			if cooldown<=0 and game.director.attack_allowed(self):
				attack_state="charging"
				attack_timer=0.95 if role=="warden" else (0.75 if elite else 0.55)
				game.sound.play_at("charge",global_position,0.25)
		"charging":
			charge = clampf(charge+delta*2,0,1)
			if attack_timer<=0:
				attack_state="burst"
				shots_left=3 if role=="striker" else 1
				attack_timer=0
		"burst":
			if attack_timer<=0:
				var victim=attack_target()
				var prediction = victim.velocity*(clampf(global_position.distance_to(victim.position)/25.0,0.15,0.9) if role=="striker" else 0.08)
				var dir = (victim.position+prediction-global_position).normalized()
				if role=="warden":
					if enraged:
						for i in range(8): game.enemy_shot(global_position,Vector3(cos(i*TAU/8),sin(clock)*0.3,sin(i*TAU/8)).normalized(),16,8,Color("d4a6ff"))
					else:
						for angle in [-0.18,0.0,0.18]: game.enemy_shot(global_position,game.spread_direction(dir,angle),18,10,Color("d4a6ff"))
				elif elite:
					for angle in [-0.12,0.0,0.12]: game.enemy_shot(global_position,game.spread_direction(dir,angle),15,12,Color("ffbf70"))
				else: game.enemy_shot(global_position,dir,25 if role=="striker" else 22,7 if role=="scout" else 8,Color("cba4ff") if role=="striker" else Color("ff7758"))
				shots_left-=1
				attack_timer=0.17
				charge=0
				if shots_left<=0:
					attack_state="idle"
					cooldown=(1.9 if enraged else 2.6) if role=="warden" else (2.8 if elite else (2.4 if role=="striker" else 1.9))

func hit(damage: float,source: Vector3 = Vector3.INF,explosive: bool = false) -> void:
	if dead: return
	if elite and not explosive and source.is_finite() and (-visual.global_basis.z).dot((source-global_position).normalized())>0.6:
		damage *= 0.45
		armor_ping=1
		game.announce("ARMORED FRONT / FLANK, PLASMA, RAIL OR MISSILES",1.5)
	game.combat_stats.damage_dealt+=minf(health,damage)
	alert_time=5
	if source.is_finite(): last_seen=source
	flight_state.flash(source)
	health -= damage
	hit_flash=1
	game.impact(global_position,Color("ffb067"),5)
	if health<=0:
		dead=true
		collision_layer=0
		game.kills+=1
		game.kill_confirm=1
		game.score+=1200 if role=="warden" else (250 if elite else (150 if role=="striker" else 100))
		game.flight_fx.breakup(flight_state.hull,role,velocity)
		game.explosion(global_position,Color("ff9561"),1.5)
		if game.kills%3==0: game.spawn_pickup(global_position,"shield")
		elif game.kills%2==0: game.spawn_pickup(global_position,"energy")
		game.drones.erase(self)
		queue_free()

func attack_target():
	var courier=game.exploration.escort
	if is_instance_valid(courier) and courier.status in ["following","waiting"] and spawn_id%3==0 and position.distance_to(courier.position)<30 and game.clear_line(position,courier.position): return courier
	return game.player
