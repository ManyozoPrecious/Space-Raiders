class_name StrafeBehavior
extends GSAISteeringBehavior
## Strafe: accelerates sideways relative to a target (with a gentle vertical
## weave) so attacking ships circle the player instead of flying straight.
## Extends the framework's GSAISteeringBehavior so it blends with the others.

var target: GSAIAgentLocation
## +1 strafes one way, -1 the other.
var side_sign := 1.0


func _init(_agent: GSAISteeringAgent, _target: GSAIAgentLocation) -> void:
	super._init(_agent)
	target = _target


func _calculate_steering(acceleration: GSAITargetAcceleration) -> void:
	var to_target := (target.position - agent.position).normalized()
	var side := to_target.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	var weave := Vector3.UP * sin(Time.get_ticks_msec() / 1000.0 * 1.5) * 0.3
	acceleration.linear = (side.normalized() * side_sign + weave).normalized() * agent.linear_acceleration_max
	acceleration.angular = 0.0
