class_name SpaceLevel
extends LevelBase
## Level 1: an asteroid field in deep space with distant planets and a
## space-station beacon. Models are CC0 assets from the provided resources.

const ROCKS := [
	"res://assets/env/GLTF/Rock_Large_1.gltf",
	"res://assets/env/GLTF/Rock_Large_2.gltf",
	"res://assets/env/GLTF/Rock_Large_3.gltf",
	"res://assets/env/GLTF/Rock_1.gltf",
	"res://assets/env/GLTF/Rock_3.gltf",
]
const PLANETS := [
	"res://assets/env/GLTF/Planet_2.gltf",
	"res://assets/env/GLTF/Planet_5.gltf",
	"res://assets/env/GLTF/Planet_9.gltf",
	"res://assets/env/GLTF/Planet_11.gltf",
]

var _star_root: Node3D


func _init() -> void:
	kills_required = 6
	bounds_radius = 300.0
	fly_height_range = Vector2(-110.0, 110.0)
	nav_center = Vector3.ZERO


func _player_start() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0, 0, 240))


func _goal_position() -> Vector3:
	return Vector3(-40, 20, -230)


func _enemy_layout() -> Array[String]:
	return ["fighter", "fighter", "fighter", "fighter", "gunship", "gunship"]


func _objective_text() -> String:
	return "FLY INTO THE BEACON!"


func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.36, 0.5)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 40, 0)
	sun.light_energy = 1.4
	sun.light_color = Color(1.0, 0.95, 0.85)
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(30, -140, 0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.5, 0.6, 1.0)
	add_child(fill)

	_build_stars()
	_build_planets()
	_build_asteroids()
	_build_station()


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


func _build_planets() -> void:
	var placements := [
		{"pos": Vector3(-700, 150, -500), "size": 420.0},
		{"pos": Vector3(650, -120, -650), "size": 300.0},
		{"pos": Vector3(500, 260, 600), "size": 240.0},
		{"pos": Vector3(-600, -200, 500), "size": 340.0},
	]
	for i in placements.size():
		var planet := ModelUtil.instantiate_fitted(load(PLANETS[i]), placements[i]["size"])
		planet.position = placements[i]["pos"]
		add_child(planet)


func _build_asteroids() -> void:
	for i in 55:
		var angle := rng.randf() * TAU
		var distance := sqrt(rng.randf()) * (bounds_radius - 20.0)
		var position := Vector3(cos(angle) * distance, rng.randf_range(-100.0, 100.0), sin(angle) * distance)
		if position.distance_to(_player_start().origin) < 90.0 or position.distance_to(_goal_position()) < 70.0:
			continue
		var size := rng.randf_range(16.0, 70.0)
		var rotation_euler := Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		add_obstacle(ROCKS[rng.randi() % ROCKS.size()], size, position, rotation_euler)


func _build_station() -> void:
	var station := ModelUtil.instantiate_fitted(load("res://assets/env/GLTF/GeodesicDome.gltf"), 55.0)
	station.position = _goal_position() + Vector3(0, -45, 0)
	add_child(station)
