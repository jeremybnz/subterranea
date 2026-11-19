extends RefCounted
const Forge=preload("res://scripts/forge.gd")
const SMOKE=preload("res://assets/shaders/damage_smoke.gdshader")
var game
var breakup_count=0
func _init(owner): game=owner
func emit_smoke(pos: Vector3,velocity: Vector3,size: float) -> void:
	if game.effects.size()>=180: return
	var n=MeshInstance3D.new(); var quad=QuadMesh.new(); quad.size=Vector2.ONE; n.mesh=quad
	var material=ShaderMaterial.new(); material.shader=SMOKE; n.material_override=material; n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	game.add_child(n); n.position=pos; n.scale=Vector3.ONE*size
	game.effects.append({"node":n,"life":1.6,"max":1.6,"velocity":velocity,"expand":false,"keep_scale":true,"kind":"damage_smoke","initial_scale":n.scale})
func breakup(visual: Node3D,kind: String,velocity: Vector3) -> void:
	if not is_instance_valid(visual) or visual.has_meta("broken_up"): return
	visual.set_meta("broken_up",true); breakup_count+=1
	var path="res://assets/models/"+kind+"_debris.glb"
	if not ResourceLoader.exists(path): return
	var limit=[24,48,72][game.graphics_preset]; var active=0
	for effect in game.effects:
		if effect.get("kind","")=="hull_debris": active+=1
	var parts=load(path).instantiate(); visual.add_child(parts)
	if kind=="kestrel": game.exploration.paint_meshes(parts)
	for chunk in parts.find_children("*","MeshInstance3D",true,false):
		if not chunk is MeshInstance3D or active>=limit: continue
		var outward=(chunk.global_position-visual.global_position).normalized()
		if outward.is_zero_approx(): outward=Vector3.UP
		chunk.reparent(game,true); chunk.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var life=randf_range(2.6,4.0); var speed=randf_range(3,6)
		var effect={"node":chunk,"life":life,"max":life,"velocity":velocity*0.35+outward*speed,"expand":false,"keep_scale":true,"kind":"hull_debris","initial_scale":chunk.scale,"spin":randf_range(-3,3),"trace_origin":chunk.position,"trace_timer":0.0,"smoke_timer":0.0}
		effect["engine_chunk"]="engine" in chunk.name.to_lower()
		game.effects.append(effect); active+=1
	parts.queue_free()
func advance(effect: Dictionary,delta: float) -> void:
	if effect.get("kind","")=="damage_smoke":
		effect.node.scale=effect.initial_scale*(1+(1-effect.life/effect.max)*1.3)
		effect.node.material_override.set_shader_parameter("fade",0.32*sin(PI*clampf(effect.life/effect.max,0,1)))
	elif effect.get("kind","")=="hull_debris":
		effect.trace_timer-=delta
		if effect.trace_timer<=0:
			effect.trace_timer=0.05
			var query=PhysicsRayQueryParameters3D.create(effect.trace_origin,effect.node.position,1)
			var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
			if hit:
				effect.node.position=hit.position+hit.normal*0.06
				effect.velocity=effect.velocity.bounce(hit.normal)*0.45
			effect.trace_origin=effect.node.position
		effect.velocity*=exp(-delta*0.28)
		effect.node.scale=effect.initial_scale*clampf(effect.life/0.6,0.01,1)
		effect.smoke_timer-=delta
		if effect.engine_chunk and effect.smoke_timer<=0 and effect.life>1.8:
			effect.smoke_timer=0.25
			emit_smoke(effect.node.position,effect.velocity*0.05,0.38)
