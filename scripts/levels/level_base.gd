class_name LevelBase
extends Node3D
## Shared logic for every level: builds the player, camera, HUD, goal beacon,
## flight navigation volume and enemies, and tracks kills, time and game flow.
## Subclasses build the environment (see space_level.gd and planet_level.gd).

const NAV_TIMEOUT := 25.0
const NAV_LAYER_COUNT := 5
const VOXELIZATION_TARGET := "res://src/voxelization_target.tscn"

@export var kills_required := 6
@export var nav_size := 640.0

var bounds_radius := 300.0
var fly_height_range := Vector2(-100.0, 100.0)
var nav_center := Vector3.ZERO
var nav_reach_radius := 10.0
var flight_nav: FlightNavigation3D

var player: PlayerShip
var camera: ChaseCamera
var hud: Hud
var goal: GoalZone
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var enemies_killed := 0
var state := "loading"

var _nav_built := false
var _obstacles: Array[Dictionary] = []


func _ready() -> void:
	rng.seed = 424242
	_build_environment()
	_create_player()
	_create_camera()
	_create_hud()
	_create_goal()
	hud.show_loading(true)
	await _build_navigation()
	hud.show_loading(false)
	_spawn_enemies()
	AudioManager.play_music("level")
	state = "playing"
	hud.show_message("DESTROY %d ENEMIES" % kills_required, 4.0)



func _build_environment() -> void:
	pass


func _player_start() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0, 0, 250))


func _goal_position() -> Vector3:
	return Vector3(0, 0, -250)


func _enemy_layout() -> Array[String]:
	return ["fighter", "fighter", "fighter", "gunship"]


func _objective_text() -> String:
	return "REACH THE BEACON!"


 

func _create_player() -> void:
	player = PlayerShip.create(GameState.get_ship_stats(GameState.selected_ship))
	add_child(player)
	player.global_transform = _player_start()
	player.set_physics_process(false)
	player.died.connect(_on_player_died)


func _create_camera() -> void:
	camera = ChaseCamera.new()
	camera.target = player
	add_child(camera)
	camera.snap_to_target()


func _create_hud() -> void:
	hud = Hud.create()
	add_child(hud)
	player.health_changed.connect(hud.set_health)
	hud.set_health(player.stats.max_health, player.stats.max_health)
	hud.set_kills(0, kills_required)
	hud.restart_requested.connect(restart_level)


func _create_goal() -> void:
	goal = GoalZone.create()
	add_child(goal)
	goal.global_position = _goal_position()
	goal.reached.connect(_on_goal_reached)


func _spawn_enemies() -> void:
	for type in _enemy_layout():
		var enemy := EnemyShip.create(type, player, self)
		add_child(enemy)
		enemy.global_position = _find_free_spawn_point()
		enemy.died.connect(_on_enemy_died)
		hud.add_marker(enemy, EnemyShip.TYPES[type]["marker"])
	player.set_physics_process(true)


func _find_free_spawn_point() -> Vector3:
	var start := _player_start().origin
	var point := Vector3.ZERO
	for attempt in 60:
		point = random_point_in_bounds(rng)
		if point.distance_to(start) < 150.0:
			continue
		if _inside_obstacle(point, 25.0):
			continue
		return point
	return point


func _inside_obstacle(point: Vector3, margin: float) -> bool:
	for obstacle in _obstacles:
		if point.distance_to(obstacle["position"]) < float(obstacle["radius"]) + margin:
			return true
	return false


## Random point inside the playable volume (used for enemy wander targets).
func random_point_in_bounds(random: RandomNumberGenerator) -> Vector3:
	var flat := Vector2(random.randf_range(-1.0, 1.0), random.randf_range(-1.0, 1.0))
	if flat.length() > 1.0:
		flat = flat.normalized()
	flat *= bounds_radius * 0.8
	return nav_center_xz() + Vector3(flat.x, random.randf_range(fly_height_range.x, fly_height_range.y), flat.y)


func nav_center_xz() -> Vector3:
	return Vector3(nav_center.x, 0.0, nav_center.z)


## Adds a static obstacle built from an environment model. The model is scaled
## so its longest side is [param size]; `shape` is "sphere", "cylinder" or "box".
func add_obstacle(model_path: String, size: float, position: Vector3, rotation_euler := Vector3.ZERO, shape := "sphere") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = position
	body.rotation = rotation_euler
	body.add_child(ModelUtil.instantiate_fitted(load(model_path), size))
	var collider := CollisionShape3D.new()
	match shape:
		"cylinder":
			var cylinder := CylinderShape3D.new()
			cylinder.height = size
			cylinder.radius = size * 0.18
			collider.shape = cylinder
		"box":
			var box := BoxShape3D.new()
			box.size = Vector3.ONE * size * 0.7
			collider.shape = box
		_:
			var sphere := SphereShape3D.new()
			sphere.radius = size * 0.42
			collider.shape = sphere
	body.add_child(collider)
	add_child(body)
	register_nav_target(body)
	_obstacles.append({"position": position, "radius": size * 0.5})
	return body


## Marks a physics body so the flight navigation volume treats it as solid.
func register_nav_target(body: Node) -> void:
	if ResourceLoader.exists(VOXELIZATION_TARGET):
		body.add_child(load(VOXELIZATION_TARGET).instantiate())


# --- Flight navigation (RevolNoom/godot_flight_navigation_3d) ---------------

func _build_navigation() -> void:
	var nav_scene = load("res://src/flight_navigation_3d.tscn")
	flight_nav = nav_scene.instantiate() as FlightNavigation3D
	
	 
	flight_nav.size = Vector3.ONE * nav_size
	flight_nav.pathfinder = GreedyAStar.new()
	var voxelizer := SvoVoxelizer.new()
	voxelizer.layer_count = NAV_LAYER_COUNT
	flight_nav.add_child(voxelizer)
	add_child(flight_nav)
	flight_nav.global_position = nav_center
	_run_nav_build()
	var waited := 0.0
	while not _nav_built and waited < NAV_TIMEOUT:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if not _nav_built:
		push_warning("Flight navigation did not finish; enemies will steer without paths.")


func _run_nav_build() -> void:
	await flight_nav.build_navigation()
	_nav_built = flight_nav.sparse_voxel_octree != null


func is_nav_ready() -> bool:
	return _nav_built and flight_nav != null


# --- Game flow --------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state != "playing":
		return
	elapsed += delta
	hud.set_time(elapsed)
	player.touch_steer = hud.joystick.output
	player.touch_fire = hud.fire_button.is_down
	_keep_player_in_bounds(delta)


func _keep_player_in_bounds(delta: float) -> void:
	var offset := player.global_position - nav_center_xz()
	var flat := Vector2(offset.x, offset.z).length()
	var outside := flat > bounds_radius or player.global_position.y > fly_height_range.y + 120.0 or player.global_position.y < fly_height_range.x - 120.0
	hud.show_out_of_bounds(outside)
	if outside:
		var to_center := (nav_center_xz() + Vector3(0, (fly_height_range.x + fly_height_range.y) * 0.5, 0)) - player.global_position
		var target_basis := Basis.looking_at(to_center.normalized(), Vector3.UP)
		player.global_transform.basis = player.global_transform.basis.slerp(target_basis, 1.4 * delta).orthonormalized()


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_enemy_died(_enemy: EnemyShip) -> void:
	enemies_killed += 1
	camera.shake(0.25)
	hud.set_kills(enemies_killed, kills_required)
	if enemies_killed >= kills_required and not goal.is_active and state == "playing":
		goal.set_active(true)
		hud.add_marker(goal, "goal")
		hud.set_objective(_objective_text())
		hud.show_message("TARGETS DESTROYED! " + _objective_text(), 5.0)
		AudioManager.play_sfx("goal")


func _on_goal_reached() -> void:
	if state != "playing":
		return
	state = "won"
	hud.show_out_of_bounds(false)
	AudioManager.play_sfx("ui_confirm")
	hud.show_complete(elapsed, enemies_killed)


func _on_player_died() -> void:
	if state != "playing":
		return
	state = "lost"
	hud.show_out_of_bounds(false)
	Vfx.explosion(self, player.global_position, 2.5)
	AudioManager.play_sfx("explosion_big")
	camera.shake(1.2)
	player.visible = false
	await get_tree().create_timer(1.3).timeout
	hud.show_game_over()
