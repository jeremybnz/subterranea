extends RefCounted
const Lore=preload("res://scripts/lore.gd")
const Courier=preload("res://scripts/rescue_drone.gd")
const Forge=preload("res://scripts/forge.gd")
var game
var items: Array=[]
var escort: CharacterBody3D
var crew_rescued=false
var triggers={}
var radio_queue: Array=[]
var radio_current={}
var radio_time=0.0
var interacting=false
var candidate={}
var progress=0.0
var candidate_id=""
var tick=0.0
var trail_time=0.0
var previous_positions={}
func _init(owner): game=owner
func build() -> void:
	var logs=[[Vector3(8,1,6),Vector3(-50,-41,-39),Vector3(7,44,-87)],[Vector3(-8,1,5),Vector3(58,2,-40),Vector3(7,47,-107)],[Vector3(8,1,14),Vector3(-58,2,-21),Vector3(-8,42,-108)]]
	for i in range(3): make_item("log",str(game.mission_index)+"_"+str(i),logs[game.mission_index][i],i)
	make_item("pod","crew",[Vector3(-49,-41,-52),Vector3(-5,47,-98),Vector3(-51,2,-33)][game.mission_index],0)
	make_item("cache",str(game.mission_index)+"_cache",[Vector3(-88,-43,-49),Vector3(60,6,-53),Vector3(9,43,-110)][game.mission_index],0)
	escort=Courier.new(); escort.game=game; game.add_child(escort)
func make_item(kind: String,id: String,pos: Vector3,index: int) -> void:
	var root=Node3D.new(); game.level.add_child(root); root.position=pos
	var color=Color("9dcdff") if kind=="log" else (Color("8ff2c0") if kind=="pod" else Color("ffce88"))
	if kind=="pod":
		Forge.box(root,Vector3.ZERO,Vector3(1.5,2.2,1.5),Color("667e79"))
		Forge.box(root,Vector3(0,0,0.8),Vector3(1.1,1.6,0.12),color,0.6)
		Forge.box(root,Vector3(0,0,0.9),Vector3(0.6,0.15,0.05),Color("effff2"),1)
		Forge.box(root,Vector3(0,0,0.9),Vector3(0.15,0.6,0.05),Color("effff2"),1)
	else:
		Forge.box(root,Vector3.ZERO,Vector3(0.8,0.7,0.5) if kind=="log" else Vector3(1.2,1,0.9),Color("405766"))
		Forge.box(root,Vector3(0,0,0.5),Vector3(0.65,0.4,0.1),color,1)
	Forge.ring(root,Vector3.ZERO,1.1 if kind=="pod" else 0.7,0.035,color,0.7).rotation.x=PI/2
	var label=Forge.sign_text(root,Vector3(0,1.8 if kind=="pod" else 1,0),{"pod":"CREW REFUGE","log":"DATA RECORDER","cache":"SURVEY CACHE"}[kind],18,color)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var claimed=id in game.campaign.data.logs if kind=="log" else (id in game.campaign.data.caches if kind=="cache" else false)
	root.visible=not claimed
	items.append({"node":root,"kind":kind,"id":id,"pos":pos,"index":index,"claimed":claimed,"name":label.text,"color":color})
func nearby() -> Dictionary:
	var nearest=4.3
	var found={}
	for item in items:
		if item.claimed or item.kind=="cache": continue
		var distance=game.player.position.distance_to(item.pos)
		if distance<nearest and game.clear_line(game.player.position,item.pos): found=item; nearest=distance
	if escort.status=="disabled" and game.player.position.distance_to(escort.position)<4.3 and game.clear_line(game.player.position,escort.position):
		found={"id":"repair","kind":"repair","name":"REPAIR COURIER","pos":escort.position,"color":Color("8ff2c0")}
	return found
func update(delta: float) -> void:
	radio_time=maxf(0,radio_time-delta)
	if radio_time<=0:
		radio_current={}
		if not radio_queue.is_empty(): start_radio(str(radio_queue.pop_front()))
	if game.mission_time>2: queue_radio("arrival")
	if game.relays_down>0: queue_radio("relay")
	if game.reactor_down: queue_radio("escape",true)
	tick-=delta
	if tick<=0:
		tick=0.1; candidate=nearby()
		var next_id=str(candidate.get("id",""))
		if next_id!=candidate_id: progress=0; candidate_id=next_id
	interacting=not candidate.is_empty()
	if interacting:
		if game.controls.held("interact"): progress+=delta
		else: progress=maxf(0,progress-delta*2)
		if progress>=1.5:
			interact(candidate); candidate={}; candidate_id=""; progress=0; tick=0
	for item in items:
		if item.kind=="cache" and not item.claimed and game.player.position.distance_to(item.pos)<1.8: collect_cache(item)
	update_trails(delta)
func interact(item: Dictionary) -> void:
	if item.kind=="repair":
		escort.repair(); game.store_checkpoint(); return
	if item.claimed: return
	if item.kind=="log":
		if not game.campaign.discover("logs",item.id): return
		item.claimed=true; item.node.hide()
		game.announce(Lore.LOGS[game.mission_index][item.index].title.to_upper()+" / JOURNAL UPDATED / PAUSE TO READ",4)
	elif item.kind=="pod":
		crew_rescued=true; item.claimed=true; item.node.hide(); game.score+=300
		escort.begin(item.pos+Vector3(0,1,0),["foundry","archive","west"][game.mission_index])
		queue_radio("crew",true)
		game.announce("CREW SECURED / +250 SALVAGE ON EXTRACTION / ESCORT COURIER FOR AN EXTRA BONUS",5)
	game.sound.play_tone("pickup",0.6); game.store_checkpoint()
func collect_cache(item: Dictionary) -> void:
	if item.claimed: return
	if not game.campaign.discover("caches",item.id,200,Lore.PAINTS[game.mission_index+1].id): return
	item.claimed=true; item.node.hide(); game.score+=500
	game.player.shield=minf(game.player.shield_max,game.player.shield+25); game.player.energy=minf(100,game.player.energy+40); game.player.missiles+=2
	game.announce("SURVEY CACHE / +200 SALVAGE / "+Lore.PAINTS[game.mission_index+1].title+" UNLOCKED",5)
	game.sound.play_tone("pickup",0.7); game.store_checkpoint()
func escort_delivered() -> void:
	game.score+=700
	game.announce("RESCUE COURIER SAFE / +300 EXTRA SALVAGE ON EXTRACTION",5)
	game.sound.play_tone("pickup",0.8); game.store_checkpoint()
func radio_by_id(id: String) -> Dictionary:
	for mission in Lore.RADIO:
		for entry in mission:
			if entry.id==id: return entry
	return {}
func queue_radio(event: String,urgent: bool = false) -> void:
	var id=str(game.mission_index)+"_"+event
	if triggers.has(id): return
	triggers[id]=true
	if urgent:
		radio_queue.clear(); start_radio(id)
	else: radio_queue.append(id)
func start_radio(id: String) -> void:
	radio_current=radio_by_id(id)
	if radio_current.is_empty(): return
	radio_time=8
	game.campaign.discover("radio",id)
	game.sound.play_tone("ui",0.4)
func markers() -> Array:
	var output=[]
	if escort.status in ["following","waiting","disabled"]:
		output.append({"pos":escort.position,"name":"COURIER / "+escort.status.to_upper(),"color":Color("8ff2c0")})
		return output
	var nearest=30.0; var best={}
	for item in items:
		var distance=game.player.position.distance_to(item.pos)
		if not item.claimed and distance<nearest and game.clear_line(game.player.position,item.pos): nearest=distance; best=item
	if not best.is_empty(): output.append({"pos":best.pos,"name":best.name,"color":best.color})
	return output
func paint() -> Dictionary:
	for entry in Lore.PAINTS:
		if entry.id==game.campaign.data.paint: return entry
	return Lore.PAINTS[0]
func apply_paint() -> void:
	paint_meshes(game.menu_ship)
	if is_instance_valid(game.player) and is_instance_valid(game.player.exterior): paint_meshes(game.player.exterior)
func paint_meshes(node: Node) -> void:
	if node is OmniLight3D: node.light_color=paint().accent
	if node is MeshInstance3D and node.material_override is ShaderMaterial and node.material_override.shader==preload("res://assets/shaders/engine_plume.gdshader"):
		node.material_override.set_shader_parameter("tint",paint().accent)
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var original=node.mesh.surface_get_material(i)
			if original is StandardMaterial3D and original.resource_name in ["Titanium","Armor","Cyan"]:
				var material=original.duplicate()
				material.albedo_color=paint().accent.darkened(0.85) if original.resource_name=="Cyan" else (paint().hull if original.resource_name=="Titanium" else paint().hull.darkened(0.5))
				if original.resource_name=="Cyan": material.emission=paint().accent
				node.set_surface_override_material(i,material)
	for child in node.get_children(): paint_meshes(child)
func select_paint(id: String) -> bool:
	if id not in game.campaign.data.paints: return false
	var previous=game.campaign.data.paint; game.campaign.data.paint=id
	if not game.campaign.save(): game.campaign.data.paint=previous; return false
	apply_paint(); game.sound.play_tone("ui",0.4); return true
func update_trails(delta: float) -> void:
	trail_time-=delta
	if trail_time>0: return
	trail_time=0.06
	var actors=game.drones.duplicate()
	actors.append(game.player)
	for shot in game.projectiles:
		if shot.friendly and is_instance_valid(shot.node): actors.append(shot.node)
	if escort.status in ["following","waiting"]: actors.append(escort)
	for actor in actors:
		if not is_instance_valid(actor): continue
		var id=actor.get_instance_id(); var here=actor.global_position
		if previous_positions.has(id) and here.distance_to(previous_positions[id])<3 and here.distance_to(previous_positions[id])>0.15 and game.player.position.distance_to(here)<42 and game.effects.size()<350 and game.graphics_preset>0:
			var color=actor.get_meta("trail_color",paint().accent if actor==game.player else (Color("8ff2c0") if actor==escort else Color("ffab76")))
			var tail=Forge.beam(game,previous_positions[id],here,0.055,color,1.5)
			game.effects.append({"node":tail,"life":0.32,"max":0.32,"velocity":Vector3.ZERO,"expand":false,"keep_scale":true})
		previous_positions[id]=here
func snapshot() -> Dictionary:
	return {"crew":crew_rescued,"triggers":triggers.duplicate(),"radio_queue":radio_queue.duplicate(),"radio_id":radio_current.get("id",""),"radio_time":radio_time,"escort":escort.snapshot()}
func restore(data: Dictionary) -> void:
	crew_rescued=bool(data.get("crew",false)); triggers=data.get("triggers",{}).duplicate(); radio_queue=data.get("radio_queue",[]).duplicate()
	radio_current=radio_by_id(str(data.get("radio_id",""))); radio_time=clampf(float(data.get("radio_time",0)),0,8)
	escort.restore(data.get("escort",{}))
	for item in items:
		item.claimed=item.id in game.campaign.data.logs if item.kind=="log" else (item.id in game.campaign.data.caches if item.kind=="cache" else crew_rescued)
		item.node.visible=not item.claimed
	candidate={}; candidate_id=""; progress=0; interacting=false
