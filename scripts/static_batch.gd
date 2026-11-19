extends RefCounted
## Bake only immutable decorative geometry. Bodies keep their world transforms.
static func optimize(game: Node3D) -> Dictionary:
	var excluded={}
	if is_instance_valid(game.menu_ship): excluded[game.menu_ship.get_instance_id()]=true
	for door in game.doors: excluded[door.get_instance_id()]=true
	for target in game.targets: excluded[target.node.get_instance_id()]=true
	for pickup in game.pickups: excluded[pickup.node.get_instance_id()]=true
	for item in game.machinery: excluded[item.node.get_instance_id()]=true
	for h in game.director.hazards: excluded[h.get_instance_id()]=true
	if is_instance_valid(game.director.challenge_node): excluded[game.director.challenge_node.get_instance_id()]=true
	for item in game.exploration.items: excluded[item.node.get_instance_id()]=true
	for node in game.systems.props+game.systems.foundries: excluded[node.get_instance_id()]=true
	var candidates: Array=[]
	collect(game.level,excluded,candidates)
	var groups={}
	var collisions=Node3D.new()
	collisions.name="PreservedCollision"
	game.level.add_child(collisions)
	for node in candidates:
		var transform=game.level.global_transform.affine_inverse()*node.global_transform
		var cell=Vector3i(floori(transform.origin.x/32),floori(transform.origin.y/24),floori(transform.origin.z/32))
		var key=str(cell)+"/"+node.mesh.get_class()+"/"+str(node.material_override.get_instance_id())
		if not groups.has(key):
			var surface=SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key]={"surface":surface,"material":node.material_override}
		groups[key].surface.append_from(node.mesh,0,transform)
		for child in node.get_children(): child.reparent(collisions,true)
		node.hide()
		node.queue_free()
	for key in groups:
		var node=MeshInstance3D.new()
		node.name="StaticBatch"
		node.mesh=groups[key].surface.commit()
		node.material_override=groups[key].material
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		game.level.add_child(node)
	return {"input_meshes":candidates.size(),"batches":groups.size()}
static func collect(node: Node,excluded: Dictionary,result: Array) -> void:
	if excluded.has(node.get_instance_id()): return
	if node is MeshInstance3D and node.mesh is PrimitiveMesh and node.material_override!=null and node.mesh.get_surface_count()==1:
		result.append(node)
	for child in node.get_children(): collect(child,excluded,result)
