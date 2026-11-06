class_name AvoidObstaclesBehavior
extends GSAISteeringBehavior
## Obstacle avoidance for static level geometry using raycasts (see
## Steering.avoid_obstacles). The framework's own GSAIAvoidCollisions works on
## other steering agents, not on static bodies, so this extends the framework's
## base class GSAISteeringBehavior to be usable inside a GSAIBlend.

var body: Node3D
var look_ahead := 45.0


func _init(_agent: GSAISteeringAgent, _body: Node3D) -> void:
	super._init(_agent)
	body = _body


func _calculate_steering(acceleration: GSAITargetAcceleration) -> void:
	var forward := agent.linear_velocity.normalized() if agent.linear_velocity.length() > 2.0 else -body.global_transform.basis.z
	var push := Steering.avoid_obstacles(body, forward, look_ahead)
	acceleration.linear = GSAIUtils.clampedv3(push * agent.linear_acceleration_max, agent.linear_acceleration_max)
	acceleration.angular = 0.0
