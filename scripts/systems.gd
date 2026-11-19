extends RefCounted
const Forge=preload("res://scripts/forge.gd")
const Mine=preload("res://scripts/mine.gd")
const Door=preload("res://scripts/door.gd")
const Foundry=preload("res://scripts/foundry.gd")
var game
var props: Array=[]
var foundries: Array=[]
var gate: Node3D
var gate_edge: Array=[]
var key_name=""
var key_pos=Vector3.ZERO
var key_node: Node3D
var switch_pos=Vector3.ZERO
var switch_node: Node3D
var has_key=false
var overridden=false
var progress=0.0
var interacting=false
var color=Color("89bbff")
func _init(owner): game=owner
func build() -> void:
	var index=game.mission_index
	key_name=["BLUE","YELLOW","RED"][index]; color=[Color("89bbff"),Color("ffe180"),Color("ff977e")][index]
	if index==0:
		Mine.room(game,Vector3(25.5,44,-90.5),Vector3(23,10,10),{"left":10,"right":10},color,"SECURITY TRANSFER")
		Mine.room(game,Vector3(43,44,-91),Vector3(12,12,12),{"left":10,"bottom":12},color,"PUMP SERVICE LIFT")
		Mine.shaft(game,Vector3(43,24,-91),28,color)
		game.nav_nodes["transfer"]=Vector3(43,44,-91); game.nav_titles["transfer"]="PUMP SERVICE LIFT"
		game.nav_edges.append_array([["upper","transfer"],["transfer","pump"]]); gate_edge=["upper","transfer"]
		make_gate(Vector3(14.3,44,-90),Vector3(0,PI/2,0),10)
		key_pos=Vector3(-38,-41,-37); switch_pos=Vector3(40,45,-94)
	elif index==1:
		Mine.shaft(game,Vector3(0,26,-96),22,color)
		game.nav_nodes["transfer"]=Vector3(0,26,-96); game.nav_titles["transfer"]="ARCHIVE SERVICE SHAFT"
		game.nav_edges.append_array([["archive","transfer"],["transfer","core"]]); gate_edge=["archive","transfer"]
		make_gate(Vector3(0,26,-96),Vector3(PI/2,0,0),12)
		key_pos=Vector3(57,3,-54); switch_pos=Vector3(7,47,-96)
	else:
		Mine.room(game,Vector3(-52,0,-89),Vector3(10,10,18),{"front":10,"back":10},color,"REACTOR SERVICE")
		Mine.room(game,Vector3(-52,0,-100),Vector3(12,12,12),{"back":10,"right":12},color,"SECURITY EXCHANGE")
		Mine.room(game,Vector3(-39,0,-100),Vector3(14,10,12),{"left":12,"right":12},color,"")
		game.nav_nodes["service"]=Vector3(-52,0,-100); game.nav_titles["service"]="SECURITY EXCHANGE"
		game.nav_edges.append_array([["vault","service"],["service","core"]]); gate_edge=["service","core"]
		make_gate(Vector3(-32.3,0,-100),Vector3(0,PI/2,0),12)
		key_pos=Vector3(7,42,-106); switch_pos=Vector3(-59,3,-32)
	key_node=Node3D.new(); game.level.add_child(key_node); key_node.position=key_pos; props.append(key_node)
	Forge.box(key_node,Vector3.ZERO,Vector3(0.8,0.45,0.15),color,1.2)
	Forge.ring(key_node,Vector3.ZERO,0.8,0.04,color,1).rotation.x=PI/2
	var label=Forge.sign_text(key_node,Vector3(0,1,0),key_name+" SERVICE KEY",17,color); label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	switch_node=Node3D.new(); game.level.add_child(switch_node); switch_node.position=switch_pos; props.append(switch_node)
	Forge.box(switch_node,Vector3.ZERO,Vector3(1.2,0.9,0.6),Color("405263"))
	Forge.box(switch_node,Vector3(0,0,0.35),Vector3(0.8,0.5,0.1),color,0.8)
	label=Forge.sign_text(switch_node,Vector3(0,1,0),"LOCAL SECURITY OVERRIDE",17,color); label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var factory=Foundry.new(); factory.game=game; game.level.add_child(factory)
	factory.position=[Vector3(46,44,-92),Vector3(3,31,-96),Vector3(-55,0,-100)][index]; foundries.append(factory)
func make_gate(pos: Vector3,rotation: Vector3,width: float) -> void:
	gate=Door.new(); gate.game=game; gate.locked=true; gate.label=key_name+" SERVICE LOCK"; gate.width=width; gate.height=width; game.level.add_child(gate); gate.position=pos; gate.rotation=rotation; game.doors.append(gate)
	for prompt in gate.prompts: prompt.text=key_name+" KEY OR LOCAL OVERRIDE"
func edge_locked(edge: Array) -> bool: return gate!=null and gate.locked and (edge==gate_edge or edge==[gate_edge[1],gate_edge[0]])
func update(delta: float) -> void:
	if not has_key and game.player.position.distance_to(key_pos)<2:
		has_key=true; key_node.hide(); gate.unlock(); game.score+=100; game.sound.play_tone("pickup"); game.announce(key_name+" SERVICE KEY / OPTIONAL ROUTE UNLOCKED",3); game.store_checkpoint()
	interacting=not overridden and not game.exploration.interacting and game.player.position.distance_to(switch_pos)<4.3 and game.clear_line(game.player.position,switch_pos)
	if interacting:
		if game.controls.held("interact"): progress+=delta
		else: progress=maxf(0,progress-delta*2)
		if progress>=1.5:
			overridden=true; gate.unlock(); game.score+=100; game.announce("LOCAL OVERRIDE / OPTIONAL ROUTE UNLOCKED",3); game.store_checkpoint()
	else: progress=0
func snapshot() -> Dictionary:
	var data={"key":has_key,"override":overridden,"foundries":[]}
	for f in foundries: data.foundries.append(f.snapshot())
	return data
func restore(data: Dictionary) -> void:
	has_key=bool(data.get("key",false)); overridden=bool(data.get("override",false)); key_node.visible=not has_key
	if has_key or overridden: gate.unlock()
	for i in range(mini(foundries.size(),data.get("foundries",[]).size())): foundries[i].restore(data.foundries[i])
