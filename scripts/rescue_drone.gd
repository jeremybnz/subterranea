extends CharacterBody3D
const Forge=preload("res://scripts/forge.gd")
var game
var status="dormant"
var integrity=160.0
var route: Array=[]
var waypoint=0
var last_hit=0.0
var visual: Node3D
var flight_state: Node
var lamp: OmniLight3D
func _ready() -> void:
	collision_layer=0; collision_mask=1; motion_mode=CharacterBody3D.MOTION_MODE_FLOATING
	var c=CollisionShape3D.new(); var s=SphereShape3D.new(); s.radius=0.55; c.shape=s; add_child(c)
	visual=Node3D.new(); add_child(visual)
	var hull=load("res://assets/models/courier.glb").instantiate(); visual.add_child(hull)
	preload("res://scripts/ship_visuals.gd").attach(hull,"courier")
	flight_state=preload("res://scripts/flight_state.gd").new(); flight_state.setup(game,self,hull,"courier")
	lamp=Forge.light(visual,Vector3(0,0,-0.8),Color("76e9df"),1,5)
	hide()
func begin(pos: Vector3,start: String) -> void:
	if status!="dormant": return
	position=pos; route=[pos,game.nav_nodes[start]]
	for key in game.path_to(start,"dock"): route.append(game.nav_nodes[key])
	route.append(game.extraction)
	waypoint=1; status="following"; collision_layer=32; show()
func _physics_process(delta: float) -> void:
	if game.state!="playing" or game.map_open or status in ["dormant","disabled","delivered"]: return
	last_hit=maxf(0,last_hit-delta)
	if last_hit<=0: integrity=minf(160,integrity+delta*5)
	if game.player.position.distance_to(position)>20:
		status="waiting"; velocity=velocity.move_toward(Vector3.ZERO,delta*16); move_and_slide(); return
	status="following"
	if waypoint>=route.size():
		deliver(); return
	var goal: Vector3=route[waypoint]
	if position.distance_to(goal)<1.0:
		waypoint+=1; return
	var dir=(goal-position).normalized()
	velocity=velocity.move_toward(dir*5.5,delta*14)
	move_and_slide()
	if dir.length()>0.1: visual.look_at(position+dir,Vector3.UP if absf(dir.y)<0.98 else Vector3.RIGHT)
func hurt(amount: float,_source: Vector3 = Vector3.INF) -> void:
	if status not in ["following","waiting"]: return
	flight_state.flash(_source)
	integrity=maxf(0,integrity-amount*[0.65,1.0,1.3][game.difficulty]); last_hit=4
	if integrity<=0:
		status="disabled"; velocity=Vector3.ZERO; collision_layer=0; lamp.light_color=Color("ffad70")
		game.announce("RESCUE COURIER DISABLED / APPROACH AND HOLD INTERACT TO REPAIR",5)
func repair() -> void:
	if status!="disabled": return
	integrity=100; last_hit=4; status="following"; collision_layer=32; lamp.light_color=Color("76e9df")
	game.announce("COURIER REPAIRED / STAY WITHIN 20 M",3)
func deliver() -> void:
	if status=="delivered": return
	status="delivered"; collision_layer=0; velocity=Vector3.ZERO
	game.exploration.escort_delivered()
func snapshot() -> Dictionary:
	var points=[]
	for pos in route: points.append(game.to_array(pos))
	return {"status":status,"pos":game.to_array(position),"integrity":integrity,"route":points,"waypoint":waypoint,"last_hit":last_hit}
func restore(data: Dictionary) -> void:
	status=str(data.get("status","dormant")); position=game.to_vector(data.get("pos",[])); integrity=clampf(float(data.get("integrity",160)),0,160)
	route.clear()
	for pos in data.get("route",[]): route.append(game.to_vector(pos))
	waypoint=clampi(int(data.get("waypoint",0)),0,route.size()); last_hit=float(data.get("last_hit",0))
	visible=status!="dormant"; collision_layer=32 if status in ["following","waiting"] else 0
	lamp.light_color=Color("ffad70") if status=="disabled" else Color("76e9df")
