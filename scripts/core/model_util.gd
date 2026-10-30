class_name ModelUtil
extends RefCounted
 
static func instantiate_fitted(scene: PackedScene, target_size: float, texture_path := "", yaw_offset_deg := 0.0) -> Node3D:
	var wrapper := Node3D.new()
	var model: Node3D = scene.instantiate()
	wrapper.add_child(model)
	model.rotation.y = deg_to_rad(yaw_offset_deg)
	var aabb := compute_aabb(model, wrapper)
	var longest := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if longest > 0.0001:
		var s := target_size / longest
		var center := aabb.position + aabb.size * 0.5
		model.transform = Transform3D(Basis().scaled(Vector3.ONE * s), -center * s) * model.transform
	if texture_path != "" and ResourceLoader.exists(texture_path):
		apply_texture(model, load(texture_path))
	return wrapper


 
static func compute_aabb(node: Node3D, root: Node3D) -> AABB:
	var result := AABB()
	var has_any := false
	for mesh_instance in _find_meshes(node):
		var local_aabb: AABB = mesh_instance.get_aabb()
		var xf := _relative_transform(mesh_instance, root)
		var box: AABB = xf * local_aabb
		if has_any:
			result = result.merge(box)
		else:
			result = box
			has_any = true
	return result


static func apply_texture(node: Node, texture: Texture2D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 0.75
	material.metallic = 0.15
	for mesh_instance in _find_meshes(node):
		mesh_instance.material_override = material


static func _find_meshes(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_find_meshes(child))
	return found


static func _relative_transform(node: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var current: Node = node
	while current != root and current is Node3D:
		xf = (current as Node3D).transform * xf
		current = current.get_parent()
	return xf
