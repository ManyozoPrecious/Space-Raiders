class_name EnemyShip
extends CharacterBody3D
## Flying enemy (scenes: enemy_fighter.tscn, enemy_gunship.tscn). Decisions are
## made by a finite state machine whose states are child nodes (Wander, Chase,
## Attack). Movement uses the GDQuest Godot Steering AI Framework
## (addons/com.gdquest.godot-steering-ai-framework, MIT licence): GSAISteeringAgent,
## GSAIPursue, GSAIArrive, GSAIFollowPath (over paths from the FlightNavigation3D
## plugin) and GSAIBlend, plus our own wander, strafe and obstacle avoidance
## behaviours built on the framework's GSAISteeringBehavior.

signal died(enemy: EnemyShip)
## Emitted whenever the enemy's health changes (the HUD shows a health bar).
signal health_changed(current: int, maximum: int)

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
var is_dead := false

# Steering framework objects (see _setup_steering).
var agent := GSAISteeringAgent.new()
var target_location := GSAIAgentLocation.new()
var path_end := Vector3.ZERO
var seek: GSAISeek
var pursue: GSAIPursue
var arrive: GSAIArrive
var follow_path: GSAIFollowPath
var wander: WanderBehavior
var strafe: StrafeBehavior
var avoid: AvoidObstaclesBehavior

const DRAG := 4.0

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
	_health.health_changed.connect(func(current: int, maximum: int) -> void: health_changed.emit(current, maximum))

	_setup_steering()

	# Give every AI state a reference to this enemy, let it build its steering
	# blend, then start in Wander once the level has positioned the enemy.
	for state in fsm.get_children():
		if state is EnemyState:
			(state as EnemyState).enemy = self
			(state as EnemyState).setup()
	fsm.register_children()
	fsm.start.call_deferred("Wander")


## Creates the framework agent and the behaviours that the states blend together.
func _setup_steering() -> void:
	agent.linear_speed_max = config["max_speed"]
	agent.linear_acceleration_max = config["acceleration"]
	agent.bounding_radius = float(config["size"]) * 0.4
	seek = GSAISeek.new(agent, target_location)
	pursue = GSAIPursue.new(agent, player.steering_agent, 1.5)
	arrive = GSAIArrive.new(agent, target_location)
	arrive.arrival_tolerance = 8.0
	arrive.deceleration_radius = 25.0
	follow_path = GSAIFollowPath.new(agent, GSAIPath.new([Vector3.ZERO, Vector3.FORWARD * 10.0]), 12.0)
	follow_path.arrival_tolerance = 5.0
	follow_path.deceleration_radius = 30.0
	wander = WanderBehavior.new(agent)
	strafe = StrafeBehavior.new(agent, player.steering_agent)
	avoid = AvoidObstaclesBehavior.new(agent, self)


## The framework only knows what we tell it, so refresh the agent every frame.
func _sync_agent() -> void:
	agent.position = global_position
	agent.linear_velocity = velocity
	agent.orientation = GSAIUtils.vector3_to_angle(-global_transform.basis.z)
	wander.forward = -global_transform.basis.z
	if has_target():
		player.sync_steering_agent()


func _physics_process(delta: float) -> void:
	_sync_agent()
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

## Asks the FlightNavigation3D plugin for a path and gives it to the
## GSAIFollowPath behaviour. Falls back to a straight line when no navigation
## data is available. Returns true when the plugin found a path.
func request_path(destination: Vector3) -> bool:
	var points: Array = []
	var found := false
	if level != null and level.is_nav_ready():
		points = Array(level.flight_nav.find_path(global_position, destination))
		found = not points.is_empty()
	if not found:
		points = [destination]
	var waypoints: Array = [global_position]
	for point in points:
		if (point as Vector3).distance_to(waypoints.back()) > 0.5:
			waypoints.append(point)
	if waypoints.size() < 2:
		waypoints.append(global_position - global_transform.basis.z * 5.0)
	path_end = waypoints.back()
	follow_path.path = GSAIPath.new(waypoints)
	return found


func path_finished() -> bool:
	return global_position.distance_to(path_end) < level.nav_reach_radius * 1.5


# --- Movement -------------------------------------------------------------

## Applies the acceleration chosen by the steering behaviours.
func apply_steering(acceleration: GSAITargetAcceleration, delta: float, look_target := Vector3.INF) -> void:
	velocity = GSAIUtils.clampedv3(velocity + acceleration.linear * delta, agent.linear_speed_max)
	velocity = velocity.move_toward(Vector3.ZERO, DRAG * delta)
	var facing := velocity if look_target == Vector3.INF else look_target - global_position
	_face_direction(facing, delta)
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
