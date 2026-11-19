extends CharacterBody3D
const Forge = preload("res://scripts/forge.gd")
var game: Node3D
var camera: Camera3D
var cockpit: Node3D
var exterior: Node3D
var flight_state: Node
var chase_enabled=false
var chase_obstructed=false
var chase_distance=2.8
var thrust_level=0.0
const EXTERIOR_SCALE=0.19
var sensitivity = 0.0022
var base_fov=83.0
var controller_rate=1.8
var shield = 100.0
var shield_max=100.0
var engine_factor=1.0
var cannon_damage=18.0
var cannon_interval=0.135
var missile_damage=110.0
var primary_weapon=0
var rail_charge=0.0
var energy = 100.0
var missiles = 8
var boost = 100.0
var fire_timer = 0.0
var missile_timer = 0.0
var damage_flash = 0.0
var damage_direction = Vector3.ZERO
var recoil = 0.0
var shake_enabled = true
var flight_assist = true
var invert_mouse = false
var boosting = false
var braking = false
var visual_bank = 0.0
var muzzle_time = 0.0
var collision_cooldown = 0.0
var lamp: SpotLight3D
var muzzle_light: OmniLight3D
var muzzle_flashes: Array = []
var strafe_input = 0.0
var gun_parts: Array=[]
var paint_trims: Array=[]
const CRUISE_SPEED = 12.5
const BOOST_SPEED = 25.0
const ACCELERATION = 38.0
const BRAKING = 24.0

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	var collider = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.65
	collider.shape = shape
	add_child(collider)
	camera = Camera3D.new()
	camera.fov = 83
	camera.near = 0.08
	add_child(camera)
	camera.current = true
	var listener=AudioListener3D.new()
	camera.add_child(listener)
	listener.make_current()
	lamp = SpotLight3D.new()
	lamp.light_color = Color("b9e8f3")
	lamp.light_energy = 3.0
	lamp.spot_range = 48
	lamp.spot_angle = 48
	add_child(lamp)
	build_cockpit()
	exterior=load("res://assets/models/kestrel.glb").instantiate(); add_child(exterior); exterior.scale=Vector3.ONE*EXTERIOR_SCALE; exterior.hide()
	preload("res://scripts/ship_visuals.gd").attach(exterior,"kestrel")
	Forge.light(exterior,Vector3(0,3,1),Color("a5d6eb"),0.7,12)
	flight_state=preload("res://scripts/flight_state.gd").new(); flight_state.setup(game,self,exterior,"kestrel")

func build_cockpit() -> void:
	cockpit = Node3D.new()
	camera.add_child(cockpit)
	for side in [-1,1]:
		var pod=load("res://assets/models/cockpit_gun.glb").instantiate(); cockpit.add_child(pod); pod.position=Vector3(side*0.72,-0.52,-1.28)
		pod.rotation.z = side*-0.1
		var trim=Forge.box(cockpit,Vector3(side*0.72,-0.39,-1.45),Vector3(0.06,0.025,0.55),Color("5dc4c1"),0.75)
		trim.material_override=trim.material_override.duplicate(); paint_trims.append(trim)
		var coil=Forge.ring(cockpit,Vector3(side*0.72,-0.52,-1.7),0.13,0.025,Color("76e9df"),1)
		coil.rotation.x=PI/2; coil.material_override=coil.material_override.duplicate()
		gun_parts.append({"pod":pod,"coil":coil,"side":side})
		var flash_mesh = Forge.sphere(cockpit,Vector3(side*0.72,-0.52,-1.96),0.13,Color("8affea"),2.3)
		flash_mesh.hide()
		muzzle_flashes.append(flash_mesh)
		Forge.beam(cockpit,Vector3(side*1.1,-0.82,-0.85),Vector3(side*0.85,-0.15,-0.93),0.055,Color("1a2d37"))
		Forge.beam(cockpit,Vector3(side*0.85,-0.15,-0.93),Vector3(side*0.99,0.5,-1.14),0.028,Color("263d47"))
		var screen = Forge.box(cockpit,Vector3(side*0.46,-0.62,-0.9),Vector3(0.23,0.13,0.025),Color("16323b"),0.25)
		screen.rotation.x = -0.32
		for i in range(5):
			Forge.box(cockpit,Vector3(side*0.46-0.085+i*0.04,-0.6,-0.87),Vector3(0.022,0.009+0.007*(i%3),0.008),Color("77ddd0"),0.8)
		for i in range(3): Forge.box(cockpit,Vector3(side*(0.58+i*0.04),-0.67,-0.84),Vector3(0.02,0.018,0.02),Color("dca362"),0.5)
	Forge.box(cockpit,Vector3(0,-0.73,-0.82),Vector3(0.9,0.12,0.15),Color("122732"))
	Forge.beam(cockpit,Vector3(-0.4,-0.66,-0.87),Vector3(0.4,-0.66,-0.87),0.009,Color("65c2bb"),0.7)
	muzzle_light = Forge.light(camera,Vector3(0,-0.3,-2),Color("89ffed"),0,5)

func _unhandled_input(event: InputEvent) -> void:
	if game.state != "playing" or game.map_open: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_object_local(Vector3.UP,-event.relative.x*sensitivity)
		rotate_object_local(Vector3.RIGHT,event.relative.y*sensitivity*(1 if invert_mouse else -1))
		transform.basis = transform.basis.orthonormalized()

func axis(positive: Key,negative: Key) -> float:
	return float(Input.is_physical_key_pressed(positive))-float(Input.is_physical_key_pressed(negative))

func flash_muzzles() -> void:
	muzzle_time = 0.045
	var color=game.arsenal.COLORS[primary_weapon]
	for mesh in muzzle_flashes:
		mesh.material_override=Forge.material(color,2.3)
		mesh.show()
	muzzle_light.light_color=color
	muzzle_light.light_energy = 2.3

func _physics_process(delta: float) -> void:
	if game.state != "playing" or game.map_open: return
	fire_timer = maxf(0,fire_timer-delta)
	missile_timer = maxf(0,missile_timer-delta)
	collision_cooldown = maxf(0,collision_cooldown-delta)
	damage_flash = maxf(0,damage_flash-delta*1.7)
	recoil = move_toward(recoil,0,delta*6)
	muzzle_time = maxf(0,muzzle_time-delta)
	if muzzle_time<=0:
		for mesh in muzzle_flashes: mesh.hide()
		muzzle_light.light_energy = 0
	energy = minf(100,energy+delta*(8+game.campaign.level("cannons")))
	var c=game.controls
	var look=Vector2(c.axis("look_left","look_right"),c.axis("look_up","look_down"))
	if look.length()>0:
		rotate_object_local(Vector3.UP,-look.x*controller_rate*delta)
		rotate_object_local(Vector3.RIGHT,look.y*controller_rate*delta*(1 if invert_mouse else -1))
	var thrust=Vector3(c.axis("left","right"),c.axis("down","up"),c.axis("forward","reverse"))
	strafe_input = thrust.x
	thrust_level=thrust.length()
	braking = c.held("brake")
	boosting = not braking and c.held("boost") and boost>2 and thrust.length()>0
	boost = clampf(boost+delta*(-25*(1-game.campaign.level("engines")*0.1) if boosting else 19),0,100)
	var speed = (BOOST_SPEED if boosting else CRUISE_SPEED)*engine_factor
	if braking: velocity = velocity.move_toward(Vector3.ZERO,delta*65)
	elif thrust.length()>0: velocity = velocity.move_toward(global_basis*thrust.limit_length()*speed,delta*ACCELERATION*engine_factor)
	elif flight_assist: velocity = velocity.move_toward(Vector3.ZERO,delta*BRAKING)
	else: velocity *= exp(-delta*0.13)
	rotate_object_local(Vector3.BACK,c.axis("roll_right","roll_left")*delta*1.65)
	transform.basis = transform.basis.orthonormalized()
	var before = velocity
	move_and_slide()
	if get_slide_collision_count()>0 and before.length()>10 and collision_cooldown<=0:
		var impact_speed = absf(before.dot(get_slide_collision(0).get_normal()))
		if impact_speed>9:
			collision_cooldown = 0.7
			hurt(minf(10,(impact_speed-8)*0.45),get_slide_collision(0).get_position())
	camera.fov = lerpf(camera.fov,minf(120,base_fov+12) if boosting else base_fov,1-exp(-delta*5))
	visual_bank = lerpf(visual_bank,-thrust.x*0.045,1-exp(-delta*7))
	update_view(delta)
	cockpit.position = cockpit.position.lerp(Vector3(-thrust.x*0.025,-thrust.y*0.02,recoil*0.05),1-exp(-delta*10))
	for part in gun_parts:
		part.pod.position.z=-1.28+recoil*0.12
		part.coil.position.z=-1.7+recoil*0.08+rail_charge*0.13
		part.coil.rotate_object_local(Vector3.UP,delta*(2 if primary_weapon==1 else 0.4))
		part.coil.scale=Vector3.ONE*(1+rail_charge*0.22)
		part.coil.material_override.albedo_color=game.arsenal.COLORS[primary_weapon]
		part.coil.material_override.emission=game.arsenal.COLORS[primary_weapon]
	for trim in paint_trims:
		trim.material_override.albedo_color=game.exploration.paint().accent
		trim.material_override.emission=game.exploration.paint().accent
	game.arsenal.update(delta)
	if c.held("missile") and missile_timer<=0 and missiles>0:
		missile_timer = 0.7
		missiles -= 1
		recoil = 1.5
		game.fire_missile()

func hurt(amount: float,source: Vector3 = Vector3.INF) -> void:
	if game.state != "playing" or game.map_open: return
	if game.training_mode: amount=0
	amount*=[0.65,1.0,1.3][game.difficulty]
	game.combat_stats.damage_taken+=minf(shield,amount)
	shield = maxf(0,shield-amount)
	damage_flash = 0.8
	if source.is_finite(): damage_direction = (source-global_position).normalized()
	if amount>0: flight_state.flash(source)
	game.sound.play_tone("hurt",0.4)
	if shield<=0:
		game.flight_fx.breakup(exterior,"kestrel",velocity)
		exterior.hide(); cockpit.hide(); game.explosion(position,Color("ffb76b"),1.5)
		game.finish(false,"SHIP LOST","Your signal went dark in the Nereid complex.")

func apply_upgrades() -> void:
	shield_max=100+game.campaign.level("shields")*25
	shield=shield_max
	engine_factor=1+game.campaign.level("engines")*0.1
	cannon_damage=18+game.campaign.level("cannons")*4
	cannon_interval=0.135*(1-game.campaign.level("cannons")*0.06)
	missile_damage=110+game.campaign.level("missiles")*25
	missiles=8+game.campaign.level("missiles")*2

func toggle_view() -> void:
	chase_enabled=not chase_enabled; chase_distance=2.8; rail_charge=0
	if game.state in ["playing","paused"]: update_view(0)
	game.save_settings()
	game.hud.rebuild_menu()
func update_view(delta: float) -> void:
	var offset=Vector3.ZERO
	chase_obstructed=false
	if chase_enabled:
		var target=Vector3(0,0.55,3.25 if boosting else 2.8)
		var anchor=global_position+global_basis*Vector3(0,0.2,0)
		var end=global_position+global_basis*target
		var query=PhysicsShapeQueryParameters3D.new(); var sphere=SphereShape3D.new(); sphere.radius=0.25
		query.shape=sphere; query.transform=Transform3D(Basis.IDENTITY,anchor); query.motion=end-anchor; query.collision_mask=1
		var motion=get_world_3d().direct_space_state.cast_motion(query)
		var safe=maxf(0,(end-anchor).length()*motion[0]-0.08)
		var desired=(end-anchor).length()
		chase_distance=minf(safe,lerpf(chase_distance,desired,1-exp(-delta*7))) if delta>0 else safe
		chase_obstructed=chase_distance<1.05
		if not chase_obstructed: offset=Vector3(0,0.2,0)+(target-Vector3(0,0.2,0)).normalized()*chase_distance
	var external=chase_enabled and not chase_obstructed
	exterior.visible=external and game.state in ["playing","paused"]
	cockpit.visible=not external and game.state in ["playing","paused"]
	camera.rotation=Vector3(0,0,visual_bank*0.4 if external else visual_bank)
	var shake=Vector3(randf_range(-1,1),randf_range(-1,1),0)*damage_flash*(0.018 if external else 0.035) if shake_enabled else Vector3.ZERO
	camera.position=offset+shake
	if not external: camera.position.z=recoil*0.045
func weapon_origin() -> Vector3:
	return global_position if chase_enabled else camera.global_position
func aim_direction() -> Vector3:
	if not chase_enabled: return -camera.global_basis.z
	var from=camera.global_position; var end=from-camera.global_basis.z*200
	var query=PhysicsRayQueryParameters3D.create(from,end,1|4|8|16)
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit: end=hit.position
	# A surface between camera and pilot must never turn fire backwards.
	var direction=(end-weapon_origin()).normalized()
	return direction if direction.dot(-global_basis.z)>0.05 else -global_basis.z
func muzzle_position(side: int) -> Vector3:
	return global_position+global_basis*Vector3(side*0.28,-0.04,-0.53) if chase_enabled and not chase_obstructed else camera.global_position+global_basis*Vector3(side*0.65,-0.4,-1.7)
