extends RefCounted
## Procedural industrial architecture. All visuals are original mesh geometry.
static var mats: Dictionary = {}
static var steel_normal: NoiseTexture2D
static var steel_finish: NoiseTexture2D

static func material(color: Color, emission: float = 0.0, metal: float = 0.6) -> StandardMaterial3D:
	var key = str(color) + str(emission) + str(metal)
	if mats.has(key): return mats[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.48
	if emission == 0:
		if steel_normal == null:
			steel_normal = NoiseTexture2D.new()
			steel_normal.width = 128
			steel_normal.height = 128
			steel_normal.as_normal_map = true
			steel_normal.bump_strength = 0.22
			var noise = FastNoiseLite.new()
			noise.frequency = 0.12
			noise.fractal_octaves = 3
			steel_normal.noise = noise
		m.normal_enabled = true
		m.normal_texture = steel_normal
		m.normal_scale = 0.3
		if steel_finish==null:
			steel_finish=NoiseTexture2D.new()
			steel_finish.width=128
			steel_finish.height=128
			var grain=FastNoiseLite.new()
			grain.frequency=0.08
			grain.fractal_octaves=3
			steel_finish.noise=grain
			var ramp=Gradient.new()
			ramp.colors=PackedColorArray([Color(0.91,0.93,0.95),Color(1,1,1)])
			steel_finish.color_ramp=ramp
		m.albedo_texture=steel_finish
		m.uv1_scale=Vector3(6,6,6)
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	mats[key] = m
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, emission: float = 0.0, solid: bool = false) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material(color, emission)
	parent.add_child(n)
	n.position = pos
	if solid:
		var body = StaticBody3D.new()
		n.add_child(body)
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	return n

static func sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 16
	mesh.rings = 8
	n.mesh = mesh
	n.material_override = material(color, emission)
	parent.add_child(n)
	n.position = pos
	return n

static func beam(parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var n = box(parent, (a+b)/2, Vector3(width, width, a.distance_to(b)), color, emission)
	if a.distance_to(b) > 0.01:
		n.look_at_from_position((a+b)/2, b, Vector3.UP if abs((b-a).normalized().dot(Vector3.UP)) < 0.99 else Vector3.RIGHT)
	return n

static func ring(parent: Node3D, pos: Vector3, radius: float, thickness: float, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 40
	mesh.ring_segments = 8
	n.mesh = mesh
	n.material_override = material(color, emission)
	parent.add_child(n)
	n.position = pos
	return n

static func light(parent: Node3D, pos: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var l = OmniLight3D.new()
	parent.add_child(l)
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = reach
	return l

static func sign_text(parent: Node3D, pos: Vector3, text: String, size: int, color: Color, rotation_y: float = 0.0) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.018
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	parent.add_child(label)
	label.position = pos
	label.rotation.y = rotation_y
	return label

static func room(parent: Node3D, center: Vector3, size: Vector3, openings: Dictionary, accent: Color, sector: String,windows: Dictionary = {}) -> void:
	var dark = Color("263641")
	var panel = Color("42545e")
	var ribs = Color("101d27")
	var w = size.x/2
	var h = size.y/2
	var d = size.z/2
	for sign in [-1,1]:
		var hatch = "top" if sign==1 else "bottom"
		var plane_y = sign*(h+0.3)
		if openings.has(hatch):
			var hole = float(openings[hatch])
			for side in [-1,1]:
				if size.x>hole: box(parent,center+Vector3(side*(w+hole/2)/2,plane_y,0),Vector3(w-hole/2,0.6,size.z),dark,0,true)
				if size.z>hole: box(parent,center+Vector3(0,plane_y,side*(d+hole/2)/2),Vector3(hole,0.6,d-hole/2),dark,0,true)
			var rim = ring(parent,center+Vector3(0,sign*(h-0.05),0),hole*0.54,0.08,accent,1.4)
			rim.scale.z = 1.0
		else:
			box(parent,center+Vector3(0,plane_y,0),Vector3(size.x,0.6,size.z),dark,0,true)
	for side in [-1,1]:
		var key = "left" if side == -1 else "right"
		if openings.has(key):
			var gap = float(openings[key])
			for end in [-1,1]:
				box(parent,center+Vector3(side*(w+0.3),0,end*(d+gap/2)/2),Vector3(0.6,size.y,d-gap/2),dark,0,true)
			for up in ([-1,1] if h > 5 else []):
				box(parent,center+Vector3(side*(w+0.3),up*(h+5)/2,0),Vector3(0.6,h-5,gap),dark,0,true)
		else:
			box(parent,center+Vector3(side*(w+0.3),0,0),Vector3(0.6,size.y,size.z),dark,0,true)
		key = "front" if side == -1 else "back"
		if openings.has(key):
			var gap = float(openings[key])
			for end in [-1,1]:
				box(parent,center+Vector3(end*(w+gap/2)/2,0,side*(d+0.3)),Vector3(w-gap/2,size.y,0.6),dark,0,true)
			for up in ([-1,1] if h > 5 else []):
				box(parent,center+Vector3(0,up*(h+5)/2,side*(d+0.3)),Vector3(gap,h-5,0.6),dark,0,true)
		elif windows.has(key):
			var cut: Vector2=windows[key]
			for end in [-1,1]:
				box(parent,center+Vector3(end*(w+cut.x/2)/2,0,side*(d+0.3)),Vector3(w-cut.x/2,size.y,0.6),dark,0,true)
			for up in [-1,1]:
				box(parent,center+Vector3(0,up*(h+cut.y/2)/2,side*(d+0.3)),Vector3(cut.x,h-cut.y/2,0.6),dark,0,true)
		else:
			box(parent,center+Vector3(0,0,side*(d+0.3)),Vector3(size.x,size.y,0.6),dark,0,true)
	# Repeated structure, inset floor plates and suspended service conduits.
	for z in range(int(-d+2),int(d),4):
		for side in [-1,1]:
			box(parent,center+Vector3(side*(w-0.15),0,z),Vector3(0.34,size.y,0.4),ribs)
			var side_key = "left" if side == -1 else "right"
			if not openings.has(side_key) or absf(z)>float(openings[side_key])/2+1.5:
				box(parent,center+Vector3(side*(w-0.055),0,z+1.8),Vector3(0.1,size.y-5,3.35),panel)
				box(parent,center+Vector3(side*(w-0.13),-h+2.8,z+1.8),Vector3(0.1,0.12,3.1),Color("172e3a"))
				for vent in range(4):
					box(parent,center+Vector3(side*(w-0.14),h-3.0-vent*0.25,z+1.8),Vector3(0.13,0.08,1.5),Color("13242f"))
				if z % 12 == 0:
					box(parent,center+Vector3(side*(w-0.2),0.6,z+1.8),Vector3(0.16,1.1,0.8),Color("162b39"))
					box(parent,center+Vector3(side*(w-0.3),0.7,z+1.8),Vector3(0.03,0.6,0.5),accent,0.8)
			box(parent,center+Vector3(side*(w-0.4),h-1.0,z),Vector3(0.13,0.16,2.5),accent,2.5)
			box(parent,center+Vector3(side*(w-0.4),-h+1.0,z),Vector3(0.13,0.16,2.5),accent,2.5)
			var brace = box(parent,center+Vector3(side*(w-1.05),-h+1.1,z),Vector3(0.4,3.0,0.5),ribs)
			brace.rotation.z = side * -0.65
		if not openings.has("bottom") or absf(z)>float(openings["bottom"])/2+2:
			box(parent,center+Vector3(0,-h+0.025,z),Vector3(size.x-3,0.06,3.7),panel)
		if not openings.has("top") or absf(z)>float(openings["top"])/2+1:
			box(parent,center+Vector3(0,h-0.15,z),Vector3(size.x,0.3,0.25),ribs)
		for x in [-1.5,1.5]:
			box(parent,center+Vector3(x,-h+0.07,z),Vector3(0.045,0.02,2.7),accent,0.7)
	for z in range(int(-d+5),int(d),12):
		light(parent,center+Vector3(0,h-2,z),accent,1.5,19)
		if not openings.has("top") or absf(z)>float(openings["top"])/2+1:
			box(parent,center+Vector3(0,h-0.3,z),Vector3(4,0.12,0.4),Color("cce9ec"),2.0)
	for key in openings:
		if key in ["top","bottom"]: continue
		var portal_center = center
		var along_x = key in ["left","right"]
		if along_x: portal_center.x += (-w if key=="left" else w)
		else: portal_center.z += (-d if key=="front" else d)
		portal(parent,portal_center,float(openings[key]),10,along_x,accent)
	# Recessed end-wall plates and utility manifolds.
	for side in [-1,1]:
		var key = "front" if side == -1 else "back"
		for x in range(int(-w+2),int(w),4):
			if windows.has(key) and absf(x)<windows[key].x/2+2: continue
			if openings.has(key) and absf(x)<float(openings[key])/2+2: continue
			box(parent,center+Vector3(x,0,side*(d-0.07)),Vector3(3.75,size.y-4,0.12),panel)
			box(parent,center+Vector3(x,-h+2,side*(d-0.15)),Vector3(3.2,0.1,0.12),ribs)
	for side in [-1,1]:
		var pipe = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.18
		cylinder.bottom_radius = 0.18
		cylinder.height = size.z
		cylinder.radial_segments = 10
		pipe.mesh = cylinder
		pipe.material_override = material(Color("647078"))
		parent.add_child(pipe)
		pipe.position = center+Vector3(side*(w-2),h-0.7,0)
		pipe.rotation.x = PI/2
	if not openings.has("front") and not windows.has("front"):
		sign_text(parent,center+Vector3(0,3,-d+0.05),sector,100,accent)

static func portal(parent: Node3D, center: Vector3, width: float, height: float, along_x: bool, accent: Color) -> void:
	var x = width/2
	var y = height/2
	var cut = 1.1
	var points = [Vector2(-x+cut,-y),Vector2(x-cut,-y),Vector2(x,-y+cut),Vector2(x,y-cut),Vector2(x-cut,y),Vector2(-x+cut,y),Vector2(-x,y-cut),Vector2(-x,-y+cut)]
	for i in range(8):
		var a = points[i]
		var b = points[(i+1)%8]
		var start = center+(Vector3(0,a.y,a.x) if along_x else Vector3(a.x,a.y,0))
		var end = center+(Vector3(0,b.y,b.x) if along_x else Vector3(b.x,b.y,0))
		beam(parent,start,end,0.3,Color("5b6c73"))
		if i%2 == 1: beam(parent,start,end,0.11,accent,1.6)

static func hull(parent: Node3D, color: Color) -> MeshInstance3D:
	var vertices = [Vector3(-0.25,-0.15,-3),Vector3(0.25,-0.15,-3),Vector3(0.25,0.15,-3),Vector3(-0.25,0.15,-3),Vector3(-1.3,-0.55,1.8),Vector3(1.3,-0.55,1.8),Vector3(1.3,0.55,1.8),Vector3(-1.3,0.55,1.8)]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0,2,1],[0,3,2],[4,5,6],[4,6,7],[0,4,7],[0,7,3],[1,2,6],[1,6,5],[3,7,6],[3,6,2],[0,1,5],[0,5,4]]:
		for i in face: st.add_vertex(vertices[i])
	st.generate_normals()
	var n = MeshInstance3D.new()
	n.mesh = st.commit()
	n.material_override = material(color)
	parent.add_child(n)
	return n
