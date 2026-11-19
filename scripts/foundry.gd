extends StaticBody3D
const Forge=preload("res://scripts/forge.gd")
var game
var role="ROBOT FOUNDRY"
var elite=false
var visual: Node3D
var max_health=180.0
var health=180.0
var destroyed=false
var timer=2.5
var warning=false
var ids: Array=[]
var produced=0
var lamp: OmniLight3D
var label: Label3D
var rotor: Node3D
func _ready() -> void:
	collision_layer=16; collision_mask=0
	var shape=CollisionShape3D.new(); var box=BoxShape3D.new(); box.size=Vector3(2,2,1.3); shape.shape=box; add_child(shape)
	visual=Node3D.new(); add_child(visual)
	Forge.box(visual,Vector3.ZERO,Vector3(2,2,1.3),Color("343846"))
	Forge.box(visual,Vector3(0,-1.15,0),Vector3(2.6,0.3,1.9),Color("172735"))
	for side in [-1,1]:
		Forge.box(visual,Vector3(side*1.08,0,0),Vector3(0.24,2.2,1.6),Color("667382"))
		for face in [-1,1]:
			Forge.box(visual,Vector3(side*1.09,0,face*0.84),Vector3(0.12,1.75,0.07),Color("a67fe0"),0.6)
	for face in [-1,1]:
		Forge.box(visual,Vector3(0,0,face*0.69),Vector3(1.7,1.75,0.1),Color("101b28"))
		for y in [-0.9,0.9]:
			Forge.box(visual,Vector3(0,y,face*0.79),Vector3(1.6,0.13,0.16),Color("8b745c"))
		for x in [-0.65,0.65]:
			for y in [-0.75,0.75]: Forge.sphere(visual,Vector3(x,y,face*0.84),0.06,Color("b5c2c9"))
	rotor=Node3D.new(); visual.add_child(rotor)
	for face in [-1,1]:
		var ring=Forge.ring(rotor,Vector3(0,0,face*0.82),0.65,0.09,Color("d7a5ff"),1.3); ring.rotation.x=PI/2
		Forge.sphere(rotor,Vector3(0,0,face*0.78),0.3,Color("bc8cff"),2)
		for arm in range(4):
			var angle=arm*PI/2; var pos=Vector3(cos(angle)*0.72,sin(angle)*0.72,face*0.92)
			var vane=Forge.box(rotor,pos,Vector3(0.35,0.14,0.16),Color("b2b5c1")); vane.rotation.z=angle+0.4
	lamp=Forge.light(visual,Vector3(0,0,-1),Color("d7a5ff"),1,7)
	label=Forge.sign_text(visual,Vector3(0,2,0),"ROBOT FOUNDRY / DESTROY TO STOP",17,Color("d7a5ff")); label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
func _physics_process(delta: float) -> void:
	if game.state!="playing" or game.map_open or destroyed: return
	rotor.rotate_z(delta*(2 if warning else 0.4))
	if game.reactor_down or position.distance_to(game.player.position)>26 or not game.clear_line(position,game.player.position):
		warning=false; lamp.light_energy=0.4; return
	var alive=0
	for d in game.drones:
		if d.spawn_id in ids and not d.dead: alive+=1
	if alive>=3: warning=false; label.text="ROBOT FOUNDRY / CAPACITY 3"; return
	timer-=delta
	warning=timer<=2
	lamp.light_energy=1.4+sin(timer*16)*0.8 if warning else 0.6
	label.text="FOUNDRY / FABRICATING" if warning else "ROBOT FOUNDRY / RECHARGING"
	if timer<=0:
		var location=position+Vector3(3 if game.mission_index==2 else -3,1 if produced%2 else -1,0)
		var d=game.spawn_drone(location,"striker" if produced%3==2 else "scout")
		d.cooldown=1.5; d.alert_time=4; d.last_seen=game.player.position; ids.append(d.spawn_id); produced+=1
		game.impact(location,Color("d7a5ff"),8); game.sound.play_at("charge",position,0.4)
		timer=8; warning=false
func hit(amount: float,_source: Vector3 = Vector3.INF,_explosive: bool = false) -> void:
	if destroyed: return
	health=maxf(0,health-amount); game.hit_confirm=1
	if health<=0:
		destroyed=true; warning=false; collision_layer=0; lamp.light_energy=0; rotor.hide(); label.text="ROBOT FOUNDRY / OFFLINE"
		game.score+=400; game.explosion(position,Color("d7a5ff"),1.6)
		game.announce("ROBOT FOUNDRY OFFLINE / PRODUCTION STOPPED",3)
func snapshot() -> Dictionary: return {"health":health,"destroyed":destroyed,"timer":timer,"ids":ids.duplicate(),"produced":produced}
func restore(data: Dictionary) -> void:
	health=clampf(float(data.get("health",180)),0,180); destroyed=bool(data.get("destroyed",false)); timer=maxf(0.5,float(data.get("timer",2.5))); ids=data.get("ids",[]).duplicate(); produced=maxi(0,int(data.get("produced",0)))
	if destroyed: collision_layer=0; rotor.hide(); lamp.light_energy=0; label.text="ROBOT FOUNDRY / OFFLINE"
