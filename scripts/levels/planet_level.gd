class_name PlanetLevel
extends LevelBase
 

const WALL_ROCKS := [
	"res://assets/env/GLTF/Rock_Large_1.gltf",
	"res://assets/env/GLTF/Rock_Large_2.gltf",
	"res://assets/env/GLTF/Rock_Large_3.gltf",
]
const TOWERS := [
	"res://assets/env/GLTF/Tree_Swirl_1.gltf",
	"res://assets/env/GLTF/Tree_Spiral_2.gltf",
	"res://assets/env/GLTF/Tree_Spikes_1.gltf",
	"res://assets/env/GLTF/Tree_Floating_2.gltf",
]
const DECOR := [
	"res://assets/env/GLTF/Tree_Blob_1.gltf",
	"res://assets/env/GLTF/Tree_Blob_2.gltf",
	"res://assets/env/GLTF/Bush_1.gltf",
	"res://assets/env/GLTF/Plant_3.gltf",
	"res://assets/env/GLTF/Tree_Light_1.gltf",
	"res://assets/env/GLTF/Grass_3.gltf",
]


func _init() -> void:
	kills_required = 8
	bounds_radius = 300.0
	fly_height_range = Vector2(25.0, 170.0)
	nav_center = Vector3(0, 220, 0)


func _player_start() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0, 70, 250))


func _goal_position() -> Vector3:
	return Vector3(0, 30, -250)


func _enemy_layout() -> Array[String]:
	return ["fighter", "fighter", "fighter", "fighter", "fighter", "gunship", "gunship", "gunship"]


func _objective_text() -> String:
	return "LAND AT THE OUTPOST BEACON!"


func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.18, 0.4, 0.8)
	sky_material.sky_horizon_color = Color(0.8, 0.78, 0.9)
	sky_material.ground_horizon_color = Color(0.8, 0.78, 0.9)
	sky_material.ground_bottom_color = Color(0.3, 0.4, 0.4)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.76, 0.88)
	env.fog_density = 0.0012
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -35, 0)
	sun.light_energy = 1.5
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.shadow_enabled = not OS.has_feature("mobile")
	add_child(sun)

	_build_ground()
	_build_canyon()
	_build_towers()
	_build_decor()
	_build_outpost()


func _build_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.width = 512
	noise_texture.height = 512
	noise_texture.seamless = true
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.8, 0.6)
	material.albedo_texture = noise_texture
	material.uv1_scale = Vector3(40, 40, 1)
	material.roughness = 1.0
	var plane := PlaneMesh.new()
	plane.size = Vector2(3000, 3000)
	var ground_mesh := MeshInstance3D.new()
	ground_mesh.mesh = plane
	ground_mesh.material_override = material
	add_child(ground_mesh)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3000, 20, 3000)
	collider.shape = box
	collider.position.y = -10.0
	body.add_child(collider)
	add_child(body)
	register_nav_target(body)


func _build_canyon() -> void:
	# Two rows of huge rocks make the canyon walls along the flight path.
	
	for side: float in [-1.0, 1.0]:
		var z: float = 330.0
		while z > -330.0:
			var size: float = rng.randf_range(110.0, 190.0)
			var x: float = side * rng.randf_range(185.0, 240.0)
			var rotation_euler: Vector3 = Vector3(0.0, rng.randf() * TAU, 0.0)
			add_obstacle(WALL_ROCKS[rng.randi() % WALL_ROCKS.size()], size, Vector3(x, size * 0.3, z), rotation_euler)
			z -= rng.randf_range(80.0, 120.0)



func _build_towers() -> void:
	for i in 16:
		var size := rng.randf_range(70.0, 150.0)
		var position := Vector3(rng.randf_range(-150.0, 150.0), size * 0.5, rng.randf_range(-200.0, 180.0))
		if position.distance_to(_player_start().origin * Vector3(1, 0, 1)) < 80.0:
			continue
		if Vector2(position.x, position.z).distance_to(Vector2(_goal_position().x, _goal_position().z)) < 70.0:
			continue
		add_obstacle(TOWERS[rng.randi() % TOWERS.size()], size, position, Vector3(0, rng.randf() * TAU, 0), "cylinder")


func _build_decor() -> void:
	for i in 90:
		var size := rng.randf_range(6.0, 22.0)
		var position := Vector3(rng.randf_range(-260.0, 260.0), size * 0.5, rng.randf_range(-300.0, 300.0))
		var model := ModelUtil.instantiate_fitted(load(DECOR[rng.randi() % DECOR.size()]), size)
		model.position = position
		model.rotation.y = rng.randf() * TAU
		add_child(model)


func _build_outpost() -> void:
	var base := _goal_position() * Vector3(1, 0, 1)
	var dome := ModelUtil.instantiate_fitted(load("res://assets/env/GLTF/GeodesicDome.gltf"), 40.0)
	dome.position = base + Vector3(-30, 20, 0)
	add_child(dome)
	var building := ModelUtil.instantiate_fitted(load("res://assets/env/GLTF/Base_Large.gltf"), 36.0)
	building.position = base + Vector3(30, 18, -10)
	add_child(building)
