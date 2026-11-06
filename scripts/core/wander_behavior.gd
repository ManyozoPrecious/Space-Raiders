class_name WanderBehavior
extends GSAISteeringBehavior
## Wander: steers towards a point on a sphere that floats in front of the agent
## and is nudged randomly every frame, giving smooth meandering flight.
## The framework has no wander behaviour, so this extends its base class
## GSAISteeringBehavior so it can be mixed with the others in a GSAIBlend.
## Idea after Craig Reynolds, "Steering Behaviors For Autonomous Characters" (1999).

## The agent's current forward direction; the owner updates it every frame.
var forward := Vector3.FORWARD
var circle_distance := 12.0
var circle_radius := 6.0
var jitter := 0.7

var _offset := Vector3.FORWARD * 6.0
var _rng := RandomNumberGenerator.new()


func _init(_agent: GSAISteeringAgent) -> void:
	super._init(_agent)
	_rng.randomize()


func _calculate_steering(acceleration: GSAITargetAcceleration) -> void:
	_offset += Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * jitter
	if _offset.length_squared() < 0.0001:
		_offset = Vector3.FORWARD
	_offset = _offset.normalized() * circle_radius
	acceleration.linear = (forward * circle_distance + _offset).normalized() * agent.linear_acceleration_max
	acceleration.angular = 0.0
