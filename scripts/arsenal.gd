extends RefCounted
## Three primary weapons share the amplifier upgrade and rechargeable energy.
const NAMES=["PULSE / MK II","PLASMA / CYCLONE","RAIL / LANCER"]
const COLORS=[Color("76e9df"),Color("b499ff"),Color("ffd58b")]
var game
func _init(owner): game=owner
func select(index: int) -> void:
	if game.training_mode: index=0
	game.player.primary_weapon=posmod(index,3)
	game.player.rail_charge=0
	game.announce(NAMES[game.player.primary_weapon]+" / "+["RAPID PRECISION","TRAVELING SPLASH / WATCH WALLS","HOLD FIRE TO CHARGE / RELEASE TO PIERCE"][game.player.primary_weapon],2.3)
	game.sound.play_tone("ui",0.4)
func update(delta: float) -> void:
	var p=game.player
	var held=game.controls.held("fire")
	if p.primary_weapon==2:
		if held and p.fire_timer<=0 and p.energy>=16:
			if p.rail_charge==0: game.sound.play_tone("charge",0.35)
			p.rail_charge=minf(minf(1,(p.energy-12)/16.0),p.rail_charge+delta/0.85)
		elif not held and p.rail_charge>0:
			if p.rail_charge>=0.25 and p.energy>=16:
				var charge=minf(p.rail_charge,(p.energy-12)/16.0)
				p.energy-=12+16*charge
				p.fire_timer=0.48
				p.recoil=1.8
				p.flash_muzzles()
				fire_rail(charge)
			p.rail_charge=0
		return
	var cost=3 if p.primary_weapon==0 else 9
	if held and p.fire_timer<=0 and p.energy>=cost:
		p.energy-=cost
		p.fire_timer=p.cannon_interval if p.primary_weapon==0 else 0.38*(1-game.campaign.level("cannons")*0.04)
		p.recoil=1 if p.primary_weapon==0 else 1.4
		p.flash_muzzles()
		if p.primary_weapon==0: game.fire_laser()
		else: fire_plasma()
func fire_plasma() -> void:
	var start=game.player.weapon_origin()
	var direction=game.player.aim_direction()
	var damage=52.0+game.campaign.level("cannons")*8
	game.combat_stats.shots.plasma+=1
	var ray=PhysicsRayQueryParameters3D.create(start,start+direction*1.6,1|4|8|16)
	var hit=game.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit:
		game.hit_feedback.play(hit,"plasma",start)
		plasma_blast(hit.position,damage)
		return
	var n=game.Forge.sphere(game,start+direction*1.2,0.32,COLORS[1],3)
	n.set_meta("trail_color",COLORS[1])
	var ring=game.Forge.ring(n,Vector3.ZERO,0.45,0.05,COLORS[1],2)
	ring.rotation.x=PI/2
	game.projectiles.append({"node":n,"direction":direction,"speed":42.0,"life":3.2,"friendly":true,"target":null,"kind":"plasma","damage":damage})
	game.sound.play_tone("plasma",0.65)
func plasma_blast(pos: Vector3,damage: float) -> void:
	game.explosion(pos,COLORS[1],0.7)
	var victims=game.drones.duplicate()
	if is_instance_valid(game.boss): victims.append(game.boss)
	for h in game.director.hazards+game.systems.foundries: victims.append(h)
	for t in game.targets:
		if t.kind!="boss" and t.alive: victims.append(t.node)
	for body in victims:
		if not is_instance_valid(body): continue
		var reach=5.5 if body==game.boss else 3.8
		var distance=body.global_position.distance_to(pos)
		if distance<reach and game.clear_line(pos,body.global_position):
			game.damage_object(body,damage*(1-0.3*distance/reach),"plasma",pos,true)
func fire_rail(charge: float) -> void:
	var start=game.player.weapon_origin()
	var direction=game.player.aim_direction()
	var end=start+direction*180
	var excluded: Array[RID]=[]
	var origin=start
	game.combat_stats.shots.rail+=1
	for i in range(3):
		var query=PhysicsRayQueryParameters3D.create(origin,end,1|4|8|16)
		query.exclude=excluded
		var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit: break
		var body=hit.collider
		game.hit_feedback.play(hit,"rail",start)
		game.damage_object(body,(32+78*charge+game.campaign.level("cannons")*15)*pow(0.8,i),"rail",start,true)
		if body.collision_layer & 1 or i==2:
			end=hit.position
			break
		excluded.append(body.get_rid())
		origin=hit.position+direction*0.08
	var beam=game.Forge.beam(game,game.player.muzzle_position(0),end,0.045+charge*0.045,COLORS[2],3)
	game.effects.append({"node":beam,"life":0.22,"max":0.22,"velocity":Vector3.ZERO,"expand":false,"keep_scale":true})
	game.sound.play_tone("rail",0.8)
