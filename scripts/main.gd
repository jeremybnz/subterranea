extends Node3D
const Forge = preload("res://scripts/forge.gd")
const Pilot = preload("res://scripts/player.gd")
const Drone = preload("res://scripts/drone.gd")
const Interface = preload("res://scripts/hud.gd")
const Sound = preload("res://scripts/sound.gd")
const Mine = preload("res://scripts/mine.gd")
const Progress=preload("res://scripts/campaign.gd")
const Operations=preload("res://scripts/operations.gd")
const Bindings=preload("res://scripts/controls.gd")
const School=preload("res://scripts/training.gd")
const Arsenal=preload("res://scripts/arsenal.gd")
const Encounters=preload("res://scripts/encounters.gd")
const Exploration=preload("res://scripts/exploration.gd")
const Atmosphere=preload("res://scripts/atmosphere.gd")
const Profiles=preload("res://scripts/profiles.gd")
const Survey=preload("res://scripts/automap.gd")
const Systems=preload("res://scripts/systems.gd")
const Ratings=preload("res://scripts/ratings.gd")
const Batch=preload("res://scripts/static_batch.gd")
const CYAN = Color("66e4dc")
const AMBER = Color("ffb76b")
var state = "menu"
var player: CharacterBody3D
var sound: Node
var hud: Control
var level: Node3D
var menu_ship: Node3D
var drones: Array = []
var targets: Array = []
var pickups: Array = []
var projectiles: Array = []
var effects: Array = []
var relays_down = 0
var kills = 0
var score = 0
var mission_time = 0.0
var escape_time = 75.0
var reactor_down = false
var core_door: Node3D
var notice = ""
var notice_time = 0.0
var end_title = ""
var end_detail = ""
var map_open = false
var clock = 0.0
var flash = 0.0
var hit_confirm = 0.0
var total_drones = 0
var doors: Array = []
var reactor_doors: Array = []
var secret_door: Node3D
var secret_found = false
var map_rooms: Array = []
var map_links: Array = []
var machinery: Array = []
var ambient_sources: Array = []
var kill_confirm = 0.0
var nav_hint: Dictionary = {}
var visited: Dictionary = {}
var navigation_time = 0.0
var aim_name = ""
var aim_health = 0.0
var aim_max = 1.0
var seeker_lock = false
var campaign: RefCounted
var profile_store: RefCounted
var survey: RefCounted
var systems: RefCounted
var rating={}
var flight_fx: RefCounted
var hit_feedback: RefCounted
var mission_index=0
var depth=2840
var extraction=Vector3(0,0,11)
var secret_center=Vector3(-83,-43,-44)
var secret_extent=Vector3(9,6,9)
var nav_nodes: Dictionary=NAV_NODES.duplicate(true)
var nav_edges: Array=NAV_EDGES.duplicate(true)
var nav_titles: Dictionary=NAV_TITLES.duplicate(true)
var nav_goals: Array=["foundry","pump","upper"]
var locked_nav_edges: Array=[["access","core"],["core","loop"]]
var boss: Node3D
var run_token=""
var reward=0
var result_recorded=false
var checkpoint_time=20.0
var save_notice=0.0
var interaction_target=-1
var interaction_progress=0.0
var next_drone_id=0
var release_verification=false
var controls: RefCounted
var training_mode=false
var training: RefCounted
var hud_scale=1.0
var graphics_preset=1
var difficulty=1
var environment: Environment
var batch_stats={}
var startup_ms=0.0
var aim_timer=0.0
var exploration: RefCounted
var arsenal: RefCounted
var director: RefCounted
var combat_stats={"shots":{"pulse":0,"plasma":0,"rail":0,"missile":0},"enemy_shots":0,"damage_dealt":0.0,"damage_taken":0.0,"hazard_damage":0.0,"pickups":0}

func _ready() -> void:
	var boot=Time.get_ticks_usec()
	randomize()
	controls=Bindings.new()
	training_mode=bool(get_tree().root.get_meta("training_requested",false)) or "--verify-training" in OS.get_cmdline_user_args()
	get_tree().root.set_meta("training_requested",false)
	release_verification="--verify-release" in OS.get_cmdline_user_args()
	var fixture=str(get_tree().root.get_meta("profile_fixture","")) if get_tree().root.get_meta("test_session",false) else ""
	profile_store=Profiles.new(fixture if not fixture.is_empty() else "user://",(not get_tree().root.get_meta("test_session",false) and not release_verification) or not fixture.is_empty())
	campaign=Progress.new(profile_store.current_path(),profile_store.persistent)
	campaign.load_profile()
	mission_index=clampi(int(get_tree().root.get_meta("mission_selection",campaign.data.selected)),0,2 if get_tree().root.get_meta("test_session",false) else campaign.data.unlocked)
	if release_verification:
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--verify-mission="): mission_index=clampi(int(argument.get_slice("=",1)),0,2)
	if training_mode: mission_index=0
	get_tree().auto_accept_quit=false
	flight_fx=preload("res://scripts/flight_fx.gd").new(self)
	hit_feedback=preload("res://scripts/contact_feedback.gd").new(self)
	setup_environment()
	sound = Sound.new()
	sound.game = self
	add_child(sound)
	level = Node3D.new()
	add_child(level)
	survey=Survey.new(self)
	systems=Systems.new(self)
	exploration=Exploration.new(self)
	arsenal=Arsenal.new(self)
	director=Encounters.new(self)
	build_level()
	if not training_mode:
		director.build()
		systems.build()
		Atmosphere.decorate(self)
		exploration.build()
	batch_stats=Batch.optimize(self)
	player = Pilot.new()
	player.game = self
	add_child(player)
	player.position = Vector3(0,0,8)
	if not get_tree().root.get_meta("test_session",false) and not release_verification: load_settings()
	player.apply_upgrades()
	exploration.apply_paint()
	player.cockpit.hide()
	hud = Interface.new()
	hud.game = self
	var layer = CanvasLayer.new()
	add_child(layer)
	layer.add_child(hud)
	if not training_mode: spawn_enemies()
	sound.attach_ambience()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if get_tree().root.get_meta("autodeploy",false):
		get_tree().root.set_meta("autodeploy",false)
		var resume_saved=get_tree().root.get_meta("resume_checkpoint",false)
		get_tree().root.set_meta("resume_checkpoint",false)
		call_deferred("launch",resume_saved)
	apply_graphics()
	startup_ms=(Time.get_ticks_usec()-boot)/1000.0
	if "--fleet-hangar" in OS.get_cmdline_user_args(): hud.front_view="fleet"; hud.rebuild_menu()
	if release_verification: call_deferred("verify_release")

func setup_environment() -> void:
	var world = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("08121c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8aafbd")
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("102c36")
	env.fog_density = 0.009 if mission_index==1 else 0.007
	if mission_index==1: env.fog_light_color=Color("172a47")
	elif mission_index==2: env.fog_light_color=Color("291c17")
	env.glow_enabled = true
	env.glow_intensity = 0.7
	environment=env
	world.environment = env
	add_child(world)

func build_level() -> void:
	if training_mode:
		training=School.new(self)
		training.build()
		return
	if mission_index==0: Mine.build(self)
	else: Operations.build(self,mission_index)

func make_display_ship() -> void:
	menu_ship=Node3D.new()
	level.add_child(menu_ship)
	menu_ship.position=Vector3(4,-0.5,-3)
	menu_ship.rotation=Vector3(0.12,0.45,-0.12)
	var model=load("res://assets/models/kestrel.glb").instantiate()
	menu_ship.add_child(model)
	preload("res://scripts/ship_visuals.gd").attach(model,"kestrel")
	for side in [-1,1]: Forge.light(menu_ship,Vector3(side*1.47,-0.16,1.95),CYAN,1.2,5)

func spawn_target(pos: Vector3, kind: String, title: String) -> void:
	var root = StaticBody3D.new()
	root.collision_layer = 8
	level.add_child(root)
	root.position = pos
	var c = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.4 if kind == "relay" else 3.2
	c.shape = shape
	root.add_child(c)
	var color = (Color("9dbdff") if kind in ["archive","uplink"] else CYAN) if kind!="reactor" else AMBER
	var radius = 0.9 if kind in ["relay","archive"] else (1.5 if kind=="uplink" else 2.6)
	var prompt: Label3D = null
	if kind=="archive":
		var archive=Forge.box(root,Vector3.ZERO,Vector3(1.8,2.2,1.4),Color("2c4c65"))
		for y in [-0.7,0,0.7]: Forge.box(root,Vector3(0,y,0.75),Vector3(1.4,0.12,0.05),color,1.3)
		prompt=Forge.sign_text(root,Vector3(0,-2,0),"HOLD "+controls.label("interact")+" / DOWNLOAD",23,color)
	else: Forge.sphere(root,Vector3.ZERO,radius,color,1.7)
	if kind=="uplink": prompt=Forge.sign_text(root,Vector3(0,-3,0),"HOLD "+controls.label("interact")+" / UPLOAD",26,color)
	var rings: Array = []
	for i in range(3):
		var ring = Forge.ring(root,Vector3.ZERO,radius+0.5+i*0.32,0.09,Color("425760"))
		ring.rotation = Vector3(i*0.9,i*0.8,0)
		rings.append(ring)
	Forge.light(root,Vector3.ZERO,color,3.5,14)
	Forge.sign_text(root,Vector3(0,radius+2,0),title,30,color)
	root.set_meta("target_id",targets.size())
	targets.append({"node":root,"kind":kind,"health":90.0 if kind in ["relay","archive"] else 360.0,"alive":true,"rings":rings,"pos":pos,"name":title,"prompt":prompt})

func spawn_enemies() -> void:
	var roster = [
		[Vector3(-5,1,-36),"scout"],[Vector3(6,-3,-49),"striker"],
		[Vector3(-37,2,-42),"scout"],[Vector3(37,-1,-40),"striker"],
		[Vector3(3,47,-49),"scout"],[Vector3(-7,43,-53),"striker"],
		[Vector3(5,45,-83),"striker"],[Vector3(-5,42,-96),"bulwark"],
		[Vector3(-39,-41,-40),"scout"],[Vector3(-48,-44,-49),"striker"],[Vector3(-36,-45,-53),"bulwark"],
		[Vector3(40,2,-83),"scout"],[Vector3(48,3,-98),"striker"],[Vector3(38,-2,-96),"bulwark"],
		[Vector3(-8,4,-86),"striker"],[Vector3(8,-5,-93),"bulwark"],[Vector3(0,7,-100),"scout"],[Vector3(-7,-4,-101),"striker"]]
	if mission_index>0: roster=Operations.roster(mission_index)
	for entry in roster: spawn_drone(entry[0],entry[1])
	total_drones=drones.size()

func spawn_drone(pos: Vector3,role: String) -> CharacterBody3D:
	var drone=Drone.new()
	drone.game=self
	drone.position=pos
	drone.role=role
	drone.spawn_id=next_drone_id
	next_drone_id+=1
	add_child(drone)
	drones.append(drone)
	total_drones=maxi(total_drones,drones.size()+kills)
	return drone

func launch(resume_saved: bool = false) -> void:
	if not resume_saved and (mission_time>0 or result_recorded):
		restart()
		return
	state = "playing"
	player.apply_upgrades()
	if not training_mode: campaign.data.selected=mission_index
	run_token=str(Time.get_unix_time_from_system())+"_"+str(randi())
	result_recorded=false
	if not resume_saved and not training_mode:
		campaign.data.checkpoint={}
		campaign.save()
	player.position = Vector3(0,0,8)
	player.rotation = Vector3.ZERO
	player.camera.position = Vector3.ZERO
	player.camera.h_offset=0
	menu_ship.hide()
	player.update_view(0)
	hud.front_view="title"
	if resume_saved: restore_checkpoint()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.rebuild_menu()
	announce("WELCOME TO KESTREL FLIGHT SCHOOL" if training_mode else ("CHECKPOINT RESTORED" if resume_saved else mission_info().objective+" / "+controls.label("map")+" FOR MAP"),5)
	sound.play_tone("ui")

func restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if training_mode: get_tree().root.set_meta("training_requested",true)
	else:
		campaign.data.checkpoint={}
		campaign.save()
	get_tree().root.set_meta("autodeploy",true)
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(hud): return
	controls.observe(event)
	if map_open:
		var close_key=event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE
		var close_pad=event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_B,JOY_BUTTON_START]
		if controls.pressed(event,"map") or close_key or close_pad: toggle_map()
		else: survey.input(event)
		get_viewport().set_input_as_handled(); return
	if hud.settings_open and not hud.listening_action.is_empty():
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
			hud.listening_action=""
			hud.rebuild_menu()
		elif controls.bind_event(hud.listening_action,event,hud.binding_device=="controller"):
			hud.listening_action=""
			save_settings()
			hud.rebuild_menu()
		get_viewport().set_input_as_handled()
		return
	var escape=event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE
	var cancel_pad=state!="playing" and event is InputEventJoypadButton and event.is_action_pressed("ui_cancel")
	if controls.pressed(event,"pause") or escape or cancel_pad:
		if hud.settings_open:
			hud.settings_open=false
			hud.rebuild_menu()
		elif hud.front_view in ["journal","saves"] and state=="paused":
			hud.front_view="title"; hud.rebuild_menu()
		elif state=="playing":
			player.rail_charge=0
			state="paused"
			Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			hud.rebuild_menu()
		elif state=="paused": resume()
		elif hud.front_view!="title": hud.front_view="title"; hud.rebuild_menu()
		get_viewport().set_input_as_handled()
		return
	if state=="playing":
		if controls.pressed(event,"camera_view"): player.toggle_view()
		if controls.pressed(event,"next_weapon"): arsenal.select(player.primary_weapon+1)
		for index in range(3):
			if controls.pressed(event,["pulse_weapon","plasma_weapon","rail_weapon"][index]): arsenal.select(index)
	if controls.pressed(event,"map") and state=="playing": toggle_map()
	if controls.pressed(event,"light") and state=="playing": player.lamp.visible=not player.lamp.visible
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F11:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if event.keycode==KEY_ENTER and state=="menu" and not hud.settings_open and hud.front_view in ["title","campaign","briefing"]:
			if hud.front_view=="title" and not campaign.data.checkpoint.is_empty(): continue_saved()
			elif hud.front_view=="briefing": launch()
			else: hud.show_briefing()
			get_viewport().set_input_as_handled()

func resume() -> void:
	state = "playing"
	player.rail_charge=0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.rebuild_menu()

func _process(delta: float) -> void:
	clock += delta
	if state == "menu":
		player.position = Vector3(9+sin(clock*0.12)*0.7,3,11)
		player.look_at(Vector3(-2,-1,-9))
		player.camera.h_offset=0
		menu_ship.position.y = -0.5+sin(clock*0.7)*0.25
	if state in ["won","lost"]: update_effects(delta)
	if state != "playing": return
	if map_open:
		survey.move(delta)
		if training_mode: training.update(delta)
		return
	survey.update(delta)
	mission_time += delta
	notice_time = maxf(0,notice_time-delta)
	flash = maxf(0,flash-delta*2)
	hit_confirm = maxf(0,hit_confirm-delta*3)
	kill_confirm = maxf(0,kill_confirm-delta*2)
	for machine in machinery: machine.node.rotate_object_local(machine.axis,delta*machine.speed)
	if training_mode:
		training.update(delta)
		update_effects(delta)
		return
	exploration.update(delta)
	systems.update(delta)
	director.update(delta)
	if secret_door.revealed and not secret_found and AABB(secret_center-secret_extent,secret_extent*2).has_point(player.position):
		secret_found=true
		score+=1000
		player.shield=player.shield_max
		player.boost=100
		announce("SECRET VAULT FOUND  /  FULL REPAIR  /  +1000",4)
		sound.play_tone("pickup")
	save_notice=maxf(0,save_notice-delta)
	checkpoint_time-=delta
	if checkpoint_time<=0:
		checkpoint_time=20
		store_checkpoint()
	if mission_index==1 and not exploration.interacting and not systems.interacting: update_interaction(delta)
	elif exploration.interacting or systems.interacting: interaction_target=-1; interaction_progress=0
	navigation_time-=delta
	if navigation_time<=0:
		navigation_time=0.2
		nav_hint=route_hint()
		for target in targets:
			if is_instance_valid(target.get("prompt")):
				target.prompt.text="HOLD "+controls.label("interact")+(" / DOWNLOAD" if target.kind=="archive" else " / UPLOAD")
		var sector=sector_name()
		if not visited.has(sector):
			visited[sector]=true
			if mission_time>6: announce("ENTERING "+sector,2.2)
	if reactor_down:
		escape_time -= delta
		if escape_time <= 0: finish(false,"SIGNAL LOST","The reactor took the complex with it.")
		elif player.position.distance_to(extraction) < 5:
			score += 1000+int(escape_time)*10
			finish(true,"OPERATION COMPLETE",["Nereid is silent. Your ship made it home.","The evidence is safe. Boreas falls behind you.","The Overseer is gone. The mining colonies are free."][mission_index])
	for target in targets:
		if not target.alive: continue
		for i in range(target.rings.size()):
			target.rings[i].rotate_y(delta*(0.35+i*0.15))
			target.rings[i].rotate_z(delta*0.2)
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup.node): continue
		pickup.node.rotation.y += delta
		pickup.node.position.y = pickup.pos.y+sin(clock*2+pickup.pos.x)*0.25
		if player.position.distance_to(pickup.node.position)<2.3:
			if pickup.kind == "shield":
				if player.shield >= player.shield_max: continue
				player.shield = minf(player.shield_max,player.shield+35)
				announce("SHIELDS RESTORED  +35",2)
			elif pickup.kind=="energy":
				if player.energy>=100: continue
				player.energy=minf(100,player.energy+40)
				announce("CAPACITOR RESTORED +40",2)
			else:
				player.missiles += 4+campaign.level("missiles")
				announce("SEEKER MISSILES  +4",2)
			combat_stats.pickups+=1
			sound.play_tone("pickup")
			pickup.node.queue_free()
			pickups.erase(pickup)
	update_effects(delta)

func _physics_process(delta: float) -> void:
	if state != "playing" or map_open: return
	aim_timer-=delta
	if aim_timer<=0:
		aim_timer=0.05
		update_aim()
	for shot in projectiles.duplicate():
		shot.life -= delta
		if shot.life <= 0:
			remove_projectile(shot)
			continue
		if shot.friendly and is_instance_valid(shot.target):
			var desired = (shot.target.global_position-shot.node.position).normalized()
			shot.direction = shot.direction.lerp(desired,delta*(2.4+campaign.level("missiles")*0.25)).normalized()
		var next = shot.node.position+shot.direction*shot.speed*delta
		var query = PhysicsRayQueryParameters3D.create(shot.node.position,next,1|4|8|16 if shot.friendly else 1|2|32)
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		if hit:
			if shot.friendly:
				if shot.get("kind","")=="plasma":
					hit_feedback.play(hit,"plasma",shot.node.position); arsenal.plasma_blast(hit.position,shot.damage)
				else: missile_blast(hit.position)
			elif hit.collider == player:
				player.hurt(shot.damage,shot.origin)
			elif is_instance_valid(exploration.escort) and hit.collider==exploration.escort: exploration.escort.hurt(shot.damage,shot.origin)
			else: hit_feedback.play(hit,"enemy",shot.origin)
			remove_projectile(shot)
		else:
			shot.node.position = next

func clear_line(a: Vector3,b: Vector3,exclude: Array = []) -> bool:
	var q = PhysicsRayQueryParameters3D.create(a,b,1)
	q.exclude = exclude
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func fire_laser() -> void:
	combat_stats.shots.pulse+=1
	var from = player.weapon_origin()
	var direction = player.aim_direction()
	var q = PhysicsRayQueryParameters3D.create(from,from+direction*150,1|4|8|16)
	var result = get_world_3d().direct_space_state.intersect_ray(q)
	var end = from+direction*110
	if result:
		end = result.position
		hit_feedback.play(result,"pulse",from)
		damage_object(result.collider,player.cannon_damage)
	for side in [-1,1]:
		var start = player.muzzle_position(side)
		var trail = Forge.beam(self,start,end,0.045,CYAN,4)
		effects.append({"node":trail,"life":0.085,"max":0.085,"velocity":Vector3.ZERO,"expand":false,"keep_scale":true})
	sound.play_tone("laser",0.5)

func fire_missile() -> void:
	combat_stats.shots.missile+=1
	var from = player.weapon_origin()
	var direction = player.aim_direction()
	var target: Node3D = null
	var best = 0.9
	var candidates=drones.duplicate()
	if is_instance_valid(boss) and not boss.dead: candidates.append(boss)
	for drone in candidates:
		if not is_instance_valid(drone): continue
		var to = drone.global_position-from
		if to.length()<70 and direction.dot(to.normalized()) > best and clear_line(from,drone.global_position):
			best = direction.dot(to.normalized())
			target = drone
	# Check the muzzle path before spawning, so close walls cannot be bypassed.
	var obstruction=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+direction*2,1|4|8|16))
	if obstruction:
		missile_blast(obstruction.position)
		return
	var n = Forge.sphere(self,from+direction*2,0.18,AMBER,4)
	Forge.light(n,Vector3.ZERO,AMBER,1.5,5)
	n.set_meta("trail_color",AMBER)
	projectiles.append({"node":n,"direction":direction,"speed":38.0,"life":5.0,"friendly":true,"target":target})
	sound.play_tone("missile",0.8)

func enemy_shot(pos: Vector3,direction: Vector3,speed: float = 22.0,damage: float = 8.0,color: Color = Color("ff7758")) -> void:
	var obstruction=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos,pos+direction*1.5,1))
	if obstruction: return
	combat_stats.enemy_shots+=1
	var n = Forge.sphere(self,pos+direction*1.5,0.15,color,1.8)
	projectiles.append({"node":n,"direction":direction,"speed":speed,"life":5.0,"friendly":false,"target":null,"damage":damage,"origin":pos})
	sound.play_at("enemy",pos,0.3)

func remove_projectile(shot: Dictionary) -> void:
	shot.node.queue_free()
	projectiles.erase(shot)

func missile_blast(pos: Vector3) -> void:
	explosion(pos,AMBER,2)
	for drone in drones.duplicate():
		if is_instance_valid(drone) and drone.global_position.distance_to(pos)<7 and clear_line(pos,drone.global_position): drone.hit(player.missile_damage,pos,true)
	if is_instance_valid(boss) and not boss.dead and boss.position.distance_to(pos)<11 and clear_line(pos,boss.position): boss.hit(player.missile_damage,pos,true)
	for h in director.hazards+systems.foundries:
		if not h.destroyed and h.position.distance_to(pos)<8 and clear_line(pos,h.position): h.hit(player.missile_damage,pos,true)
	for target in targets:
		if target.kind=="boss": continue
		if target.alive and target.pos.distance_to(pos)<8 and clear_line(pos,target.pos): damage_object(target.node,player.missile_damage,"missile")

func damage_object(body: Object,amount: float,weapon: String = "pulse",origin: Vector3 = Vector3.INF,explosive: bool = false) -> void:
	if training_mode:
		training.damage(body,amount,weapon)
		return
	if body.has_method("hit"):
		body.hit(amount,origin if origin.is_finite() else player.weapon_origin(),explosive)
		hit_confirm = 1
	elif body.has_meta("door"):
		var door = body.get_meta("door")
		if door.secret: door.breach()
	elif body.has_meta("target_id"):
		var target = targets[int(body.get_meta("target_id"))]
		if not target.alive: return
		if target.kind in ["archive","uplink"]:
			announce("ARCHIVE INTERFACE / APPROACH AND HOLD "+controls.label("interact"),2)
			return
		if target.kind == "reactor" and relays_down < 3:
			announce("CORE SHIELDED  /  DISABLE ALL THREE RELAYS",2)
			return
		target.health -= amount
		hit_confirm = 1
		if target.health <= 0:
			target.alive = false
			target.node.hide()
			target.node.collision_layer = 0
			explosion(target.pos,CYAN if target.kind=="relay" else AMBER,3)
			if target.kind == "relay":
				relays_down += 1
				score += 350
				announce("RELAY OFFLINE  /  %d OF 3" % relays_down,3)
				if relays_down == 3:
					for door in reactor_doors: door.unlock()
					announce("OVERSEER SHIELD COLLAPSED / DEFEAT THE OVERSEER" if mission_index==2 else "REACTOR ACCESS OPEN / DESTROY THE CORE",5)
			else:
				score+=1500
				begin_escape("CORE BREACH / RETURN TO THE ARRIVAL DOCK")

func spawn_pickup(pos: Vector3,kind: String) -> void:
	var root = Node3D.new()
	level.add_child(root)
	root.position = pos
	var color = CYAN if kind == "shield" else (Color("b499ff") if kind=="energy" else AMBER)
	var cube = Forge.box(root,Vector3.ZERO,Vector3(0.65,0.65,0.65),color,1.5)
	cube.rotation.z = PI/4
	Forge.ring(root,Vector3.ZERO,0.85,0.035,color,2)
	Forge.light(root,Vector3.ZERO,color,0.6,4)
	pickups.append({"node":root,"pos":pos,"kind":kind})

func impact(pos: Vector3,color: Color,count: int) -> void:
	for i in range(count):
		var n = Forge.sphere(self,pos,randf_range(0.04,0.09),color,2)
		var life = randf_range(0.15,0.4)
		effects.append({"node":n,"life":life,"max":life,"velocity":Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))*5,"expand":false})

func explosion(pos: Vector3,color: Color,size: float) -> void:
	impact(pos,color,22)
	if graphics_preset>0 and effects.size()<350:
		for i in range(5):
			var dir=Vector3(sin(i*2.3),cos(i*1.7)*0.7,cos(i*2.3)).normalized()
			var spark=Forge.beam(self,pos,pos+dir*0.8,0.035,color,2)
			effects.append({"node":spark,"life":0.45,"max":0.45,"velocity":dir*9,"expand":false,"keep_scale":true})
		var fire=Forge.sphere(self,pos,0.35,color,1.8)
		effects.append({"node":fire,"life":0.2,"max":0.2,"velocity":Vector3.ZERO,"expand":true,"size":size*0.35})
	var n = Forge.ring(self,pos,0.4,0.04,color,1.7)
	n.rotation.x=PI/2
	effects.append({"node":n,"life":0.42,"max":0.42,"velocity":Vector3.ZERO,"expand":true,"size":size})
	for i in range(8):
		var debris=Forge.box(self,pos,Vector3(0.13,0.07,0.23),Color("7a6f62"))
		effects.append({"node":debris,"life":0.8,"max":0.8,"velocity":Vector3(randf_range(-5,5),randf_range(-5,5),randf_range(-5,5)),"expand":false,"spin":randf_range(2,8)})
	var flash_light=Forge.light(self,pos,color,5,clampf(size*8,8,32))
	effects.append({"node":flash_light,"life":0.28,"max":0.28,"velocity":Vector3.ZERO,"expand":false,"keep_scale":true,"light_energy":5.0})
	for i in range(3):
		var smoke=Forge.sphere(self,pos+Vector3(randf_range(-0.6,0.6),randf_range(-0.6,0.6),randf_range(-0.6,0.6)),0.4,Color("263c45"))
		var material=smoke.material_override.duplicate()
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color=Color(0.12,0.17,0.2,0.3)
		smoke.material_override=material
		effects.append({"node":smoke,"life":1.0,"max":1.0,"velocity":Vector3(randf_range(-1,1),1,randf_range(-1,1)),"expand":true,"size":size*0.25,"fade":0.3})
	if is_instance_valid(player) and player.position.distance_to(pos)<18: flash=maxf(flash,0.16)
	sound.play_at("blast",pos,0.8)

func update_effects(delta: float) -> void:
	for effect in effects.duplicate():
		effect.life -= delta
		if effect.life <= 0:
			effect.node.queue_free()
			effects.erase(effect)
			continue
		effect.node.position += effect.velocity*delta
		if effect.expand: effect.node.scale = Vector3.ONE*(1+(1-effect.life/effect.max)*effect.size*5)
		elif not effect.get("keep_scale",false): effect.node.scale = Vector3.ONE*maxf(0.03,effect.life/effect.max)
		if effect.has("spin"): effect.node.rotate_object_local(Vector3.UP,delta*effect.spin)
		if effect.has("fade"):
			var tint=effect.node.material_override.albedo_color
			tint.a=effect.fade*(effect.life/effect.max)
			effect.node.material_override.albedo_color=tint
		if effect.has("light_energy"): effect.node.light_energy=effect.light_energy*(effect.life/effect.max)
		flight_fx.advance(effect,delta)

func announce(text: String,duration: float = 3.0) -> void:
	notice = text
	notice_time = duration

func finish(success: bool,title: String,detail: String) -> void:
	if result_recorded: return
	result_recorded=true
	if training_mode:
		end_title=title
		end_detail=detail
		state="won" if success else "lost"
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		hud.rebuild_menu()
		return
	if success:
		if exploration.escort.status in ["following","waiting"] and exploration.escort.position.distance_to(extraction)<12 and clear_line(exploration.escort.position,extraction): exploration.escort.deliver()
		rating=Ratings.evaluate(self)
		reward=campaign.complete(mission_index,score,mission_time,kills,secret_found,run_token,director.challenge_state=="cleared",exploration.crew_rescued,exploration.escort.status=="delivered",rating)
	else:
		campaign.data.checkpoint={}
		campaign.save()
	state = "won" if success else "lost"
	end_title = "CAMPAIGN COMPLETE" if success and mission_index==2 else title
	end_detail = detail
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.rebuild_menu()

func sector_name() -> String:
	if training_mode: return "KESTREL / TRAINING HANGAR"
	var pos=player.position
	if mission_index>0:
		for room in map_rooms:
			if not room.title.is_empty() and AABB(room.center-room.size/2,room.size).has_point(pos): return room.title
		return mission_info().location+" / FLIGHT CONDUIT"
	if pos.y < -32:
		return "09 / RESERVE VAULT" if pos.x < -73 else "01 / LOWER FOUNDRY"
	if pos.y < -10: return "FOUNDRY DESCENT SHAFT"
	if pos.y > 34:
		return "03 / UPPER RELAY" if pos.z < -76 else "03 / TURBINE DECK"
	if pos.y > 11: return "TURBINE ASCENT SHAFT"
	if pos.z > -16: return "07 / ARRIVAL DOCK"
	if pos.x > 30 and pos.z < -75: return "02 / PUMP HALL"
	if pos.x > 30 and pos.z < -57: return "COOLANT CONDUIT"
	if pos.z < -75: return "04 / REACTOR CHAMBER"
	if pos.z < -59: return "REACTOR ACCESS"
	if pos.x < -31: return "01 / FOUNDRY LIFT"
	if pos.x > 31: return "02 / COOLANT WORKS"
	if absf(pos.x)>16: return "SERVICE CONDUIT"
	return "00 / CENTRAL NEXUS"

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if state in ["playing","paused"]: store_checkpoint()
		get_tree().quit()
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and state == "playing" and not map_open and is_instance_valid(hud) and not get_tree().root.get_meta("cinematic",false):
		state = "paused"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.rebuild_menu()

func update_aim() -> void:
	aim_name = ""
	seeker_lock = false
	var from = player.weapon_origin()
	var ray = PhysicsRayQueryParameters3D.create(from,from+player.aim_direction()*100,1|4|8|16)
	var result = get_world_3d().direct_space_state.intersect_ray(ray)
	if not result: return
	var collider = result.collider
	if collider.has_method("hit"):
		aim_name = collider.role.to_upper()
		if collider==boss: aim_name += " / SHIELDED" if relays_down<3 else " / PHASE %d" % boss.phase
		if collider.elite: aim_name += " / ARMOR" if (-collider.visual.global_basis.z).dot((player.position-collider.position).normalized())>0.6 else " / EXPOSED"
		aim_health = collider.health
		aim_max = collider.max_health
		seeker_lock = collider.collision_layer!=16 and from.distance_to(collider.position)<70 and player.missiles>0
	elif collider.has_meta("target_id"):
		var target = targets[int(collider.get_meta("target_id"))]
		if not target.alive: return
		aim_name = target.name
		aim_health = target.health
		aim_max = 90 if target.kind in ["relay","archive"] else 360
		if target.kind=="reactor" and relays_down<3: aim_name += " / SHIELDED"

const NAV_NODES = {
	"dock":Vector3(0,0,8),"entry":Vector3(0,0,-22),"nexus":Vector3(0,0,-44),
	"port":Vector3(-43,0,-44),"foundry":Vector3(-43,-43,-44),
	"turbines":Vector3(0,44,-44),"upper":Vector3(0,44,-90),
	"coolant":Vector3(43,0,-44),"pump":Vector3(43,0,-91),
	"access":Vector3(0,0,-67),"core":Vector3(0,0,-91),"loop":Vector3(24,0,-91),
	"secret":Vector3(-66,-43,-44),"vault":Vector3(-83,-43,-44)}
const NAV_EDGES = [["dock","entry"],["entry","nexus"],["nexus","port"],["port","foundry"],["nexus","turbines"],["turbines","upper"],["nexus","coolant"],["coolant","pump"],["nexus","access"],["access","core"],["core","loop"],["loop","pump"],["foundry","secret"],["secret","vault"]]
const NAV_TITLES = {"dock":"ARRIVAL / EXTRACTION","entry":"ARRIVAL CONDUIT","nexus":"CENTRAL NEXUS","port":"FOUNDRY LIFT","foundry":"LOWER FOUNDRY","turbines":"TURBINE FLIGHT SHAFT","upper":"UPPER RELAY","coolant":"COOLANT WORKS","pump":"PUMP HALL","access":"REACTOR ACCESS","core":"REACTOR CORE","loop":"REACTOR SERVICE LOOP","secret":"MAINTENANCE ACCESS","vault":"RESERVE VAULT"}

func path_to(start: String,goal: String) -> Array:
	var open: Array=[start]
	var costs={start:0.0}
	var previous={}
	while not open.is_empty():
		open.sort_custom(func(a,b): return costs[a]<costs[b])
		var current=open.pop_front()
		if current==goal:
			var path: Array=[goal]
			while path[0]!=start: path.push_front(previous[path[0]])
			return path
		for edge in nav_edges:
			if not training_mode and systems.edge_locked(edge): continue
			if edge in locked_nav_edges and relays_down<3: continue
			if ("secret" in edge or "vault" in edge) and not secret_door.revealed: continue
			var other=""
			if edge[0]==current: other=edge[1]
			elif edge[1]==current: other=edge[0]
			if other.is_empty(): continue
			var cost=costs[current]+nav_nodes[current].distance_to(nav_nodes[other])
			if not costs.has(other) or cost<costs[other]:
				costs[other]=cost
				previous[other]=current
				if other not in open: open.append(other)
	return []

func route_hint() -> Dictionary:
	if training_mode: return training.hint()
	var start="nexus"
	var nearest=INF
	for key in nav_nodes:
		if key in ["secret","vault"] and not secret_door.revealed: continue
		var distance=player.position.distance_to(nav_nodes[key])
		if distance<nearest: nearest=distance; start=key
	if not reactor_down and not survey.pin.is_empty() and nav_nodes.has(survey.pin):
		var pinned=path_to(start,survey.pin)
		if not pinned.is_empty():
			var next=pinned[1] if pinned.size()>1 else survey.pin
			return {"pos":nav_nodes[next],"name":"PIN / "+nav_titles[next],"color":Color("a5c4ff")}
	var goal="dock" if reactor_down else "core"
	var goal_pos=extraction if reactor_down else targets[3].pos
	var title="EXTRACTION" if reactor_down else "REACTOR CORE"
	if not reactor_down and relays_down<3:
		var best=INF
		var names=nav_goals
		for i in range(3):
			if not targets[i].alive: continue
			var path=path_to(start,names[i])
			if path.is_empty(): continue
			var cost=nearest
			for j in range(path.size()-1): cost+=nav_nodes[path[j]].distance_to(nav_nodes[path[j+1]])
			if cost<best:
				best=cost; goal=names[i]; goal_pos=targets[i].pos; title=targets[i].name
	var route=path_to(start,goal)
	if route.is_empty(): return {}
	var destination=goal_pos
	if route.size()>1:
		var current=nav_nodes[start]
		var next=nav_nodes[route[1]]
		var direction=(next-current).normalized()
		var deviation=player.position-current
		var side=deviation-direction*deviation.dot(direction)
		if side.length()>3 and nearest>5:
			destination=current; title=nav_titles[start]
		else:
			destination=next; title=nav_titles[route[1]]
	return {"pos":destination,"name":title,"color":AMBER}

func save_settings() -> void:
	var config=ConfigFile.new()
	config.set_value("flight","sensitivity",player.sensitivity)
	config.set_value("flight","shake",player.shake_enabled)
	config.set_value("flight","assist",player.flight_assist)
	config.set_value("flight","invert",player.invert_mouse)
	config.set_value("flight","chase_view",player.chase_enabled)
	config.set_value("audio","master",sound.volume)
	config.set_value("audio","music",sound.music_volume)
	config.set_value("audio","effects",sound.effects_volume)
	config.set_value("display","fov",player.base_fov)
	config.set_value("display","hud_scale",hud_scale)
	config.set_value("display","graphics",graphics_preset)
	config.set_value("flight","difficulty",difficulty)
	config.set_value("flight","controller_rate",player.controller_rate)
	config.set_value("flight","deadzone",controls.deadzone)
	config.set_value("controls","keyboard",controls.bindings)
	config.set_value("controls","controller",controls.pad_bindings)
	if not get_tree().root.get_meta("test_session",false): config.save("user://flight.cfg")

func load_settings() -> void:
	var config=ConfigFile.new()
	if config.load("user://flight.cfg")!=OK: return
	player.sensitivity=clampf(config.get_value("flight","sensitivity",0.0022),0.0007,0.004)
	player.shake_enabled=config.get_value("flight","shake",true)
	player.flight_assist=config.get_value("flight","assist",true)
	player.invert_mouse=config.get_value("flight","invert",false)
	player.chase_enabled=bool(config.get_value("flight","chase_view",false))
	sound.set_volume(clampf(config.get_value("audio","master",0.65),0,1))
	sound.music_volume=clampf(config.get_value("audio","music",0.45),0,1)
	sound.effects_volume=clampf(config.get_value("audio","effects",0.85),0,1)
	player.base_fov=clampf(config.get_value("display","fov",83.0),65,100)
	hud_scale=clampf(config.get_value("display","hud_scale",1.0),0.75,1)
	graphics_preset=clampi(config.get_value("display","graphics",1),0,2)
	difficulty=clampi(config.get_value("flight","difficulty",1),0,2)
	player.controller_rate=clampf(config.get_value("flight","controller_rate",1.8),0.6,3.5)
	controls.deadzone=clampf(config.get_value("flight","deadzone",0.18),0.05,0.35)
	controls.load_bindings(config.get_value("controls","keyboard",{}),config.get_value("controls","controller",{}))

func mission_info() -> Dictionary:
	return Progress.MISSIONS[mission_index]

func objective_text() -> String:
	if training_mode: return "TRAINING / "+training.STEPS[training.step]
	if reactor_down: return "RETURN TO EXTRACTION"
	if relays_down<3: return mission_info().objective
	return ["DESTROY THE REACTOR","UPLOAD AT THE UPLINK","DEFEAT THE OVERSEER"][mission_index]

func begin_escape(message: String) -> void:
	reactor_down=true
	escape_time=mission_info().escape
	flash=1
	announce(message,6)
	Forge.light(level,targets[3].pos,Color("ff543a"),6,38)
	if mission_index==1:
		for x in [-6,6]: spawn_drone(Vector3(x,0,-48),"scout")

func update_interaction(delta: float) -> void:
	var candidate=-1
	var nearest=5.6
	if not reactor_down:
		for i in range(targets.size()):
			var target=targets[i]
			if not target.alive or target.kind not in ["archive","uplink"]: continue
			if target.kind=="uplink" and relays_down<3: continue
			var distance=player.position.distance_to(target.pos)
			if distance<nearest and clear_line(player.position,target.pos): nearest=distance; candidate=i
	if candidate!=interaction_target: interaction_progress=0
	interaction_target=candidate
	if candidate<0: return
	if controls.held("interact"): interaction_progress+=delta/(3.0 if targets[candidate].kind=="uplink" else 2.0)
	else: interaction_progress=maxf(0,interaction_progress-delta*2)
	if interaction_progress>=1:
		var target=targets[candidate]
		target.alive=false
		target.node.hide()
		target.node.collision_layer=0
		if target.kind=="archive":
			relays_down+=1
			score+=500
			announce("ARCHIVE DECRYPTED / %d OF 3" % relays_down,3)
			if relays_down==3:
				for door in reactor_doors: door.unlock()
				announce("ALL ARCHIVES RECOVERED / UPLOAD AT THE UPLINK",5)
		else:
			score+=2000
			begin_escape("EVIDENCE UPLOADED / INTERCEPTORS INBOUND / EVACUATE")
		sound.play_tone("pickup")
		interaction_target=-1
		interaction_progress=0
		store_checkpoint()

func choose_mission(index: int) -> void:
	if index<0 or index>campaign.data.unlocked: return
	campaign.data.selected=index
	campaign.save()
	get_tree().root.set_meta("mission_selection",index)
	get_tree().root.set_meta("front_view","campaign")
	get_tree().reload_current_scene()

func continue_saved() -> void:
	if campaign.data.checkpoint.is_empty(): return
	get_tree().root.set_meta("mission_selection",int(campaign.data.checkpoint.mission))
	get_tree().root.set_meta("resume_checkpoint",true)
	get_tree().root.set_meta("autodeploy",true)
	get_tree().reload_current_scene()

func return_to_hangar() -> void:
	if state in ["playing","paused"]: store_checkpoint()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	get_tree().root.set_meta("front_view","campaign")
	get_tree().reload_current_scene()

func buy_upgrade(part: String) -> void:
	if campaign.buy(part):
		player.apply_upgrades()
		sound.play_tone("pickup")
		hud.rebuild_menu()
	else:
		sound.play_tone("hurt",0.3)
		hud.rebuild_menu()

func to_array(vector: Vector3) -> Array:
	return [vector.x,vector.y,vector.z]

func to_vector(value: Variant,fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if not value is Array or value.size()!=3: return fallback
	for component in value:
		if not (component is float or component is int) or not is_finite(float(component)): return fallback
	return Vector3(value[0],value[1],value[2])

func store_checkpoint() -> bool:
	if training_mode or not state in ["playing","paused"] or result_recorded: return false
	var snapshot={"mission":mission_index,"run":run_token,"time":mission_time,"score":score,"kills":kills,"total":total_drones,"relays":relays_down,"escaped_core":reactor_down,"escape_time":escape_time,"secret":secret_found,"secret_open":secret_door.revealed,"pilot":{"pos":to_array(player.position),"rot":to_array(player.rotation),"velocity":to_array(player.velocity),"shield":player.shield,"energy":player.energy,"boost":player.boost,"missiles":player.missiles},"targets":[],"drones":[],"pickups":[]}
	snapshot["survey"]=survey.snapshot()
	snapshot["systems"]=systems.snapshot()
	snapshot["exploration"]=exploration.snapshot()
	snapshot["encounters"]=director.snapshot()
	snapshot["combat_stats"]=combat_stats.duplicate(true)
	snapshot.pilot["primary_weapon"]=player.primary_weapon
	for target in targets: snapshot.targets.append({"alive":target.alive,"health":target.health})
	for drone in drones:
		if is_instance_valid(drone) and not drone.dead: snapshot.drones.append({"role":drone.role,"pos":to_array(drone.position),"home":to_array(drone.home),"health":drone.health,"id":drone.spawn_id})
	for pickup in pickups: snapshot.pickups.append({"kind":pickup.kind,"pos":to_array(pickup.pos)})
	if is_instance_valid(boss): snapshot["boss"]={"health":boss.health,"phase":boss.phase,"pos":to_array(boss.position),"dead":boss.dead,"reinforcements":boss.reinforcements}
	campaign.data.checkpoint=snapshot
	var ok=campaign.save()
	if ok: save_notice=2.5
	else: announce("PROGRESS COULD NOT SAVE / CHECK STORAGE",5)
	return ok

func restore_checkpoint() -> bool:
	var saved=campaign.data.checkpoint
	if saved.is_empty() or int(saved.get("mission",-1))!=mission_index or saved.targets.size()!=targets.size(): return false
	var pilot=saved.pilot
	player.position=to_vector(pilot.get("pos",[]),Vector3(0,0,8))
	player.rotation=to_vector(pilot.get("rot",[]))
	player.velocity=to_vector(pilot.get("velocity",[]))
	player.shield=clampf(float(pilot.get("shield",player.shield_max)),1,player.shield_max)
	player.energy=clampf(float(pilot.get("energy",100)),0,100)
	player.boost=clampf(float(pilot.get("boost",100)),0,100)
	player.missiles=clampi(int(pilot.get("missiles",8)),0,999)
	player.primary_weapon=clampi(int(pilot.get("primary_weapon",0)),0,2)
	player.rail_charge=0
	run_token=str(saved.get("run",run_token))
	mission_time=maxf(0,float(saved.get("time",0)))
	score=maxi(0,int(saved.get("score",0)))
	kills=maxi(0,int(saved.get("kills",0)))
	relays_down=clampi(int(saved.get("relays",0)),0,3)
	reactor_down=bool(saved.get("escaped_core",false))
	escape_time=clampf(float(saved.get("escape_time",75)),0.1,90)
	secret_found=bool(saved.get("secret",false))
	for i in range(targets.size()):
		targets[i].alive=bool(saved.targets[i].get("alive",true))
		targets[i].health=maxf(0,float(saved.targets[i].get("health",targets[i].health)))
		if not targets[i].alive:
			targets[i].node.hide()
			targets[i].node.collision_layer=0
	for drone in drones:
		drone.collision_layer=0
		drone.queue_free()
	drones.clear()
	for entry in saved.get("drones",[]):
		var drone=spawn_drone(to_vector(entry.get("pos",[])),str(entry.get("role","scout")))
		drone.health=clampf(float(entry.get("health",drone.max_health)),1,drone.max_health)
		drone.home=to_vector(entry.get("home",[]),drone.position)
		drone.spawn_id=int(entry.get("id",drone.spawn_id))
		next_drone_id=maxi(next_drone_id,drone.spawn_id+1)
	total_drones=maxi(kills+drones.size(),int(saved.get("total",total_drones)))
	for pickup in pickups: pickup.node.queue_free()
	pickups.clear()
	for pickup in saved.get("pickups",[]): spawn_pickup(to_vector(pickup.get("pos",[])),str(pickup.get("kind","shield")))
	if saved.get("secret_open",false): secret_door.breach()
	if relays_down==3:
		for door in reactor_doors: door.unlock()
	for door in doors:
		if not door.locked and player.position.distance_to(door.position)<12: door.openness=1
	if is_instance_valid(boss) and saved.has("boss"):
		var b=saved.boss
		boss.health=clampf(float(b.get("health",1500)),0,1500)
		boss.phase=clampi(int(b.get("phase",1)),1,3)
		boss.position=to_vector(b.get("pos",[]),boss.home)
		boss.dead=bool(b.get("dead",false))
		boss.reinforcements=bool(b.get("reinforcements",false))
		if boss.dead:
			boss.hide()
			boss.collision_layer=0
		else: boss.warming=1.0
	systems.restore(saved.get("systems",{}))
	survey.restore(saved.get("survey",{}))
	director.restore(saved.get("encounters",{}))
	exploration.restore(saved.get("exploration",{}))
	if saved.has("combat_stats"): combat_stats.merge(saved.combat_stats.duplicate(true),true)
	nav_hint=route_hint()
	return true

func verify_release() -> void:
	var args=OS.get_cmdline_user_args()
	if "--verify-vista" in args and not training_mode:
		state="playing"; player.set_physics_process(false); menu_ship.hide(); player.cockpit.show(); hud.rebuild_menu()
		for d in drones: d.set_physics_process(false)
		if is_instance_valid(boss): boss.set_physics_process(false)
		var origin=[Vector3(0,44,-103),Vector3(52,0,-64),Vector3(0,0,-127)][mission_index]
		player.position=origin+Vector3(0,-0.5,4); player.look_at(origin+Vector3(0,0,-30))
	if "--verify-livery" in args:
		hud.front_view="livery"; hud.rebuild_menu()
	if "--verify-chase" in args or "--verify-damage" in args or "--verify-breakup" in args:
		launch(); player.set_physics_process(false); player.position=Vector3(0,1,-44); player.rotation=Vector3.ZERO
		for d in drones: d.set_physics_process(false)
		player.chase_enabled="--verify-breakup" not in args; player.update_view(0); notice_time=0
		if "--verify-chase" in args: player.thrust_level=1; player.boosting=true
		if "--verify-damage" in args: player.shield=22; player.flight_state.update_state(0.01); player.flight_state.flash(player.position+Vector3(0,0,4))
		if "--verify-breakup" in args:
			var victim=drones[0]; victim.position=player.position+Vector3(0,0,-6); victim.visual.look_at(player.position); victim.hit(10000,player.position,true)
	if "--verify-fleet" in args:
		for argument in args:
			if argument.begins_with("--verify-ship="): hud.fleet_index=clampi(int(argument.get_slice("=",1)),0,6)
		hud.front_view="fleet"; hud.rebuild_menu()
	if "--verify-map" in args and not training_mode:
		state="playing"; player.set_physics_process(false); menu_ship.hide(); hud.rebuild_menu()
		survey.seen=range(map_rooms.size()); survey.seen_links=range(map_links.size()); survey.place_marker("pump" if mission_index==0 else "core"); toggle_map()
	if "--verify-saves" in args and not training_mode:
		launch(); state="paused"; hud.show_saves(); manual_save(0)
	if "--verify-profiles" in args:
		hud.front_view="profiles"; hud.rebuild_menu()
	if "--verify-audio" in args:
		hud.settings_open=true; hud.settings_tab="flight"; hud.rebuild_menu()
	var acoustic_voice: AudioStreamPlayer3D
	if "--verify-acoustics" in args:
		launch(); player.set_physics_process(false); player.position=Vector3(0,1,-44); player.rotation=Vector3.ZERO; player.chase_enabled=false; player.update_view(0)
		for d in drones: d.set_physics_process(false)
		Forge.box(self,Vector3(0,1,-47),Vector3(4,4,0.3),Color.GRAY,0,true)
		await get_tree().physics_frame; await get_tree().physics_frame
		acoustic_voice=sound.play_at("machine",Vector3(0,1,-50),0.1,true)
		fire_laser()
	for i in range(18): await get_tree().process_frame
	var valid=((targets.size()==2 and drones.is_empty()) if training_mode else (targets.size()==4 and drones.size()>0)) and menu_ship.get_child_count()>0
	valid=valid and controls.bindings.size()==25 and ResourceLoader.exists("res://assets/audio/plasma.res") and ResourceLoader.exists("res://assets/audio/rail.res") and (training_mode or director.hazards.size()==3)
	valid=valid and (training_mode or exploration.items.size()==5)
	if "--verify-livery" in args: valid=valid and is_instance_valid(hud.livery_model)
	if "--verify-fleet" in args: valid=valid and is_instance_valid(hud.livery_model) and is_instance_valid(hud.preview_camera)
	valid=valid and ResourceLoader.exists("res://assets/models/warden.glb") and ResourceLoader.exists("res://assets/models/courier.glb") and ResourceLoader.exists("res://assets/models/cockpit_gun.glb")
	if not training_mode: valid=valid and systems.foundries.size()==1 and systems.gate.locked and campaign.data.manual_slots.size()==3
	if "--verify-map" in args: valid=valid and map_open and survey.seen.size()==map_rooms.size()
	if "--verify-saves" in args: valid=valid and not campaign.data.manual_slots[0].is_empty()
	if "--verify-profiles" in args: valid=valid and hud.profile_rows.size()==3
	if "--verify-audio" in args: valid=valid and sound.variations.size()==12 and is_instance_valid(sound.boost_audio) and sound.hum.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and FileAccess.file_exists("res://assets/audio/sfx/manifest.json")
	if "--verify-acoustics" in args: valid=valid and is_instance_valid(acoustic_voice) and acoustic_voice.bus=="Muffled_Ambience" and hit_feedback.last_surface=="metal"
	if "--verify-chase" in args: valid=valid and player.exterior.visible and player.camera.position.z>1
	if "--verify-damage" in args: valid=valid and player.flight_state.burns[0].visible
	if "--verify-breakup" in args: valid=valid and effects.any(func(e): return e.get("kind","")=="hull_debris")
	for argument in args:
		if argument.begins_with("--verify-capture="):
			var captured=get_viewport().get_texture().get_image()
			if captured!=null: valid=valid and captured.save_png(argument.get_slice("=",1))==OK
	print("EXPLORATION CONTENT items=",exploration.items.size()," paints=",campaign.data.paints.size())
	print("COMBAT CONTENT weapons=3 hazards=",director.hazards.size()," trial=",director.challenge_state)
	print("RELEASE VERIFY training=",training_mode," mission=",mission_index+1," targets=",targets.size()," enemies=",drones.size()," models=",menu_ship.get_child_count()," OK=",valid)
	get_tree().quit(0 if valid else 1)

func quit_game() -> void:
	if state in ["playing","paused"]: store_checkpoint()
	get_tree().quit()

func start_training() -> void:
	get_tree().root.set_meta("training_requested",true)
	get_tree().root.set_meta("autodeploy",true)
	get_tree().reload_current_scene()

func is_secret_open() -> bool:
	return is_instance_valid(secret_door) and secret_door.revealed

func apply_graphics() -> void:
	var viewport=get_viewport()
	viewport.msaa_3d=[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X][graphics_preset]
	viewport.scaling_3d_scale=[0.7,1.0,1.0][graphics_preset]
	environment.glow_enabled=graphics_preset>0
	for item in machinery:
		if item.node is MultiMeshInstance3D: item.node.visible=graphics_preset>0

func cycle_graphics() -> void:
	graphics_preset=(graphics_preset+1)%3
	apply_graphics()
	save_settings()
	hud.rebuild_menu()

func cycle_difficulty() -> void:
	difficulty=(difficulty+1)%3
	save_settings()
	hud.rebuild_menu()

func spread_direction(direction: Vector3,angle: float) -> Vector3:
	var axis=direction.cross(Vector3.RIGHT).normalized()
	if axis.is_zero_approx(): axis=Vector3.UP
	return direction.rotated(axis,angle)

func toggle_map() -> void:
	map_open=not map_open; player.rail_charge=0
	for action in ["fire","missile"]: Input.action_release("ship_"+action)
	if map_open: survey.update(1)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if map_open else Input.MOUSE_MODE_CAPTURED
func switch_profile(index: int) -> bool:
	if state not in ["menu","won","lost"]: return false
	if not profile_store.activate(index): hud.save_message=profile_store.error; hud.rebuild_menu(); return false
	for key in ["mission_selection","autodeploy","resume_checkpoint","training_requested"]:
		if get_tree().root.has_meta(key): get_tree().root.remove_meta(key)
	get_tree().root.set_meta("front_view","title"); get_tree().reload_current_scene(); return true
func manual_save(index: int) -> bool:
	if training_mode or state!="paused" or not store_checkpoint(): return false
	var ok=campaign.save_slot(index,campaign.data.checkpoint)
	hud.save_message="MANUAL SLOT SAVED" if ok else campaign.last_error
	hud.confirm_slot=-1; hud.rebuild_menu(); return ok
func manual_load(index: int) -> bool:
	if not campaign.load_slot(index): hud.save_message=campaign.last_error; hud.rebuild_menu(); return false
	continue_saved(); return true
