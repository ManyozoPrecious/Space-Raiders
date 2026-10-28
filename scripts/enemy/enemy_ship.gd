class_name EnemyShip
extends CharacterBody3D
## Flying enemy (scenes: enemy_fighter.tscn, enemy_gunship.tscn). Decisions are
## made by a finite state machine whose states are child nodes (Wander, Chase,
## Attack). Movement uses steering behaviours: wander, pursue, path following
## along FlightNavigation3D paths, and obstacle avoidance.

signal died(enemy: EnemyShip)

const SCENES := {
	"fighter": "res://scenes/enemy_fighter.tscn",
	"gunship": "res://scenes/enemy_gunship.tscn",
}

const TYPES := {
	"fighter": {
		"label": "Raider",
		"model": "res://assets/ships/Insurgent/glTF/Insurgent.gltf",
		"texture": "res://assets/ships/Insurgent/Textures/Insurgent_Red.png",
		"size": 8.0,
		"yaw_offset": 180.0,
		"max_speed": 44.0,
		"acceleration": 32.0,
		"turn_speed": 3.2,
		"health": 40,
		"damage": 7,
		"fire_cooldown": 0.55,
		"burst": 1,
		"projectile_speed": 120.0,
		"spread_deg": 3.0,
		"detect_range": 230.0,
		"attack_range": 100.0,
		"marker": "fighter",
	},
	"gunship": {
		"label": "Gunship",
		"model": "res://assets/ships/Challenger/glTF/Challenger.gltf",
		"texture": "res://assets/ships/Challenger/Textures/Challenger_Red.png",
		"size": 12.0,
		"yaw_offset": 180.0,
		"max_speed": 28.0,
		"acceleration": 15.0,
		"turn_speed": 1.8,
		"health": 120,
		"damage": 12,
		"fire_cooldown": 1.2,
		"burst": 2,
		"projectile_speed": 105.0,
		"spread_deg": 2.0,
		"detect_range": 260.0,
		"attack_range": 140.0,
		"marker": "gunship",
	},
}

## Which entry of TYPES this scene uses (set in the scene's Inspector).
@export var type_key := "fighter"

var config: Dictionary
var player: PlayerShip
var level: LevelBase
var rng := RandomNumberGenerator.new()
var wander_offset := Vector3.FORWARD * 6.0
var path := PackedVector3Array()
var path_index := 0
var is_dead := false

var _fire_timer := 0.0
var _los_timer := 0.0
var _has_los := false

@onready var fsm: StateMachine = $StateMachine
@onready var _model_holder: Node3D = $Model
@onready var _health: HealthComponent = $HealthComponent


static func create(type: String, target: PlayerShip, owner_level: LevelBase) -> EnemyShip:
	var enemy: EnemyShip = load(SCENES[type]).instantiate()
	enemy.type_key = type
	enemy.player = target
	enemy.level = owner_level
	return enemy


func _ready() -> void:
	config = TYPES[type_key]
	rng.randomize()
	add_to_group("enemies")

	_model_holder.add_child(ModelUtil.instantiate_fitted(load(config["model"]), config["size"], config["texture"], config["yaw_offset"]))

	_health.max_health = config["health"]
	_health.reset()
	_health.died.connect(_on_died)

	# Give every AI state a reference to this enemy, then start in Wander.
	for state in fsm.get_children():
		if state is EnemyState:
			(state as EnemyState).enemy = self
	fsm.register_children()
	fsm.start("Wander")


func _physics_process(delta: float) -> void:
	_fire_timer -= delta
	_los_timer -= delta
	if _los_timer <= 0.0:
		_los_timer = 0.2
		_has_los = has_target() and Steering.has_line_of_sight(self, player.global_position)


# --- Queries used by the states -------------------------------------------

func has_target() -> bool:
	return player != null and is_instance_valid(player) and not player.is_dead


func distance_to_player() -> float:
	return global_position.distance_to(player.global_position)


func has_line_of_sight_to_player() -> bool:
	return _has_los


func is_facing(target: Vector3, max_angle_deg: float) -> bool:
	var to_target := (target - global_position).normalized()
	return (-global_transform.basis.z).dot(to_target) > cos(deg_to_rad(max_angle_deg))


# --- Navigation helpers ---------------------------------------------------

## Asks the FlightNavigation3D plugin for a path. Falls back to a straight
## line (single waypoint) when no navigation data is available.
func request_path(destination: Vector3) -> bool:
	path = PackedVector3Array()
	path_index = 0
	if level != null and level.is_nav_ready():
		path = level.flight_nav.find_path(global_position, destination)
	if path.is_empty():
		path = PackedVector3Array([destination])
		return false
	return true


func follow_path_velocity() -> Vector3:
	path_index = Steering.path_follow_index(global_position, path, path_index, level.nav_reach_radius)
	return Steering.seek(global_position, path[path_index], config["max_speed"])


func path_finished() -> bool:
	if path.is_empty():
		return true
	var last := path[path.size() - 1]
	return path_index >= path.size() - 1 and global_position.distance_to(last) < level.nav_reach_radius * 1.5


# --- Movement -------------------------------------------------------------

## Applies a desired velocity with acceleration limits and obstacle avoidance.
func steer(desired_velocity: Vector3, delta: float, look_target := Vector3.INF) -> void:
	var forward := velocity.normalized() if velocity.length() > 2.0 else -global_transform.basis.z
	var avoid := Steering.avoid_obstacles(self, forward, 45.0)
	desired_velocity += avoid * float(config["max_speed"]) * 1.8
	desired_velocity = desired_velocity.limit_length(config["max_speed"])
	velocity = velocity.move_toward(desired_velocity, float(config["acceleration"]) * delta)
	if look_target != Vector3.INF:
		_face_direction(look_target - global_position, delta)
	else:
		_face_direction(velocity, delta)
	move_and_slide()


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.25:
		return
	var dir := direction.normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	var target_basis := Basis.looking_at(dir, up)
	var blend := clampf(float(config["turn_speed"]) * delta, 0.0, 1.0)
	global_transform.basis = global_transform.basis.slerp(target_basis, blend).orthonormalized()


# --- Combat ---------------------------------------------------------------

func fire_at_player() -> void:
	if _fire_timer > 0.0 or not has_target():
		return
	_fire_timer = config["fire_cooldown"]
	var size: float = config["size"]
	var burst: int = config["burst"]
	var speed: float = config["projectile_speed"]
	for i in burst:
		var side := (float(i) - (burst - 1) * 0.5) * size * 0.5
		var origin := global_position - global_transform.basis.z * size * 0.55 + global_transform.basis.x * side
		var travel_time := origin.distance_to(player.global_position) / speed
		var aim_point := player.global_position + player.velocity * travel_time * 0.7
		var direction := (aim_point - origin).normalized()
		var spread := deg_to_rad(float(config["spread_deg"]))
		direction = (direction + Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * spread).normalized()
		Projectile.spawn(get_tree().current_scene, origin, direction, false, config["damage"], speed, self)
	AudioManager.play_sfx_3d("laser_enemy", global_position, -6.0)


func take_damage(amount: int) -> void:
	if is_dead:
		return
	AudioManager.play_sfx_3d("hit", global_position, -4.0)
	_health.take_damage(amount)
	# Getting shot makes a wandering enemy hunt the player.
	if not is_dead and fsm.current_name == "Wander":
		fsm.transition_to("Chase")


func _on_died() -> void:
	is_dead = true
	Vfx.explosion(get_tree().current_scene, global_position, float(config["size"]) / 6.0)
	AudioManager.play_sfx_3d("explosion", global_position)
	died.emit(self)
	queue_free()
