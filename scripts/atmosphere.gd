extends RefCounted
const Forge=preload("res://scripts/forge.gd")
static func decorate(game) -> void:
	var index=game.mission_index
	var origin=[Vector3(0,44,-103),Vector3(52,0,-64),Vector3(0,0,-127)][index]
	var width=24.0 if index==2 else 14.0
	var height=12.0 if index==2 else 8.0
	var glass=Forge.box(game.level,origin,Vector3(width,height,0.22),Color("77b9c7"),0,true)
	for body in glass.get_children():
		if body is CollisionObject3D: body.set_meta("surface","glass")
	var material=glass.material_override.duplicate(); material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; material.albedo_color=Color(0.3,0.65,0.75,0.08); material.metallic=0.1; glass.material_override=material
	for side in [-1,1]:
		Forge.box(game.level,origin+Vector3(side*(width/2+0.25),0,0.2),Vector3(0.5,height+1,0.6),Color("4c6570"))
		Forge.box(game.level,origin+Vector3(0,side*(height/2+0.25),0.2),Vector3(width+1,0.5,0.6),Color("4c6570"))
		Forge.box(game.level,origin+Vector3(side*width/4,0,0.2),Vector3(0.13,height,0.25),Color("63828e"))
	Forge.sign_text(game.level,origin+Vector3(0,height/2+0.9,0.6),["NEREID / DEEP BORING ARRAY","BOREAS / FROZEN EXCAVATION","HELIOS / FUSION ARRAY"][index],32,Color("b6d9e1"))
	# The vista is physically outside a sealed observation window.
	var center=origin+Vector3(0,0,-29)
	if index==0:
		for i in range(15):
			var a=i*TAU/15
			var rock=Forge.sphere(game.level,center+Vector3(cos(a)*17,sin(a)*13,-6),5,Color("3c3330")); rock.scale=Vector3(1.3,0.8,1.6)
		var drill=Node3D.new(); game.level.add_child(drill); drill.position=center
		for z in [-9,-3,3,9]: Forge.ring(drill,Vector3(0,0,z),5.5,0.5,Color("ad6f3a"),0.3).rotation.x=PI/2
		for i in range(8):
			var a=i*TAU/8
			Forge.beam(drill,Vector3(cos(a)*5,sin(a)*5,-11),Vector3(cos(a+0.7)*5,sin(a+0.7)*5,11),0.45,Color("76513a"))
		game.machinery.append({"node":drill,"axis":Vector3.BACK,"speed":0.2})
		Forge.light(game.level,center+Vector3(0,4,7),Color("ffb269"),4,24)
	elif index==1:
		for i in range(16):
			var spire=MeshInstance3D.new(); var mesh=CylinderMesh.new(); mesh.top_radius=0; mesh.bottom_radius=2.0+(i%3); mesh.height=12+(i%5)*3; mesh.radial_segments=6; spire.mesh=mesh
			spire.material_override=Forge.material(Color("729cb9"),0.18); game.level.add_child(spire); spire.position=center+Vector3(-22+i*3,-8+(i%3)*2,-8-absf(i-8)); spire.rotation.z=sin(i*1.7)*0.3
		var moon=Forge.sphere(game.level,center+Vector3(12,12,-35),10,Color("a4cde4"),0.65)
		Forge.light(game.level,center+Vector3(0,8,8),Color("9ec9ff"),4,25)
	else:
		var core=Forge.sphere(game.level,center,9,Color("ff923f"),1.3)
		var shader=Shader.new()
		shader.code="shader_type spatial; render_mode unshaded; uniform vec3 center; varying vec3 p; void vertex(){p=VERTEX-center;} void fragment(){float n=0.5+0.22*sin(p.x*1.7+p.y*0.9+TIME*0.8)+0.17*sin(p.z*2.6-p.y*2.1-TIME*1.2)+0.1*sin(p.x*5.2+p.z*3.1+TIME); vec3 c=mix(vec3(0.45,0.045,0.008),vec3(1.0,0.64,0.12),smoothstep(0.1,0.9,n)); ALBEDO=c; EMISSION=c*0.45;}"
		var plasma=ShaderMaterial.new(); plasma.shader=shader; plasma.set_shader_parameter("center",center); core.material_override=plasma
		for i in range(3):
			var ring=Forge.ring(game.level,center,13+i*3,0.45,Color("a67a48"),0.7); ring.rotation=Vector3(0.5+i*0.65,0.3*i,0.3)
			game.machinery.append({"node":ring,"axis":Vector3.UP,"speed":0.13+i*0.04})
		for side in [-1,1]: Forge.beam(game.level,center+Vector3(side*20,-16,0),center+Vector3(side*20,16,0),1.1,Color("514745"))
		Forge.light(game.level,center+Vector3(0,0,15),Color("ffb66d"),3,18)
	for i in range(28):
		var a=i*2.399
		Forge.sphere(game.level,center+Vector3(cos(a)*(22+i%9),sin(a)*(15+i%7),-30-i%4*5),0.09+0.03*(i%3),Color("b7d8ec"),0.7)
	# Bent supports, disconnected cable runs and caution strips stay at room edges.
	var damage_center=[Vector3(-43,-43,-44),Vector3(0,47,-48),Vector3(52,-40,-25)][index]
	for side in [-1,1]:
		Forge.beam(game.level,damage_center+Vector3(side*10,6,-9),damage_center+Vector3(side*7,3,-9),0.26,Color("78635b"))
		for j in range(6):
			var strip=Forge.box(game.level,damage_center+Vector3(side*10,-7.7,-8+j*1.5),Vector3(1.5,0.03,0.4),Color("d5a65d")); strip.rotation.y=0.6
