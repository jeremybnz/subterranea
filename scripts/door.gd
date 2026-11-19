extends Node3D
## Split blast doors move with their collision, with proximity hold and safe closing.
const Forge = preload("res://scripts/forge.gd")
var game: Node3D
var width = 12.0
var height = 10.0
var locked = false
var secret = false
var revealed = false
var label = "TRANSIT / AUTO"
var openness = 0.0
var desired_open = false
var panels: Array = []
var signs: Array = []
var prompts: Array = []
var status_lights: Array = []
var last_motion = false

func _ready() -> void:
	Forge.portal(self,Vector3.ZERO,width,height,false,Color("77e6d8"))
	for side in [-1,1]:
		var body = AnimatableBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.sync_to_physics = false
		add_child(body)
		body.position.x = side*width/4
		body.set_meta("door",self)
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(width/2,height,0.45)
		shape.shape = box
		body.add_child(shape)
		Forge.box(body,Vector3.ZERO,box.size,Color("3c505b") if not secret else Color("38434a"))
		Forge.box(body,Vector3(0,0,0.24),Vector3(width/2-0.4,height-0.6,0.08),Color("223440"))
		for y in [-3.5,3.5]:
			Forge.box(body,Vector3(0,y,0.31),Vector3(width/2-0.65,0.14,0.05),Color("d99a59"),0.4)
		for face in [-1,1]:
			var light = Forge.box(body,Vector3(-side*(width/4-0.18),0,face*0.29),Vector3(0.08,height-0.8,0.06),Color("ef9b6a"),1.3)
			status_lights.append(light)
		panels.append({"node":body,"side":side})
	for face in [-1,1]:
		var sign = Forge.sign_text(self,Vector3(0,1.1,face*0.35),label,32,Color("afd7d7"),0 if face==1 else PI)
		signs.append(sign)
		var prompt=Forge.sign_text(self,Vector3(0,-0.1,face*0.35),"FRACTURED PLATING / FIRE TO BREACH" if secret else ("DISABLE RELAYS" if locked else "PROXIMITY SENSOR"),17,Color("7b9da8"),0 if face==1 else PI)
		prompts.append(prompt)
	if secret:
		for i in range(4):
			Forge.beam(self,Vector3(-2+i,2-i,0.36),Vector3(-1+i,0.6-i*0.7,0.36),0.045,Color("b5a37b"),0.4)

func unlock() -> void:
	locked = false
	for sign in signs: sign.text = "ACCESS GRANTED"
	for prompt in prompts: prompt.text = "MAINTENANCE ACCESS" if secret else "PROXIMITY SENSOR"
	for light in status_lights: light.material_override = Forge.material(Color("77e6d8"),1.4)

func breach() -> void:
	if not secret or revealed: return
	revealed = true
	unlock()
	game.announce("HIDDEN MAINTENANCE ACCESS  /  SUPPLIES BEYOND",4)
	game.sound.play_at("blast",global_position,0.6)

func _physics_process(delta: float) -> void:
	if game.state != "playing" or game.map_open: return
	var local = to_local(game.player.global_position)
	var near = absf(local.x)<width/2+2 and absf(local.y)<height/2+2 and absf(local.z)<9
	# Stay open while any ship intersects the doorway's safety zone.
	for drone in game.drones:
		if not is_instance_valid(drone): continue
		var d = to_local(drone.global_position)
		if absf(d.x)<width/2+1 and absf(d.y)<height/2+1 and absf(d.z)<4: near = true
	if is_instance_valid(game.exploration.escort) and game.exploration.escort.status in ["following","waiting"]:
		var e=to_local(game.exploration.escort.global_position)
		if absf(e.x)<width/2+2 and absf(e.y)<height/2+2 and absf(e.z)<9: near=true
	desired_open = not locked and (revealed if secret else near or game.reactor_down)
	var moving = (desired_open and openness<1) or (not desired_open and openness>0)
	if moving and not last_motion: game.sound.play_at("door_open" if desired_open else "door_close",global_position,0.5)
	last_motion = moving
	openness = move_toward(openness,1.0 if desired_open else 0.0,delta*1.5)
	for sign in signs: sign.visible=openness<0.35
	for prompt in prompts: prompt.visible=openness<0.35
	var eased = smoothstep(0,1,openness)
	for panel in panels:
		panel.node.position.x = panel.side*(width/4+eased*(width/2+0.3))
