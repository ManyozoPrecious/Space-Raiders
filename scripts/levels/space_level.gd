class_name SpaceLevel
extends SceneLevel
 
var _star_root: Node3D


func _init() -> void:
	kills_required = 1
	bounds_radius = 300.0
	fly_height_range = Vector2(-110.0, 110.0)
	nav_center = Vector3.ZERO


func _enemy_layout() -> Array[String]:
	return ["fighter", "fighter", "fighter", "fighter", "gunship", "gunship"]


func _objective_text() -> String:
	return "FLY INTO THE BEACON!"


func _setup_level() -> void:
	_build_stars()


func _process(_delta: float) -> void:
	if _star_root != null and player != null:
		_star_root.global_position = player.global_position


func _build_stars() -> void:
	_star_root = Node3D.new()
	add_child(_star_root)
	var mesh := SphereMesh.new()
	mesh.radius = 1.4
	mesh.height = 2.8
	mesh.radial_segments = 4
	mesh.rings = 2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1, 1, 1)
	mesh.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = 450
	for i in multimesh.instance_count:
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.5, 1.6)), direction * 1400.0))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_star_root.add_child(instance)
