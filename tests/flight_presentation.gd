extends SceneTree
var game
var failures=0
func _initialize() -> void:
	root.set_meta("test_session",true); root.set_meta("cinematic",true); call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else: failures+=1; push_error(label)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func fresh(index: int=0) -> void:
	if is_instance_valid(game): game.queue_free(); await process_frame; await process_frame
	root.set_meta("mission_selection",index); game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; await physics_frame; game.launch(); game.player.set_physics_process(false)
	for d in game.drones: d.set_physics_process(false)
	for f in game.systems.foundries: f.set_physics_process(false)
	if is_instance_valid(game.boss): game.boss.set_physics_process(false)
func pieces() -> Array: return game.effects.filter(func(e): return e.get("kind","")=="hull_debris")
func run() -> void:
	await fresh()
	var p=game.player; p.position=Vector3(0,1,-44); p.rotation=Vector3.ZERO
	check(not p.chase_enabled and p.cockpit.visible and not p.exterior.visible,"Existing profiles begin in the unobstructed cockpit view")
	var key=InputEventKey.new(); key.keycode=KEY_T; key.physical_keycode=KEY_T; key.pressed=true; game._input(key)
	check(p.chase_enabled and p.exterior.visible and not p.cockpit.visible and p.camera.position.z>2,"Remappable T input activates the external ship and chase camera")
	check(p.weapon_origin().distance_to(p.global_position)<0.001,"Chase weapons originate at the ship, not the trailing camera")
	for rotation in [Vector3(0,0,PI),Vector3(PI/2,0,PI/2),Vector3(-PI/2,PI/2,-PI/2)]:
		p.rotation=rotation; p.update_view(0)
		check(p.camera.global_basis.is_equal_approx(p.global_basis) and p.camera.position.z>1,"Chase orientation follows a full six-axis attitude "+str(rotation))
	p.rotation=Vector3.ZERO; p.position=Vector3(9,0,-29.75); p.update_view(0)
	check(p.chase_enabled and p.chase_obstructed and p.cockpit.visible and p.camera.position.length()<0.1,"A close wall triggers cockpit clearance without disabling the requested chase view")
	p.position=Vector3(0,1,-44)
	for i in range(45): p.update_view(1.0/60)
	check(not p.chase_obstructed and p.exterior.visible,"Chase view returns smoothly after leaving the obstruction")
	var q=PhysicsShapeQueryParameters3D.new(); var shape=SphereShape3D.new(); shape.radius=0.25; q.shape=shape; q.collision_mask=1; q.transform=Transform3D(Basis.IDENTITY,p.position+Vector3(0,0.2,0)); q.motion=p.camera.global_position-q.transform.origin
	check(game.get_world_3d().direct_space_state.cast_motion(q)[0]>0.98,"The final camera position passes an actual sphere-clearance cast")
	var saved_keys=game.controls.DEFAULTS.duplicate(true); saved_keys.erase("camera_view"); saved_keys.forward=["key",KEY_T]
	game.controls.load_bindings(saved_keys,{})
	check(game.controls.bindings.forward==["key",KEY_T] and game.controls.bindings.camera_view!=["key",KEY_T],"A legacy custom T binding keeps precedence over the new view default")
	game.controls.reset()
	var pad=InputEventJoypadButton.new(); pad.button_index=JOY_BUTTON_TOUCHPAD; pad.pressed=true; game._input(pad)
	check(not p.chase_enabled,"The default touchpad event can switch the camera through the shared action map")
	p.toggle_view(); p.update_view(0)
	var state=p.flight_state; p.thrust_level=0
	for i in range(30): state.update_state(0.02)
	var idle=state.engines.get_meta("power"); p.thrust_level=1
	for i in range(30): state.update_state(0.02)
	var cruise=state.engines.get_meta("power"); p.boosting=true
	for i in range(30): state.update_state(0.02)
	var boosted=state.engines.get_meta("power")
	check(cruise>idle*2 and boosted>cruise*1.6,"Actual thrust and boost produce distinct smoothed engine power levels")
	var plume=state.engines.get_child(0)
	check(plume.scale.y>1.8 and plume.material_override.get_shader_parameter("power")>1.8,"Boost stretches and brightens the rendered exhaust mesh")
	p.boosting=false; p.thrust_level=0; p.shield=100; p.hurt(20,p.position+Vector3(0,0,5))
	check(state.shield_mesh.visible and state.hit_age==0 and state.shield_mesh.material_override.get_shader_parameter("impact_dir").z>0.9,"Incoming fire creates a shield ripple facing the real damage source")
	p.shield=20; state.smoke_time=0; state.update_state(0.1)
	check(state.burns[0].visible and game.effects.any(func(e): return e.get("kind","")=="damage_smoke"),"Low integrity shows scorch patches and emits actual smoke particles")
	var smoke=game.effects.filter(func(e): return e.get("kind","")=="damage_smoke")[0]; var before=smoke.node.position; var age=state.hit_age; var power=state.engines.get_meta("power")
	game.toggle_map(); await frames(8)
	check(smoke.node.position==before and state.hit_age==age and state.engines.get_meta("power")==power,"Automap pauses smoke motion, shield lifetime and reactive engine state")
	game.toggle_map(); p.shield=100; state.update_state(0.1)
	check(not state.burns[0].visible and state.integrity==1,"Repairs clear derived scorch damage without permanently recoloring the hull")
	# Every weapon must hit the reticle target, but still stop at a wall beside the ship.
	for d in game.drones: d.position=Vector3(1000+d.spawn_id*5,1000,1000)
	var target=game.drones[0]; target.position=Vector3(0,1,-52); target.health=1000; target.max_health=1000
	p.position=Vector3(0,1,-44); p.rotation=Vector3.ZERO; p.update_view(0); p.camera.look_at(target.position)
	await physics_frame
	var health=target.health; game.fire_laser(); check(target.health<health,"Chase pulse fire hits the centered reticle target from the ship")
	health=target.health; game.arsenal.fire_plasma(); await frames(20); check(target.health<health,"Chase plasma travels from the ship into the reticle target")
	health=target.health; game.arsenal.fire_rail(1); check(target.health<health,"Chase charged rail fire hits the reticle target")
	health=target.health; game.fire_missile(); check(game.projectiles.any(func(s): return s.friendly and s.node.position.distance_to(p.position)<2.1),"Chase missiles spawn at the ship's checked muzzle path")
	await frames(22); check(target.health<health,"A real chase-view seeker reaches and damages its target")
	var wall=game.Forge.box(game,Vector3(0,0.98,-47),Vector3(4,0.4,0.5),Color.GRAY,0,true); await physics_frame
	var camera_ray=PhysicsRayQueryParameters3D.create(p.camera.global_position,p.camera.global_position-p.camera.global_basis.z*30,1|4)
	var seen=game.get_world_3d().direct_space_state.intersect_ray(camera_ray)
	check(not seen.is_empty() and seen.collider==target,"Parallax fixture lets the raised camera see a target over low cover")
	health=target.health; game.fire_laser(); game.arsenal.fire_rail(1); game.arsenal.fire_plasma(); game.fire_missile(); await frames(22)
	check(target.health==health,"Pulse, rail, plasma and missiles cannot fire through cover visible only from the camera")
	wall.queue_free(); await physics_frame
	# Actual hull fragments retain the source mesh and never create gameplay collision bodies.
	game.update_effects(10); var kills=game.kills
	target.hit(10000,p.position,true); var debris=pieces()
	check(debris.size()==6 and game.kills==kills+1,"Destroying a scout produces six actual armor/engine chunks and one kill")
	check(debris.all(func(e): return e.node is MeshInstance3D and not e.node is CollisionObject3D) and debris.any(func(e): return e.engine_chunk),"Breakup pieces are cosmetic original meshes with identifiable engine chunks")
	var count=game.flight_fx.breakup_count; target.hit(10000,p.position,true)
	check(game.flight_fx.breakup_count==count,"Repeated lethal hits cannot duplicate a breakup or reward")
	for i in range(12):
		var d=game.spawn_drone(Vector3(0,1,-52),"scout"); d.set_physics_process(false); d.hit(10000,p.position,true)
	check(pieces().size()<=48,"Burst destruction respects the Balanced 48-fragment budget")
	var fragment=pieces()[0]; fragment.node.position=Vector3(5,1,-44); fragment.trace_origin=fragment.node.position; fragment.velocity=Vector3(30,0,0); fragment.trace_timer=0
	wall=game.Forge.box(game,Vector3(6,1,-44),Vector3(0.2,4,4),Color.GRAY,0,true); await physics_frame
	game.update_effects(0.1)
	check(fragment.velocity.x<0 and fragment.node.position.x<6,"Cosmetic debris bounces off an actual mine wall")
	wall.queue_free(); game.update_effects(10); await process_frame
	check(pieces().is_empty() and not game.effects.any(func(e): return e.get("kind","")=="damage_smoke"),"Fragments and damage smoke expire without leaving persistent actors")
	p.shield=18; game.store_checkpoint(); p.shield=100; game.restore_checkpoint(); state.update_state(0.02)
	check(state.burns[0].visible,"Restored shield integrity reconstructs the right damage appearance")
	await fresh(2); game.relays_down=3; game.boss.phase=3; game.boss.health=100; game.boss.warming=0; game.boss.hit(10000,Vector3.ZERO,true)
	check(game.boss.dead and pieces().size()==6 and game.reactor_down,"The actual Overseer death sheds its six hull chunks and still begins evacuation")
	game.player.shield=1; game.player.hurt(100,game.player.position+Vector3(0,0,4))
	check(game.state=="lost" and game.player.exterior.has_meta("broken_up"),"Player destruction triggers its own hull breakup and the normal loss flow")
	game.queue_free(); await process_frame; await process_frame; await create_timer(0.15,true,false,true).timeout
	print("FLIGHT PRESENTATION TEST COMPLETE: ",failures," failures"); quit(1 if failures else 0)
