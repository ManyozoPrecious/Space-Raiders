class_name WanderState
extends EnemyState
## Wandering: the player is not close. Follows a FlightNavigation3D path to a
## random waypoint (GSAIFollowPath) blended with wander and obstacle avoidance.


func setup() -> void:
	blend = GSAIBlend.new(enemy.agent)
	blend.add(enemy.follow_path, 0.7)
	blend.add(enemy.wander, 0.35)
	blend.add(enemy.avoid, 1.8)


func enter(_msg: Dictionary = {}) -> void:
	_pick_destination()


func physics_update(delta: float) -> void:
	var e := enemy
	if e.has_target() and e.distance_to_player() < float(e.config["detect_range"]):
		finished.emit("Chase", {})
		return
	if e.path_finished():
		_pick_destination()
	steer_with(blend, delta)


func _pick_destination() -> void:
	enemy.request_path(enemy.level.random_point_in_bounds(enemy.rng))
