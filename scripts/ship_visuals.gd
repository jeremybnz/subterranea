extends RefCounted
const PLUME=preload("res://assets/shaders/engine_plume.gdshader")
static var finish: NoiseTexture2D
static func surface_finish(node: Node) -> void:
	if finish==null:
		finish=NoiseTexture2D.new(); finish.width=128; finish.height=128; var grain=FastNoiseLite.new(); grain.frequency=0.28; grain.fractal_octaves=2; finish.noise=grain
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var material=node.mesh.surface_get_material(i)
			if material is StandardMaterial3D and not material.emission_enabled and material.resource_name!="Canopy":
				material.uv1_triplanar=true; material.uv1_scale=Vector3.ONE*12; material.roughness_texture=finish; material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED; material.roughness=0.62
	for child in node.get_children(): surface_finish(child)
static func attach(parent: Node3D,kind: String,tint: Color = Color("75ece2")) -> Node3D:
	surface_finish(parent)
	var holder=Node3D.new(); holder.name="EnginePlumes"; parent.add_child(holder)
	var engines=[]
	match kind:
		"kestrel": engines=[[1.47,-0.16,1.92,0.19,0.75],[-1.47,-0.16,1.92,0.19,0.75]]
		"scout": engines=[[1.05,-0.04,0.84,0.10,0.36],[-1.05,-0.04,0.84,0.10,0.36]]
		"striker": engines=[[0.95,0.03,1.04,0.13,0.48],[-0.95,0.03,1.04,0.13,0.48]]
		"bulwark","warden": engines=[[0.76,0,0.89,0.16,0.45],[-0.76,0,0.89,0.16,0.45]]
		"overseer": engines=[[3.24,-0.09,2.2,0.28,0.9],[-3.24,-0.09,2.2,0.28,0.9],[1.67,0,2.25,0.18,0.65],[-1.67,0,2.25,0.18,0.65]]
		"courier": engines=[[0.29,-0.03,0.9,0.08,0.28],[-0.29,-0.03,0.9,0.08,0.28]]
	var material=ShaderMaterial.new(); material.shader=PLUME; material.set_shader_parameter("tint",tint)
	for jet in engines:
		var plume=MeshInstance3D.new(); var mesh=CylinderMesh.new(); mesh.top_radius=0.015; mesh.bottom_radius=jet[3]; mesh.height=jet[4]; mesh.radial_segments=16; mesh.cap_top=false; mesh.cap_bottom=false
		plume.set_meta("base_length",jet[4]); plume.set_meta("base_z",jet[2]+0.32+0.015); plume.mesh=mesh; plume.material_override=material; plume.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(plume); plume.rotation.x=PI/2; plume.position=Vector3(jet[0],jet[1],jet[2]+0.32+jet[4]/2+0.015)
	return holder

static func drive(holder: Node3D,throttle: float,boost: bool,integrity: float,delta: float) -> void:
	var requested=(0.45+throttle*0.75)*(1.8 if boost else 1.0)
	var power=lerpf(float(holder.get_meta("power",0.45)),requested,1-exp(-delta*10))
	holder.set_meta("power",power)
	for plume in holder.get_children():
		plume.scale.y=power
		plume.position.z=float(plume.get_meta("base_z"))+float(plume.get_meta("base_length"))*power/2
		plume.material_override.set_shader_parameter("power",power)
		plume.material_override.set_shader_parameter("engine_health",clampf(integrity,0,1))
