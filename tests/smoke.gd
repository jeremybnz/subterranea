extends SceneTree
var failures = 0
func check(condition: bool, message: String) -> void:
	if condition: print("PASS: ",message)
	else:
		failures += 1
		push_error("FAIL: "+message)

func _initialize() -> void:
	root.set_meta("test_session",true)
	call_deferred("run")

func run() -> void:
	var packed = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	check(game.targets.size()==4 and game.drones.size()==18,"Mission contains three relays, core, and eighteen enemies")
	game.launch()
	await physics_frame
	check(game.state=="playing","Launch enters captured flight")
	check(game.player.motion_mode==CharacterBody3D.MOTION_MODE_FLOATING,"Ship uses zero-gravity movement")
	var core = game.targets[3]
	game.damage_object(core.node,500)
	check(core.health==360,"Reactor is invulnerable before relays are disabled")
	# Test continuous paths across every doorway using physics ray queries.
	for route in [[Vector3(0,0,8),Vector3(0,0,-44)],[Vector3(-43,0,-44),Vector3(43,0,-44)],[Vector3(0,0,-44),Vector3(0,0,-73)]]:
		check(game.clear_line(route[0],route[1]),"Connected flight path "+str(route))
	game.player.position=Vector3(13,0,0)
	game.player.velocity=Vector3(15,0,0)
	game.player.move_and_slide()
	check(game.player.position.x<13.4,"Ship collides with solid mine walls")
	game.player.position=Vector3(0,0,8)
	var drone = game.drones[0]
	game.damage_object(drone,100)
	check(game.kills==1,"Drone damage awards a kill")
	game.player.shield=50
	game.spawn_pickup(game.player.position,"shield")
	await process_frame
	await process_frame
	check(game.player.shield==85,"Shield pickups restore health")
	game.fire_laser()
	game.fire_missile()
	check(game.projectiles.size()>0 and game.effects.size()>0,"Both weapons generate projectiles or traces")
	for i in range(3): game.damage_object(game.targets[i].node,100)
	await physics_frame
	await process_frame
	check(game.relays_down==3,"All relays can be destroyed")
	check(not game.core_door.locked and not game.reactor_doors[1].locked,"Relay completion unlocks both reactor entrances")
	game.player.position=Vector3(0,0,-69)
	game.player.velocity=Vector3.ZERO
	for i in range(55): await physics_frame
	check(game.core_door.openness>0.99,"Unlocked reactor blast door slides open on approach")
	check(game.clear_line(Vector3(0,0,-73),Vector3(0,0,-83)),"Reactor route opens physically")
	game.damage_object(core.node,400)
	check(game.reactor_down,"Destroying the reactor starts containment countdown")
	game.player.position=Vector3(0,0,11)
	await process_frame
	await process_frame
	check(game.state=="won","Returning to extraction completes the mission")
	game.state="playing"
	game.result_recorded=false
	game.player.shield=5
	game.player.hurt(10)
	check(game.state=="lost","Fatal damage opens the loss screen")
	print("SMOKE TEST COMPLETE: ",failures," failures")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
