extends RefCounted
## Rotatable orthographic 3D survey; flight is paused while inspecting it.
var game
var seen: Array=[]
var seen_links: Array=[]
var yaw=-0.35
var pitch=0.9
var zoom=4.0
var center=Vector3(-12,0,-48)
var pan=Vector2.ZERO
var pin=""
var selected=""
var objectives=true
var contacts=true
var supplies=true
var drag=0
var moved=false
var tick=0.0
var plot=Rect2(70,185,1100,570)
func _init(owner): game=owner
func basis() -> Basis: return Basis(Vector3.RIGHT,pitch)*Basis(Vector3.UP,yaw)
func project(pos: Vector3) -> Vector2:
	var point=basis()*(pos-center)
	return plot.get_center()+pan+Vector2(point.x,-point.y)*zoom
func update(delta: float) -> void:
	tick-=delta
	if tick>0: return
	tick=0.15
	for i in range(game.map_rooms.size()):
		var room=game.map_rooms[i]
		if room.hidden and not game.is_secret_open(): continue
		if AABB(room.center-room.size/2-Vector3.ONE,room.size+Vector3.ONE*2).has_point(game.player.position) and i not in seen: seen.append(i)
	for i in range(game.map_links.size()):
		if link_distance(game.player.position,game.map_links[i])<7 and i not in seen_links: seen_links.append(i)
	if not pin.is_empty() and game.nav_nodes.has(pin) and game.player.position.distance_to(game.nav_nodes[pin])<3:
		pin=""; game.announce("NAVIGATION MARKER REACHED",2)
func link_distance(pos: Vector3,link: Array) -> float:
	var direction: Vector3=link[1]-link[0]
	var t=clampf((pos-link[0]).dot(direction)/maxf(0.01,direction.length_squared()),0,1)
	return pos.distance_to(link[0]+direction*t)
func known(pos: Vector3) -> bool:
	for i in seen_links:
		if i<game.map_links.size() and link_distance(pos,game.map_links[i])<7: return true
	for i in seen:
		if i>=game.map_rooms.size(): continue
		var room=game.map_rooms[i]
		if AABB(room.center-room.size/2-Vector3.ONE*2,room.size+Vector3.ONE*4).has_point(pos): return true
	return false
func nodes() -> Array:
	var result=[]
	for key in game.nav_nodes:
		if key in ["secret","vault"] and not game.is_secret_open(): continue
		if known(game.nav_nodes[key]): result.append(key)
	return result
func recenter() -> void:
	center=game.player.position; pan=Vector2.ZERO; yaw=-0.35; pitch=0.9; zoom=4
func place_marker(key: String) -> bool:
	if key not in nodes(): return false
	pin=key; selected=key; game.nav_hint=game.route_hint(); game.sound.play_tone("ui",0.3); return true
func cycle_node(direction: int) -> void:
	var available=nodes()
	if available.is_empty(): return
	var i=available.find(selected); selected=available[posmod(i+direction,available.size())]
func input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var at=event.position*Vector2(1600,900)/game.get_viewport().get_visible_rect().size
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom=clampf(zoom*1.15,1.5,12)
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom=clampf(zoom/1.15,1.5,12)
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
			if event.pressed:
				if event.button_index==MOUSE_BUTTON_LEFT and at.x>=1210:
					var row=int((at.y-235)/55)
					if at.y>=235 and at.y<510:
						match row:
							0: recenter()
							1: objectives=not objectives
							2: contacts=not contacts
							3: supplies=not supplies
							4: pin=""
						return true
				drag=event.button_index; moved=false
			else:
				if drag==MOUSE_BUTTON_LEFT and not moved:
					var best=""; var distance=20.0
					for key in nodes():
						var d=project(game.nav_nodes[key]).distance_to(at)
						if d<distance: best=key; distance=d
					if not best.is_empty(): place_marker(best)
				drag=0
	elif event is InputEventMouseMotion and drag!=0:
		if event.relative.length()>1: moved=true
		if drag==MOUSE_BUTTON_LEFT:
			yaw+=event.relative.x*0.008; pitch=clampf(pitch+event.relative.y*0.008,-1.4,1.4)
		else: pan+=event.relative
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R: recenter()
			KEY_1: objectives=not objectives
			KEY_2: contacts=not contacts
			KEY_3: supplies=not supplies
			KEY_DELETE,KEY_BACKSPACE: pin=""
			KEY_BRACKETLEFT: cycle_node(-1)
			KEY_BRACKETRIGHT: cycle_node(1)
			KEY_ENTER: place_marker(selected)
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A: place_marker(selected)
			JOY_BUTTON_X: objectives=not objectives; contacts=not contacts; supplies=not supplies
			JOY_BUTTON_Y: recenter()
			JOY_BUTTON_DPAD_LEFT: cycle_node(-1)
			JOY_BUTTON_DPAD_RIGHT: cycle_node(1)
			JOY_BUTTON_LEFT_SHOULDER: zoom=clampf(zoom/1.15,1.5,12)
			JOY_BUTTON_RIGHT_SHOULDER: zoom=clampf(zoom*1.15,1.5,12)
	return true
func move(delta: float) -> void:
	var c=game.controls
	yaw+=c.axis("look_left","look_right")*delta
	pitch=clampf(pitch+c.axis("look_up","look_down")*delta,-1.4,1.4)
	pan+=Vector2(c.axis("left","right"),c.axis("forward","reverse"))*delta*180
func segment(hud,a: Vector3,b: Vector3,color: Color,width: float = 1) -> void:
	var first=project(a); var second=project(b)
	if plot.has_point(first) and plot.has_point(second): hud.line(first,second,color,width)
func draw(hud) -> void:
	hud.draw_rect(Rect2(0,0,1600,900),Color("06121b")); hud.brand(Vector2(65,66),true)
	hud.text_at(Vector2(65,114),("TRAINING" if game.training_mode else game.mission_info().location)+" / 3D AUTOMAP",27,hud.C)
	hud.text_at(Vector2(65,147),"FLIGHT PAUSED / "+game.controls.label("map")+" OR ESC TO CLOSE / CLICK A SURVEY NODE TO SET A MARKER",12,hud.MUTED,true)
	hud.draw_rect(plot,Color("0b202b")); hud.draw_rect(plot,Color("2a4d5c"),false,1)
	var rooms=[]
	for i in seen:
		if i<game.map_rooms.size(): rooms.append(game.map_rooms[i])
	for room in rooms:
		var corners=[]; var half=room.size/2
		for y in [-1,1]:
			for z in [-1,1]:
				for x in [-1,1]: corners.append(room.center+Vector3(x*half.x,y*half.y,z*half.z))
		for i in range(8):
			for bit in [1,2,4]:
				var other=i^bit
				if i<other: segment(hud,corners[i],corners[other],Color(room.color,0.55),1)
	for i in seen_links:
		if i<game.map_links.size(): segment(hud,game.map_links[i][0],game.map_links[i][1],Color("84a8d1"),3)
	for key in nodes():
		var at=project(game.nav_nodes[key])
		if not plot.grow(-15).has_point(at): continue
		hud.draw_circle(at,4,hud.A if key==pin else (hud.WHITE if key==selected else hud.C))
		if key in [pin,selected]: hud.text_at(at+Vector2(8,-9),game.nav_titles[key].left(23),11,hud.A,true)
	for edge in game.nav_edges:
		if edge[0] in nodes() and edge[1] in nodes(): segment(hud,game.nav_nodes[edge[0]],game.nav_nodes[edge[1]],Color("b08a52") if not game.training_mode and game.systems.edge_locked(edge) else Color("315365"))
	if objectives:
		for target in game.targets:
			if not known(target.pos): continue
			var at=project(target.pos)
			if plot.grow(-20).has_point(at):
				hud.draw_circle(at,6,hud.C if target.alive else hud.MUTED)
				hud.text_at(at+Vector2(9,16),target.name.left(21),10,hud.MUTED,true)
	if contacts:
		for d in game.drones:
			if known(d.position) and plot.has_point(project(d.position)): hud.draw_circle(project(d.position),3,Color("ff896b"))
	if supplies:
		for item in game.pickups:
			if known(item.pos) and plot.has_point(project(item.pos)): hud.draw_rect(Rect2(project(item.pos)-Vector2(2,2),Vector2(4,4)),hud.A)
	if not game.training_mode:
		if not game.systems.has_key and known(game.systems.key_pos) and plot.has_point(project(game.systems.key_pos)): hud.draw_circle(project(game.systems.key_pos),5,game.systems.color)
		for f in game.systems.foundries:
			if known(f.position) and plot.has_point(project(f.position)): hud.draw_rect(Rect2(project(f.position)-Vector2(5,5),Vector2(10,10)),hud.MUTED if f.destroyed else Color("d7a5ff"),false,2)
	var ship=project(game.player.position)
	if plot.has_point(ship): hud.draw_arc(ship,10,0,TAU,20,hud.C,2); hud.draw_circle(ship,3,hud.WHITE)
	hud.panel(Rect2(1210,185,325,570),0.95)
	hud.text_at(Vector2(1230,218),"SURVEY %d / %d" % [seen.size(),game.map_rooms.size()],20,hud.C,true)
	var buttons=["RECENTER / R","OBJECTIVES / "+("ON" if objectives else "OFF"),"CONTACTS / "+("ON" if contacts else "OFF"),"SUPPLIES / "+("ON" if supplies else "OFF"),"CLEAR MARKER / DEL"]
	for i in range(5):
		hud.draw_rect(Rect2(1225,235+i*55,295,42),Color("193440")); hud.text_at(Vector2(1240,262+i*55),buttons[i],14,hud.WHITE,true)
	hud.wrapped(Vector2(1230,550),"MARKER / "+(game.nav_titles.get(pin,"NONE") if not pin.is_empty() else "NONE"),280,16,hud.A)
	hud.wrapped(Vector2(1230,620),"Pins guide along accessible routes. Extraction takes priority when the escape timer starts.",280,15,hud.MUTED)
	hud.text_at(Vector2(70,798),"MOUSE: LEFT DRAG ROTATE / RIGHT DRAG PAN / WHEEL ZOOM / R RECENTER / 1-3 FILTERS",12,hud.MUTED,true)
	hud.text_at(Vector2(70,830),"PAD: RIGHT STICK ROTATE / LEFT STICK PAN / LB-RB ZOOM / D-PAD SELECT / A PIN / B CLOSE",12,hud.MUTED,true)
func snapshot() -> Dictionary: return {"seen":seen.duplicate(),"links":seen_links.duplicate(),"pin":pin,"yaw":yaw,"pitch":pitch,"zoom":zoom,"pan":[pan.x,pan.y],"center":game.to_array(center)}
func restore(data: Dictionary) -> void:
	seen_links.clear()
	for i in data.get("links",[]):
		if (i is int or i is float) and i>=0 and i<game.map_links.size() and int(i) not in seen_links: seen_links.append(int(i))
	seen.clear()
	for i in data.get("seen",[]):
		if (i is int or i is float) and i>=0 and i<game.map_rooms.size() and int(i) not in seen: seen.append(int(i))
	pin=str(data.get("pin","")); yaw=float(data.get("yaw",-0.35)); pitch=clampf(float(data.get("pitch",0.9)),-1.4,1.4); zoom=clampf(float(data.get("zoom",4)),1.5,12)
	var v=data.get("pan",[0,0]); pan=Vector2(v[0],v[1]) if v is Array and v.size()==2 else Vector2.ZERO
	center=game.to_vector(data.get("center",[]),Vector3(-12,0,-48)); update(1)
