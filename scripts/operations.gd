extends RefCounted
const Mine=preload("res://scripts/mine.gd")
const Forge=preload("res://scripts/forge.gd")
const Boss=preload("res://scripts/boss.gd")
const ICE=Color("9ebeff")
const TEAL=Color("6edcde")
const HEAT=Color("ffa76d")
const RED=Color("f57960")

static func build(game: Node3D,index: int) -> void:
	if index==1: cryo(game)
	else: fortress(game)
	game.make_display_ship()
	for room in game.map_rooms:
		if room.size.x>20 and not room.hidden:
			var color=room.color
			for side in [-1,1]:
				var pos=room.center+Vector3(side*(room.size.x/2-3),-room.size.y/2+2,room.size.z/2-4)
				Forge.box(game.level,pos,Vector3(2,3,2),Color("3d5362"),0,true)
				Forge.box(game.level,pos+Vector3(0,1.55,0),Vector3(1.7,0.05,0.1),color,0.7)
	for radius in [4.7,5.0,5.4]:
		var ring=Forge.ring(game.level,game.extraction+Vector3(0,0,2),radius,0.06,HEAT,1.4)
		ring.rotation.x=PI/2
	Forge.sign_text(game.level,game.extraction+Vector3(0,5.7,2.1),"EXTRACTION / KE STREL",36,HEAT,PI)

static func cryo(game: Node3D) -> void:
	game.depth=1960
	var rooms=[
		[Vector3.ZERO,Vector3(30,18,30),{"front":12},"BOREAS / ARRIVAL"],
		[Vector3(0,0,-24),Vector3(12,10,18),{"front":12,"back":12},""],
		[Vector3(0,0,-48),Vector3(36,22,30),{"front":12,"back":12,"left":12,"right":12,"top":12},"CRYO NEXUS"],
		[Vector3(-28,0,-48),Vector3(20,10,12),{"left":12,"right":12},""],
		[Vector3(28,0,-48),Vector3(20,10,12),{"left":12,"right":12},""],
		[Vector3(-52,0,-48),Vector3(28,22,32),{"right":12,"front":10},"ARCHIVE / ALPHA"],
		[Vector3(52,0,-48),Vector3(28,22,32),{"left":12},"ARCHIVE / BETA"],
		[Vector3(0,47,-48),Vector3(32,20,32),{"bottom":12,"front":12},"FREEZER DECK"],
		[Vector3(0,47,-74),Vector3(12,10,20),{"front":12,"back":12},""],
		[Vector3(0,47,-99),Vector3(30,20,30),{"back":12,"bottom":12},"ARCHIVE / GAMMA"],
		[Vector3(0,0,-69.5),Vector3(12,10,13),{"front":12,"back":12},""],
		[Vector3(0,0,-93),Vector3(38,30,34),{"back":12,"top":12},"LONG-RANGE UPLINK"]]
	for room in rooms: Mine.room(game,room[0],room[1],room[2],ICE,room[3])
	Mine.shaft(game,Vector3(0,24,-48),26,ICE)
	Mine.room(game,Vector3(-52,0,-72),Vector3(10,10,16),{"front":10,"back":10},TEAL,"",true)
	Mine.room(game,Vector3(-52,0,-91),Vector3(24,16,22),{"back":10},TEAL,"RESERVE / FROST",true)
	game.secret_center=Vector3(-52,0,-91)
	game.secret_extent=Vector3(10,7,9)
	game.secret_door=Mine.door(game,Vector3(-52,0,-64.5),false,true,true,"MAINTENANCE / FROST")
	game.core_door=Mine.door(game,Vector3(0,0,-75.6),false,true,false,"UPLINK / ARCHIVES REQUIRED",12)
	Mine.door(game,Vector3(0,47,-65),false,false,false,"FREEZER / AUTO",12)
	Mine.door(game,Vector3(-39,0,-48),true,false,false,"ALPHA / AUTO",12)
	Mine.door(game,Vector3(39,0,-48),true,false,false,"BETA / AUTO",12)
	game.spawn_target(Vector3(-55,0,-50),"archive","ARCHIVE ALPHA")
	game.spawn_target(Vector3(55,0,-50),"archive","ARCHIVE BETA")
	game.spawn_target(Vector3(0,47,-104),"archive","ARCHIVE GAMMA")
	game.spawn_target(Vector3(0,0,-98),"uplink","ORBITAL UPLINK")
	game.nav_nodes={"dock":Vector3(0,0,8),"entry":Vector3(0,0,-24),"nexus":Vector3(0,0,-48),"west":Vector3(-52,0,-48),"east":Vector3(52,0,-48),"freezer":Vector3(0,47,-48),"archive":Vector3(0,47,-99),"access":Vector3(0,0,-69.5),"core":Vector3(0,0,-93),"secret":Vector3(-52,0,-72),"vault":Vector3(-52,0,-91)}
	game.nav_edges=[["dock","entry"],["entry","nexus"],["nexus","west"],["nexus","east"],["nexus","freezer"],["freezer","archive"],["nexus","access"],["access","core"],["west","secret"],["secret","vault"]]
	game.locked_nav_edges=[["access","core"]]
	game.nav_goals=["west","east","archive"]
	game.nav_titles={"dock":"ARRIVAL / EXTRACTION","entry":"CRYO CONDUIT","nexus":"CRYO NEXUS","west":"ARCHIVE ALPHA","east":"ARCHIVE BETA","freezer":"FREEZER ASCENT","archive":"ARCHIVE GAMMA","access":"UPLINK APPROACH","core":"ORBITAL UPLINK","secret":"MAINTENANCE ACCESS","vault":"RESERVE VAULT"}
	for center in [Vector3(-52,0,-48),Vector3(52,0,-48),Vector3(0,47,-99)]:
		for side in [-1,1]:
			for z in [-7,7]:
				var pos=center+Vector3(side*9,-5,z)
				Forge.box(game.level,pos,Vector3(3,9,3),Color("708999"),0,true)
				for h in [-3,0,3]: Forge.ring(game.level,pos+Vector3(0,h,0),1.9,0.05,ICE,0.9)
		Mine.turbine(game,center+Vector3(10 if center.x==52 else 0,4,-14.4),3.4,ICE)
	for x in [-9,9]:
		var antenna=Forge.ring(game.level,Vector3(x,2,-105),4,0.12,ICE,1)
		antenna.rotation.x=PI/2
		game.machinery.append({"node":antenna,"axis":Vector3.UP,"speed":0.15})
	for pos in [Vector3(-7,0,1),Vector3(-59,2,-42),Vector3(7,47,-97)]: game.spawn_pickup(pos,"shield")
	for pos in [Vector3(7,0,1),Vector3(59,2,-42),Vector3(-56,0,-90)]: game.spawn_pickup(pos,"missiles")
	game.ambient_sources.append({"pos":Vector3(0,0,-98),"kind":"machine","volume":0.65})

static func fortress(game: Node3D) -> void:
	game.depth=3480
	game.extraction=Vector3(0,0,25)
	var rooms=[
		[Vector3(0,0,9),Vector3(28,18,44),{"front":12},"HELIOS / ARRIVAL"],
		[Vector3(0,0,-25),Vector3(34,22,24),{"back":12,"front":14,"left":12,"right":12},"FORTRESS NEXUS"],
		[Vector3(0,0,-55),Vector3(14,12,36),{"front":14,"back":14},""],
		[Vector3(0,0,-100),Vector3(64,38,54),{"back":14,"top":12,"left":12},"OVERSEER / CHAMBER"],
		[Vector3(-28,0,-25),Vector3(22,10,12),{"left":12,"right":12},""],
		[Vector3(28,0,-25),Vector3(22,10,12),{"left":12,"right":12},""],
		[Vector3(-52,0,-25),Vector3(26,22,30),{"right":12,"front":10},"SHIELD / WEST"],
		[Vector3(52,0,-25),Vector3(26,22,30),{"left":12,"bottom":12},"REACTOR DESCENT"],
		[Vector3(52,-40,-25),Vector3(28,18,30),{"top":12},"SHIELD / DEEP"],
		[Vector3(0,40,-100),Vector3(32,18,30),{"bottom":12},"SHIELD / CROWN"]]
	for room in rooms: Mine.room(game,room[0],room[1],room[2],HEAT,room[3])
	Mine.shaft(game,Vector3(52,-21,-25),20,RED)
	Mine.shaft(game,Vector3(0,25,-100),12,HEAT)
	Mine.room(game,Vector3(-52,0,-49),Vector3(10,10,18),{"front":10,"back":10},HEAT,"",true)
	Mine.room(game,Vector3(-52,0,-69),Vector3(22,16,22),{"back":10,"front":10},TEAL,"RESERVE / HELIOS",true)
	game.secret_center=Vector3(-52,0,-69)
	game.secret_extent=Vector3(9,7,9)
	game.secret_door=Mine.door(game,Vector3(-52,0,-40.5),false,true,true,"MAINTENANCE / HELIOS")
	game.core_door=Mine.door(game,Vector3(0,0,-72.6),false,false,false,"OVERSEER / APPROACH",14)
	Mine.door(game,Vector3(-39,0,-25),true,false,false,"WEST / AUTO",12)
	game.spawn_target(Vector3(-55,0,-29),"relay","WEST SHIELD NODE")
	game.spawn_target(Vector3(54,-40,-29),"relay","DEEP SHIELD NODE")
	game.spawn_target(Vector3(0,40,-106),"relay","CROWN SHIELD NODE")
	var boss=Boss.new()
	boss.game=game
	boss.position=Vector3(0,0,-103)
	game.add_child(boss)
	game.boss=boss
	game.targets.append({"node":boss,"kind":"boss","health":boss.health,"alive":true,"rings":[],"pos":boss.position,"name":"THE OVERSEER"})
	game.nav_nodes={"dock":Vector3(0,0,8),"nexus":Vector3(0,0,-25),"access":Vector3(0,0,-55),"core":Vector3(0,0,-100),"west":Vector3(-52,0,-25),"east":Vector3(52,0,-25),"lower":Vector3(52,-40,-25),"crown":Vector3(0,40,-100),"secret":Vector3(-52,0,-49),"vault":Vector3(-52,0,-69)}
	game.nav_edges=[["dock","nexus"],["nexus","west"],["nexus","east"],["east","lower"],["nexus","access"],["access","core"],["core","crown"],["west","secret"],["secret","vault"]]
	game.locked_nav_edges=[]
	game.nav_goals=["west","lower","crown"]
	game.nav_titles={"dock":"ARRIVAL / EXTRACTION","nexus":"FORTRESS NEXUS","access":"OVERSEER APPROACH","core":"OVERSEER CHAMBER","west":"WEST SHIELD NODE","east":"REACTOR DESCENT","lower":"DEEP SHIELD NODE","crown":"CROWN ASCENT","secret":"MAINTENANCE ACCESS","vault":"RESERVE VAULT"}
	for side in [-1,1]:
		for z in [-85,-100,-115]:
			if side==-1 and z==-100: continue # Keep the security service entrance clear.
			var pos=Vector3(side*27,0,z)
			Forge.box(game.level,pos,Vector3(4,30,4),Color("4a3c37"),0,true)
			for y in [-10,-5,0,5,10]:
				var ring=Forge.ring(game.level,pos+Vector3(0,y,0),3,0.1,RED,1)
				game.machinery.append({"node":ring,"axis":Vector3.UP,"speed":0.25})
			Forge.light(game.level,pos,HEAT,1.5,16)
		Forge.box(game.level,Vector3(side*22,-18.8,-100),Vector3(7,0.12,40),RED,0.9)
	for pos in [Vector3(-7,0,3),Vector3(57,-40,-20),Vector3(-8,0,-82),Vector3(8,40,-99)]: game.spawn_pickup(pos,"shield")
	for pos in [Vector3(7,0,3),Vector3(-57,0,-20),Vector3(8,0,-82),Vector3(-8,40,-99),Vector3(-55,0,-68)]: game.spawn_pickup(pos,"missiles")
	game.ambient_sources.append({"pos":Vector3(0,0,-100),"kind":"machine","volume":0.8})

static func roster(index: int) -> Array:
	if index==1:
		return [[Vector3(-6,2,-44),"scout"],[Vector3(7,-2,-52),"striker"],[Vector3(-46,3,-42),"striker"],[Vector3(-59,-3,-56),"bulwark"],[Vector3(46,2,-42),"scout"],[Vector3(59,-3,-55),"bulwark"],[Vector3(5,49,-54),"striker"],[Vector3(-6,44,-93),"scout"],[Vector3(6,49,-105),"bulwark"],[Vector3(-9,3,-87),"striker"],[Vector3(8,-4,-98),"striker"],[Vector3(0,7,-103),"scout"]]
	return [[Vector3(-6,2,-25),"striker"],[Vector3(8,-2,-30),"scout"],[Vector3(-48,2,-22),"bulwark"],[Vector3(-57,-3,-31),"striker"],[Vector3(47,3,-21),"scout"],[Vector3(57,-42,-31),"bulwark"],[Vector3(47,-38,-18),"striker"],[Vector3(7,42,-95),"bulwark"],[Vector3(-6,38,-109),"striker"],[Vector3(-16,5,-89),"scout"],[Vector3(16,-6,-117),"striker"]]
