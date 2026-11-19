extends RefCounted
const Mine=preload("res://scripts/mine.gd")
const Forge=preload("res://scripts/forge.gd")
const STEPS=["THRUST","STRAFE","LIFT","ROLL","BOOST","AIRBRAKE","PULSE CANNONS","SEEKER MISSILE","TACTICAL MAP","VERTICAL FLIGHT","SERVICE INTERFACE"]
var game: Node3D
var step=0
var practice=0.0
var marker: Node3D
var goals=[Vector3(0,0,0),Vector3(-8,0,0),Vector3(-8,6,0),Vector3(-8,6,0),Vector3(0,0,-12),Vector3(0,0,-12),Vector3(0,0,-54),Vector3(5,3,-62),Vector3(0,0,-58),Vector3(0,46,-58),Vector3(0,46,-65)]
var finished=false
var boost_seen=false
func _init(owner: Node3D) -> void: game=owner
func build() -> void:
	Mine.room(game,Vector3.ZERO,Vector3(32,20,40),{"front":12},Color("76e9df"),"KESTREL / FLIGHT SCHOOL")
	Mine.room(game,Vector3(0,0,-32),Vector3(12,12,24),{"front":12,"back":12},Color("76e9df"),"")
	Mine.room(game,Vector3(0,0,-58),Vector3(32,24,28),{"back":12,"top":12},Color("9dbdff"),"WEAPONS / ASCENT")
	Mine.shaft(game,Vector3(0,24,-58),24,Color("9dbdff"))
	Mine.room(game,Vector3(0,46,-58),Vector3(32,20,28),{"bottom":12},Color("ffb76b"),"CERTIFICATION / DECK")
	game.spawn_target(goals[6],"relay","PULSE TARGET")
	game.spawn_target(goals[7],"relay","MISSILE TARGET")
	for target in game.targets:
		target.alive=false
		target.node.hide()
		target.node.collision_layer=0
	marker=Node3D.new()
	game.level.add_child(marker)
	for radius in [2.5,2.7]:
		var ring=Forge.ring(marker,Vector3.ZERO,radius,0.035,Color("ffb76b"),1.2)
		ring.rotation.x=PI/2
	Forge.sign_text(game.level,Vector3(0,6,-19.7),"TRAINING / SAFE FLIGHT",45,Color("76e9df"))
	game.make_display_ship()
func instruction() -> String:
	var c=game.controls
	return [
		"Use "+c.label("forward")+" to fly through the gold marker. Mouse or right stick steers.",
		"Strafe left with "+c.label("left")+" and enter the left marker.",
		"Rise with "+c.label("up")+". Thrust follows your ship's local axes.",
		"Hold "+c.label("roll_left")+" or "+c.label("roll_right")+" to roll. Use the attitude indicator to orient yourself.",
		"Hold "+c.label("boost")+" while thrusting and enter the forward marker at speed.",
		"Hold "+c.label("brake")+" to stop the ship. Assist also brakes when you release thrust.",
		"Aim at PULSE TARGET and fire with "+c.label("fire")+" until it is disabled.",
		"Aim at MISSILE TARGET and launch with "+c.label("missile")+". Missiles have a blast radius.",
		"Open the tactical survey with "+c.label("map")+". It shows shafts, objectives and your altitude.",
		"Fly down the conduit, then ascend the shaft to the gold marker at +46 meters.",
		"Approach the service marker and hold "+c.label("interact")+" for two seconds to certify your ship."][step]
func hint() -> Dictionary: return {"pos":goals[step],"name":STEPS[step],"color":Color("ffb76b")}
func advance() -> void:
	step+=1
	practice=0
	game.sound.play_tone("pickup",0.5)
	game.player.boost=100
	if step in [6,7]:
		var target=game.targets[step-6]
		target.alive=true
		target.health=90
		target.node.show()
		target.node.collision_layer=8
func update(delta: float) -> void:
	if finished: return
	marker.position=goals[step]
	marker.visible=step not in [6,7,8]
	game.nav_hint=hint()
	var pilot=game.player
	var c=game.controls
	var close=pilot.position.distance_to(goals[step])<3.0
	match step:
		0:
			if close: advance()
		1:
			practice+=delta*c.strength("left")
			if close and practice>0.25: advance()
		2:
			practice+=delta*c.strength("up")
			if close and practice>0.25: advance()
		3:
			practice+=delta*absf(c.axis("roll_right","roll_left"))
			if practice>0.75: advance()
		4:
			if pilot.boosting:
				practice+=delta
				if pilot.velocity.length()>16: boost_seen=true
			if close and practice>0.25 and boost_seen: advance()
		5:
			if c.held("brake") and pilot.velocity.length()<1: practice+=delta
			if practice>0.3: advance()
		7:
			if pilot.missiles==0: pilot.missiles=1
		8:
			if game.map_open: practice+=delta
			if practice>0.35: advance()
		9:
			if close: advance()
		10:
			if close and c.held("interact"): practice+=delta
			else: practice=maxf(0,practice-delta)
			if practice>=2:
				finished=true
				game.campaign.data.training_complete=true
				game.campaign.save()
				game.finish(true,"FLIGHT CERTIFIED","Flight, weapons and navigation checks complete.")
func damage(body: Object,amount: float,weapon: String) -> void:
	if not body.has_meta("target_id") or step not in [6,7]: return
	if (step==6 and weapon!="pulse") or (step==7 and weapon!="missile"): return
	var index=int(body.get_meta("target_id"))
	if index!=step-6: return
	var target=game.targets[index]
	target.health-=amount
	game.hit_confirm=1
	if target.health<=0:
		target.alive=false
		target.node.hide()
		target.node.collision_layer=0
		game.explosion(target.pos,Color("ffb76b"),1.5)
		advance()
