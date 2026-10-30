class_name PlayerShip
extends CharacterBody3D
 

signal health_changed(current: int, maximum: int)
signal died

const SCENE_PATH := "res://scenes/player_ship.tscn"
const COLLISION_COOLDOWN := 0.6
const COLLISION_DAMAGE := 12
const AIM_ASSIST_RANGE := 350.0
const AIM_ASSIST_COS := 0.97

var stats: ShipStats
var touch_steer := Vector2.ZERO
var touch_fire := false
var is_dead := false
var current_speed := 0.0

var _fire_cooldown := 0.0
var _collision_cooldown := 0.0
var _next_muzzle := 0

@onready var _model: Node3D = $Model
@onready var _hull_shape: CollisionShape3D = $CollisionShape3D
@onready var _muzzles: Array = $Muzzles.get_children()
@onready var _exhausts: Array = [$ExhaustLeft, $ExhaustRight]
@onready var _health: HealthComponent = $HealthComponent


static func create(ship_stats: ShipStats) -> PlayerShip:
	var ship: PlayerShip = load(SCENE_PATH).instantiate()
	ship.stats = ship_stats
	return ship


func _ready() -> void:
	add_to_group("player")
	# The scene is laid out for a ship 9 units long; scale it to the chosen ship.
	var scale_factor := stats.model_size / 9.0
	(_hull_shape.shape as SphereShape3D).radius = stats.model_size * 0.32
	for node in _muzzles:
		(node as Node3D).position *= scale_factor
	for node in _exhausts:
		(node as Node3D).position *= scale_factor

	_model.add_child(ModelUtil.instantiate_fitted(load(stats.model_path), stats.model_size, stats.texture_path, stats.yaw_offset_deg))

	_health.max_health = stats.max_health
	_health.reset()
	_health.health_changed.connect(func(c: int, m: int) -> void: health_changed.emit(c, m))
	_health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	var steer := touch_steer
	if steer.length() < 0.05:
		steer = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var firing := touch_fire or Input.is_key_pressed(KEY_SPACE)

	current_speed = move_toward(current_speed, stats.max_speed, stats.acceleration * delta)
	# Joystick right = turn right, joystick up = nose up.
	rotate_object_local(Vector3.UP, -steer.x * stats.turn_rate * delta)
	rotate_object_local(Vector3.RIGHT, -steer.y * stats.turn_rate * delta)
	# Cosmetic banking on the model only.
	_model.rotation.z = lerp_angle(_model.rotation.z, -steer.x * 0.7, 6.0 * delta)
	_model.rotation.x = lerp_angle(_model.rotation.x, -steer.y * 0.2, 6.0 * delta)

	velocity = -global_transform.basis.z * current_speed
	move_and_slide()
	_handle_collisions(delta)

	_fire_cooldown -= delta
	if firing and _fire_cooldown <= 0.0:
		_fire()


func take_damage(amount: int) -> void:
	if is_dead:
		return
	AudioManager.play_sfx("hit_player", -2.0)
	_health.take_damage(amount)


func _handle_collisions(delta: float) -> void:
	_collision_cooldown -= delta
	if get_slide_collision_count() == 0:
		return
	var collision := get_slide_collision(0)
	# Bounce away from whatever we hit and lose speed.
	current_speed *= 0.35
	global_position += collision.get_normal() * 1.5
	if _collision_cooldown <= 0.0:
		_collision_cooldown = COLLISION_COOLDOWN
		take_damage(COLLISION_DAMAGE)


func _fire() -> void:
	_fire_cooldown = stats.fire_cooldown
	var muzzle := _muzzles[_next_muzzle] as Node3D
	_next_muzzle = (_next_muzzle + 1) % _muzzles.size()
	var origin := muzzle.global_position
	var direction := _get_aim_direction(origin)
	Projectile.spawn(get_tree().current_scene, origin, direction, true, 10, 190.0, self)
	AudioManager.play_sfx("laser_player", -8.0, randf_range(0.95, 1.1))


## Aim assist for touch play: bends the shot towards the enemy closest to the
## crosshair (inside a narrow cone), leading it by the bolt travel time.
func _get_aim_direction(origin: Vector3) -> Vector3:
	var forward := -global_transform.basis.z
	var best_dir := forward
	var best_dot := AIM_ASSIST_COS
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var enemy_node := enemy as Node3D
		var to_enemy := enemy_node.global_position - origin
		var distance := to_enemy.length()
		if distance > AIM_ASSIST_RANGE or distance < 1.0:
			continue
		var dot := forward.dot(to_enemy / distance)
		if dot > best_dot:
			best_dot = dot
			var lead := enemy_node.global_position
			if enemy_node is CharacterBody3D:
				lead += (enemy_node as CharacterBody3D).velocity * (distance / 190.0)
			best_dir = (lead - origin).normalized()
	return forward.lerp(best_dir, 0.8).normalized()


func _on_died() -> void:
	is_dead = true
	died.emit()
