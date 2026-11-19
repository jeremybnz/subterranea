extends CharacterBody3D
const Forge=preload("res://scripts/forge.gd")
var game: Node3D
var role="overseer"
var elite=false
var dead=false
var max_health=1500.0
var health=1500.0
var phase=1
var charge=0.0
var alert_time=0.0
var visual: Node3D
var flight_state: Node
var home=Vector3.ZERO
var clock=0.0
var cooldown=2.0
var warming=0.0
var charging=false
var attack_timer=0.0
var locked_aim=Vector3.ZERO
var telegraph: MeshInstance3D
var reinforcements=false
var glow: OmniLight3D

func _ready() -> void:
	collision_layer=8
	collision_mask=1
	motion_mode=CharacterBody3D.MOTION_MODE_FLOATING
	var shape=CollisionShape3D.new()
	var sphere=SphereShape3D.new()
	sphere.radius=3.3
	shape.shape=sphere
	add_child(shape)
	visual=load("res://assets/models/overseer.glb").instantiate()
	add_child(visual)
	preload("res://scripts/ship_visuals.gd").attach(visual,"overseer",Color("ffae70"))
	flight_state=preload("res://scripts/flight_state.gd").new(); flight_state.setup(game,self,visual,"overseer")
	home=position
	glow=Forge.light(visual,Vector3(0,0,-3.7),Color("ffa367"),2.4,20)

func _physics_process(delta: float) -> void:
	if game.state!="playing" or game.map_open or dead: return
	clock+=delta
	warming=maxf(0,warming-delta)
	cooldown-=delta
	var target=home+Vector3(sin(clock*0.32)*7,sin(clock*0.47)*4,cos(clock*0.28)*3)
	velocity=(target-position).limit_length()*3
	move_and_slide()
	var to=game.player.position-position
	if to.length()>0.1: visual.look_at(game.player.position,Vector3.UP if absf(to.normalized().y)<0.97 else Vector3.RIGHT)
	alert_time=3 if to.length()<70 else 0
	game.targets[3].pos=position
	game.targets[3].health=health
	glow.light_energy=1.5+charge*5+warming*2
	if game.relays_down<3:
		if cooldown<=0 and to.length()<65:
			cooldown=3.2
			game.enemy_shot(position,to.normalized(),16,8,Color("ffb76b"))
		return
	if warming>0: return
	if charging:
		attack_timer-=delta
		charge=1-attack_timer/(1.15 if phase==3 else 0.8)
		if attack_timer<=0:
			fire_attack()
			charging=false
			charge=0
			cooldown=2.8 if phase==1 else (2.4 if phase==2 else 1.9)
	elif cooldown<=0 and to.length()<75:
		charging=true
		attack_timer=1.15 if phase==3 else 0.8
		locked_aim=game.player.position+game.player.velocity*0.16
		game.sound.play_at("charge",position,0.65)
		if phase==3:
			telegraph=Forge.beam(game,position,locked_aim,0.07,Color("ff5d54"),1.5)
			game.effects.append({"node":telegraph,"life":1.15,"max":1.15,"velocity":Vector3.ZERO,"expand":false,"keep_scale":true})

func fire_attack() -> void:
	var direction=(game.player.position-position).normalized()
	if phase==1:
		for angle in [-0.18,0.0,0.18]: game.enemy_shot(position,game.spread_direction(direction,angle),20,11,Color("ffae65"))
	elif phase==2:
		for i in range(12):
			var angle=i*TAU/12+clock*0.2
			var dir=Vector3(cos(angle),sin(angle)*0.45,sin(angle)).normalized()
			game.enemy_shot(position,dir,16,9,Color("ff6e58"))
	else:
		var from=position
		var end=from+(locked_aim-from).normalized()*90
		var ray=PhysicsRayQueryParameters3D.create(from,end,1|2)
		var hit=get_world_3d().direct_space_state.intersect_ray(ray)
		if hit:
			end=hit.position
			if hit.collider==game.player: game.player.hurt(26,from)
		var beam=Forge.beam(game,from,end,0.22,Color("ff865a"),3)
		game.effects.append({"node":beam,"life":0.17,"max":0.17,"velocity":Vector3.ZERO,"expand":false,"keep_scale":true})
		game.sound.play_at("blast",position,0.7)

func change_phase(next: int) -> void:
	phase=next
	warming=1.4
	charging=false
	charge=0
	cooldown=0.5
	game.announce("OVERSEER / PHASE %d  /  %s" % [phase,"RADIAL SALVO" if phase==2 else "DODGE THE TARGETING BEAM"],4)
	game.explosion(position,Color("ffb76b"),2)
	if phase==2 and not reinforcements:
		reinforcements=true
		for offset in [Vector3(-12,5,0),Vector3(12,-5,0)]: game.spawn_drone(home+offset,"scout")

func hit(amount: float,_source: Vector3 = Vector3.INF,explosive: bool = false) -> void:
	if dead: return
	flight_state.flash(_source)
	if game.relays_down<3:
		game.announce("OVERSEER SHIELDED / DESTROY THREE SHIELD NODES",2)
		return
	if warming>0: return
	if explosive: amount*=0.7
	game.combat_stats.damage_dealt+=minf(health,amount)
	health=maxf(0,health-amount)
	if phase==1 and health<=1000:
		health=1000
		change_phase(2)
	elif phase==2 and health<=500:
		health=500
		change_phase(3)
	game.targets[3].health=health
	game.hit_confirm=1
	game.impact(position,Color("ffb16f"),8)
	if health<=0:
		dead=true
		collision_layer=0
		game.flight_fx.breakup(visual,"overseer",velocity)
		hide()
		game.targets[3].alive=false
		game.score+=3000
		game.explosion(position,Color("ffb76b"),6)
		game.begin_escape("OVERSEER DESTROYED / FORTRESS COLLAPSE / RETURN TO DOCK")
