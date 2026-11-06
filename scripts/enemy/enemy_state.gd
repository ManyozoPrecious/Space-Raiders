class_name EnemyState
extends State
## Base class for enemy AI states. Each state owns a steering blend (a
## GSAIBlend from the steering framework) built in setup().

var enemy: EnemyShip
var blend: GSAIBlend

var _accel := GSAITargetAcceleration.new()


## Called once by the enemy after `enemy` is assigned; build behaviours here.
func setup() -> void:
	pass


## Calculates the acceleration of [param behavior] and moves the enemy with it.
func steer_with(behavior: GSAISteeringBehavior, delta: float, look_target := Vector3.INF) -> void:
	behavior.calculate_steering(_accel)
	enemy.apply_steering(_accel, delta, look_target)
