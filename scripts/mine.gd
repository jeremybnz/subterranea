extends RefCounted
const Forge = preload("res://scripts/forge.gd")
const Door = preload("res://scripts/door.gd")
const TEAL = Color("66e4dc")
const ORANGE = Color("ffb76b")
const BLUE = Color("91b4ff")
const RED = Color("ff8766")

static func room(game: Node3D,center: Vector3,size: Vector3,openings: Dictionary,color: Color,title: String,hidden: bool = false) -> void:
	var windows={}
	if title in ["UPPER RELAY","ARCHIVE / BETA"]: windows["front"]=Vector2(14,8)
	elif title=="OVERSEER / CHAMBER": windows["front"]=Vector2(24,12)
	Forge.room(game.level,center,size,openings,color,title,windows)
	game.map_rooms.append({"center":center,"size":size,"title":title,"color":color,"hidden":hidden})

static func door(game: Node3D,pos: Vector3,turn: bool = false,locked: bool = false,secret: bool = false,title: String = "TRANSIT / AUTO",width: float = 10.0) -> Node3D:
	var node = Door.new()
	node.game = game
	node.width = width
	node.locked = locked
	node.secret = secret
	node.label = title
	game.level.add_child(node)
	node.position = pos
	if turn: node.rotation.y = PI/2
	game.doors.append(node)
	if locked and not secret: game.reactor_doors.append(node)
	return node

static func build(game: Node3D) -> void:
	room(game,Vector3.ZERO,Vector3(28,18,30),{"front":12},TEAL,"ARRIVAL")
	room(game,Vector3(0,0,-22),Vector3(12,10,14),{"front":12,"back":12},TEAL,"")
	room(game,Vector3(0,0,-44),Vector3(32,22,30),{"front":12,"back":12,"left":10,"right":10,"top":12},TEAL,"NEXUS")
	for side in [-1,1]:
		room(game,Vector3(side*24,0,-44),Vector3(16,10,10),{"left":10,"right":10},ORANGE,"")
		var openings = {"right":10,"bottom":12} if side==-1 else {"left":10,"front":10}
		room(game,Vector3(side*43,0,-44),Vector3(22,18,26),openings,ORANGE,"FOUNDRY LIFT" if side==-1 else "COOLANT WORKS")
	room(game,Vector3(0,0,-67),Vector3(12,10,16),{"front":12,"back":12},RED,"")
	room(game,Vector3(0,0,-91),Vector3(36,30,32),{"back":12,"right":10},RED,"REACTOR / 07")
	# Upper turbine deck is reached through a continuous 24m flight shaft.
	shaft(game,Vector3(0,23,-44),24,BLUE)
	room(game,Vector3(0,44,-44),Vector3(32,18,30),{"bottom":12,"front":12},BLUE,"TURBINE DECK")
	room(game,Vector3(0,44,-68),Vector3(12,10,18),{"front":12,"back":12},BLUE,"")
	room(game,Vector3(0,44,-90),Vector3(28,18,26),{"back":12,"right":10},BLUE,"UPPER RELAY")
	# A second vertical branch drops to the foundry and its concealed supply vault.
	shaft(game,Vector3(-43,-21,-44),24,ORANGE)
	room(game,Vector3(-43,-43,-44),Vector3(32,20,32),{"top":12,"left":10},ORANGE,"LOWER FOUNDRY")
	room(game,Vector3(-66,-43,-44),Vector3(14,10,10),{"left":10,"right":10},ORANGE,"",true)
	room(game,Vector3(-83,-43,-44),Vector3(20,14,22),{"right":10},TEAL,"RESERVE / 09",true)
	# Pump hall loops back to the reactor, with a second interlocked blast door.
	room(game,Vector3(43,0,-66),Vector3(10,10,18),{"front":10,"back":10},TEAL,"")
	room(game,Vector3(43,0,-91),Vector3(26,20,32),{"back":10,"left":10,"top":12},TEAL,"PUMP HALL")
	room(game,Vector3(24,0,-91),Vector3(12,10,10),{"left":10,"right":10},RED,"")
	game.core_door = door(game,Vector3(0,0,-74.6),false,true,false,"REACTOR / SEALED",12)
	door(game,Vector3(18.4,0,-91),true,true,false,"REACTOR / SEALED")
	door(game,Vector3(43,0,-58),false,false,false,"COOLANT / AUTO")
	door(game,Vector3(0,44,-60),false,false,false,"TURBINES / AUTO",12)
	game.secret_door = door(game,Vector3(-59.4,-43,-44),true,true,true,"MAINTENANCE / 09")
	game.spawn_target(Vector3(-43,-43,-50),"relay","FOUNDRY RELAY")
	game.spawn_target(Vector3(45,1,-96),"relay","COOLANT RELAY")
	game.spawn_target(Vector3(0,44,-94),"relay","TURBINE RELAY")
	game.spawn_target(Vector3(0,0,-96),"reactor","REACTOR CORE")
	landmarks(game)
	for pos in [Vector3(-7,0,1),Vector3(-49,-43,-37),Vector3(-7,44,-48),Vector3(47,-3,-84)]: game.spawn_pickup(pos,"shield")
	for pos in [Vector3(7,0,1),Vector3(-38,-39,-45),Vector3(7,44,-48),Vector3(39,3,-85)]: game.spawn_pickup(pos,"missiles")
	for pos in [Vector3(-85,-43,-42),Vector3(-79,-43,-48)]: game.spawn_pickup(pos,"missiles")
	game.spawn_pickup(Vector3(-85,-43,-48),"shield")
	game.make_display_ship()

static func shaft(game: Node3D,pos: Vector3,length: float,color: Color) -> void:
	var root = Node3D.new()
	game.level.add_child(root)
	root.position = pos
	root.rotation.x = PI/2
	Forge.room(root,Vector3.ZERO,Vector3(12,12,length),{"front":12,"back":12},color,"")
	game.map_links.append([pos-Vector3(0,length/2,0),pos+Vector3(0,length/2,0)])
	for y in [-8,0,8]:
		var ring = Forge.ring(game.level,pos+Vector3(0,y,0),5.6,0.045,color,1.8)
		game.machinery.append({"node":ring,"axis":Vector3.UP,"speed":0.2})

static func turbine(game: Node3D,pos: Vector3,radius: float,color: Color) -> void:
	var root = Node3D.new()
	game.level.add_child(root)
	root.position = pos
	var ring = Forge.ring(root,Vector3.ZERO,radius,0.32,Color("556d7a"))
	ring.rotation.x = PI/2
	var rotor = Node3D.new()
	root.add_child(rotor)
	Forge.sphere(rotor,Vector3.ZERO,0.7,Color("253e4a"))
	for i in range(8):
		var angle = i*TAU/8
		var blade = Forge.box(rotor,Vector3(cos(angle)*radius*0.53,sin(angle)*radius*0.53,0),Vector3(radius*0.7,0.38,0.3),Color("5c7686"))
		blade.rotation.z = angle+0.25
		Forge.sphere(rotor,Vector3(cos(angle)*radius*0.83,sin(angle)*radius*0.83,0),0.07,color,1.6)
	game.machinery.append({"node":rotor,"axis":Vector3.BACK,"speed":0.7})
	Forge.light(root,Vector3(0,0,1),color,1.8,14)
	game.ambient_sources.append({"pos":pos,"kind":"machine","volume":0.6})

static func landmarks(game: Node3D) -> void:
	var level = game.level
	for radius in [4.7,5.0,5.4]:
		var ring = Forge.ring(level,Vector3(0,0,13.8),radius,0.05,ORANGE,2)
		ring.rotation.x = PI/2
	Forge.sign_text(level,Vector3(0,6,14.5),"EXTRACTION / 07",55,ORANGE,PI)
	Forge.sign_text(level,Vector3(-8,4,-14.5),"NEREID",90,TEAL)
	Forge.sign_text(level,Vector3(-8,2.8,-14.4),"DEEP MINING OPERATIONS",22,Color("a3bdc4"))
	Forge.sign_text(level,Vector3(8,3,-14.5),"07",160,Color("647c86"))
	Forge.sign_text(level,Vector3(0,7,-58.5),"REACTOR ACCESS",40,RED)
	Forge.sign_text(level,Vector3(-9,5,-58.5),"01 / FOUNDRY",28,ORANGE)
	Forge.sign_text(level,Vector3(9,5,-58.5),"02 / COOLANT",28,TEAL)
	Forge.sign_text(level,Vector3(0,9,-52),"03 / TURBINES  ^",32,BLUE)
	Forge.sign_text(level,Vector3(-43,3,-56.5),"DESCEND / 42 M",40,ORANGE)
	Forge.sign_text(level,Vector3(43,3,-56.5),"PUMP HALL / AHEAD",32,TEAL)
	for z in [-10,-5,0,5,10]:
		for side in [-1,1]:
			Forge.box(level,Vector3(side*11,-7,z),Vector3(3,3,3.2),Color("45545a"),0,true)
			Forge.box(level,Vector3(side*11,-5.46,z),Vector3(2.5,0.06,0.14),ORANGE,1)
	# Huge moving flywheels establish the upper deck's identity.
	for x in [-10,10]: turbine(game,Vector3(x,44,-57.7),3.8,BLUE)
	for x in [-9,9]: turbine(game,Vector3(x,44,-102.6),3.2,BLUE)
	# Lower foundry: a suspended, rotating drill and a recessed glowing furnace.
	var drill = Node3D.new()
	level.add_child(drill)
	drill.position = Vector3(-53,-43,-53)
	for i in range(6):
		var ring = Forge.ring(drill,Vector3(0,-4+i*1.5,0),2.2-i*0.21,0.18,Color("7b6555"))
		ring.rotation.z = 0.12
	game.machinery.append({"node":drill,"axis":Vector3.UP,"speed":0.65})
	Forge.box(level,Vector3(-43,-52.8,-56),Vector3(18,0.12,5),Color("ff8a39"),1.1)
	Forge.light(level,Vector3(-43,-49,-54),ORANGE,3,20)
	Forge.sign_text(level,Vector3(-43,-37,-59.5),"F O U N D R Y",65,ORANGE)
	Forge.sign_text(level,Vector3(-58.4,-41,-49),"09 / RESERVE",18,Color("857d6b"),PI/2)
	game.ambient_sources.append({"pos":Vector3(-53,-43,-53),"kind":"machine","volume":0.65})
	# Coolant reservoirs and animated collars occupy the edges of the pump hall.
	for pos in [Vector3(35,-5,-84),Vector3(51,-5,-84),Vector3(35,-5,-101),Vector3(51,-5,-101)]:
		Forge.box(level,pos,Vector3(3.6,7,3.6),Color("344f5b"),0,true)
		for h in [-2,0,2]:
			var ring = Forge.ring(level,pos+Vector3(0,h,0),2.1,0.055,TEAL,1.5)
			game.machinery.append({"node":ring,"axis":Vector3.UP,"speed":0.3})
	for x in [-1,1]:
		Forge.beam(level,Vector3(x*11,-14,-96),Vector3(x*3,-1,-96),0.8,Color("3d4c53"))
		Forge.beam(level,Vector3(x*11,14,-96),Vector3(x*3,1,-96),0.8,Color("3d4c53"))
	var cage = Forge.ring(level,Vector3(0,0,-96),6,0.15,RED,0.7)
	cage.rotation.x = PI/2
	game.machinery.append({"node":cage,"axis":Vector3.UP,"speed":0.14})
	game.ambient_sources.append({"pos":Vector3(0,0,-96),"kind":"machine","volume":0.8})
	# Dust motes are one instanced draw call per chamber.
	for center in [Vector3(0,0,-44),Vector3(0,44,-44),Vector3(-43,-43,-44),Vector3(43,0,-91)]:
		var mesh = SphereMesh.new()
		mesh.radius=0.025
		mesh.height=0.05
		mesh.radial_segments=4
		mesh.rings=2
		var multi = MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.mesh=mesh
		multi.instance_count=60
		for i in range(60): multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(randf_range(-10,10),randf_range(-7,7),randf_range(-10,10))))
		var motes = MultiMeshInstance3D.new()
		motes.multimesh=multi
		motes.material_override=Forge.material(Color("477d8a"),0.3)
		level.add_child(motes)
		motes.position=center
		game.machinery.append({"node":motes,"axis":Vector3.UP,"speed":0.018})
