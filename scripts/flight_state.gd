extends Node3D
const Visuals=preload("res://scripts/ship_visuals.gd")
const SHIELD=preload("res://assets/shaders/shield_hit.gdshader")
const SCORCH=preload("res://assets/shaders/scorch.gdshader")
var game
var actor: Node3D
var hull: Node3D
var kind=""
var engines: Node3D
var shield_mesh: MeshInstance3D
var burns: Array=[]
var hit_age=1.0
var smoke_time=0.0
var integrity=1.0
func setup(owner,body: Node3D,model: Node3D,asset: String) -> void:
	game=owner; actor=body; hull=model; kind=asset; model.add_child(self)
func _ready() -> void:
	engines=hull.get_node("EnginePlumes")
	var dimensions={"kestrel":Vector3(3.2,0.85,2.8),"scout":Vector3(1.7,0.65,1.4),"striker":Vector3(1.65,0.8,1.7),"bulwark":Vector3(1.7,0.8,1.45),"warden":Vector3(1.9,1.3,1.6),"overseer":Vector3(6,2,3.6),"courier":Vector3(1.3,0.65,1.4)}[kind]
	shield_mesh=MeshInstance3D.new(); var sphere=SphereMesh.new(); sphere.radius=1; sphere.height=2; sphere.radial_segments=24; sphere.rings=12; shield_mesh.mesh=sphere; shield_mesh.scale=dimensions
	var material=ShaderMaterial.new(); material.shader=SHIELD; material.set_shader_parameter("tint",Color("7be9f6") if kind in ["kestrel","courier"] else Color("ffae80")); shield_mesh.material_override=material; shield_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(shield_mesh); shield_mesh.hide()
	var points={"kestrel":[Vector3(-1.47,0.3,0.65),Vector3(1.47,0.3,0.65)],"scout":[Vector3(-1.05,0.17,0.4),Vector3(1.05,0.17,0.4)],"striker":[Vector3(-0.95,0.39,0.58),Vector3(0.95,0.39,0.58)],"bulwark":[Vector3(-0.76,0.58,-0.65),Vector3(0.76,0.58,-0.65)],"warden":[Vector3(-0.76,0.58,-0.65),Vector3(0.76,0.58,-0.65)],"overseer":[Vector3(-3.24,0.61,0.85),Vector3(3.24,0.61,0.85)],"courier":[Vector3(-0.3,0.35,0.35),Vector3(0.3,0.35,0.35)]}[kind]
	for point in points:
		var patch=MeshInstance3D.new(); var plane=PlaneMesh.new(); plane.size=Vector2(0.55,0.7)*(2 if kind=="overseer" else 1); patch.mesh=plane; patch.position=point; patch.rotation.y=0.4
		var paint=ShaderMaterial.new(); paint.shader=SCORCH; patch.material_override=paint; patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(patch); patch.hide(); burns.append(patch)
func _process(delta: float) -> void:
	if game.state!="playing" or game.map_open: return
	update_state(delta)
func update_state(delta: float) -> void:
	var throttle=0.0; var boost=false
	if kind=="kestrel":
		integrity=actor.shield/actor.shield_max; throttle=actor.thrust_level; boost=actor.boosting
	elif kind=="courier": integrity=actor.integrity/160.0; throttle=actor.velocity.length()/10
	else: integrity=actor.health/actor.max_health; throttle=actor.velocity.length()/8
	Visuals.drive(engines,clampf(throttle,0,1),boost,integrity,delta)
	hit_age=minf(1,hit_age+delta*2.8); shield_mesh.visible=hit_age<1
	shield_mesh.material_override.set_shader_parameter("age",hit_age)
	for patch in burns:
		patch.visible=integrity<0.55
		patch.material_override.set_shader_parameter("severity",clampf((0.7-integrity)/0.65,0,1))
	smoke_time-=delta
	if integrity<0.45 and smoke_time<=0:
		smoke_time=0.22 if integrity<0.25 else 0.55
		var scale_factor=hull.global_basis.get_scale().length()/sqrt(3)
		game.flight_fx.emit_smoke(hull.to_global(Vector3(0,0.25,0.6)),actor.velocity*0.12+hull.global_basis.y.normalized()*0.35,clampf(scale_factor*0.55,0.22,1.5))
func flash(source: Vector3) -> void:
	hit_age=0; shield_mesh.show()
	var direction=(source-actor.global_position).normalized() if source.is_finite() and source.distance_to(actor.global_position)>0.01 else -actor.global_basis.z
	shield_mesh.material_override.set_shader_parameter("impact_dir",(hull.global_basis.inverse()*direction).normalized())
	shield_mesh.material_override.set_shader_parameter("age",0.0)
	if kind in ["kestrel","courier"] and game.effects.size()<220:
		game.impact(actor.global_position+direction*0.55,Color("a4ecff") if integrity>0.5 else Color("ffb76b"),3)
