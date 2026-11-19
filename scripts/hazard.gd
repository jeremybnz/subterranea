extends StaticBody3D
const Forge=preload("res://scripts/forge.gd")
var game
var hazard_id=0
var kind="coolant"
var role="COOLANT VALVE"
var elite=false
var visual: Node3D
var max_health=36.0
var health=36.0
var destroyed=false
var active=false
var warning=false
var clock=0.0
var damage_clock=0.0
var field: Node3D
var lamp: OmniLight3D
var label: Label3D
func _ready() -> void:
	collision_layer=16
	collision_mask=0
	var c=CollisionShape3D.new(); var s=SphereShape3D.new(); s.radius=0.85; c.shape=s; add_child(c)
	visual=Node3D.new(); add_child(visual)
	var color=Color("9cbfff") if kind=="coolant" else Color("ffd780")
	role={"coolant":"COOLANT VALVE","arc":"ARC POWER CELL","machine":"VOLATILE MACHINERY"}[kind]
	Forge.box(visual,Vector3.ZERO,Vector3(1.2,1.5,1.2),Color("4d5261"))
	for y in [-0.5,0,0.5]: Forge.ring(visual,Vector3(0,y,0),0.85,0.07,color,1)
	lamp=Forge.light(visual,Vector3.ZERO,color,1,7)
	label=Forge.sign_text(visual,Vector3(0,2,0),role+" / SHOOT TO DISABLE",17,color)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	field=Node3D.new(); add_child(field)
	if kind=="arc":
		for i in range(5):
			var a=Vector3(-2+i*0.8,sin(i*2.1)*0.6,0)
			var b=Vector3(-1.2+i*0.8,sin((i+1)*2.1)*0.6,0)
			Forge.beam(field,a,b,0.09,color,2.5)
	elif kind=="coolant":
		for i in range(5):
			var cloud=Forge.sphere(field,Vector3(sin(i*2)*1.5,cos(i*3)*0.8,cos(i*2)*1.5),1.1,color,0.5)
			var m=cloud.material_override.duplicate(); m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; m.albedo_color=Color(0.3,0.65,1,0.23); cloud.material_override=m
	else:
		Forge.sphere(field,Vector3(0,0,0),0.5,Color("ff9464"),2)
	clock=hazard_id*1.1
func _physics_process(delta: float) -> void:
	if game.state!="playing" or game.map_open or destroyed: return
	clock+=delta
	var cycle=fmod(clock,7)
	warning=cycle>=2 and cycle<3
	active=cycle>=3 and cycle<5 and kind!="machine"
	field.visible=active or kind=="machine"
	lamp.light_energy=2.5 if active else (1.4+sin(clock*20)*0.7 if warning else 0.5)
	label.text=role+(" / LIVE / EVADE" if active else (" / WARNING" if warning else " / SHOOT TO DISABLE"))
	damage_clock=maxf(0,damage_clock-delta)
	if active and damage_clock<=0 and game.player.position.distance_to(position)<3.2 and game.clear_line(position,game.player.position):
		damage_clock=0.5
		var damage=3.0 if kind=="coolant" else 5.0
		game.combat_stats.hazard_damage+=damage*[0.65,1.0,1.3][game.difficulty]
		game.player.hurt(damage,position)
func hit(amount: float,_source: Vector3 = Vector3.INF,_explosive: bool = false) -> void:
	if destroyed: return
	health=maxf(0,health-amount)
	game.hit_confirm=1
	if health>0: return
	destroyed=true; active=false; warning=false; collision_layer=0; field.hide(); lamp.light_energy=0
	label.text=role+" / OFFLINE"; label.modulate=Color("7d98a0")
	game.score+=75
	game.explosion(position,Color("ffab78") if kind=="machine" else Color("9ebeff"),1)
	if kind=="machine":
		for drone in game.drones.duplicate():
			if drone.position.distance_to(position)<7 and game.clear_line(position,drone.position): drone.hit(95,position,true)
		if game.player.position.distance_to(position)<6 and game.clear_line(position,game.player.position): game.player.hurt(24,position)
func restore(entry: Dictionary) -> void:
	health=clampf(float(entry.get("health",36)),0,max_health)
	destroyed=bool(entry.get("destroyed",false))
	if destroyed:
		collision_layer=0; field.hide(); lamp.light_energy=0; label.text=role+" / OFFLINE"
