class_name WanderState
extends EnemyState
## Wandering: the player is not close. Flies between random waypoints using
## path following (FlightNavigation3D) blended with the wander behaviour.


func enter(_msg: Dictionary = {}) -> void:
	_pick_destination()


func physics_update(delta: float) -> void:
	var e := enemy
	if e.has_target() and e.distance_to_player() < float(e.config["detect_range"]):
		finished.emit("Chase", {})
		return
	if e.path_finished():
		_pick_destination()
	var max_speed: float = e.config["max_speed"]
	var desired := e.follow_path_velocity() * 0.7
	e.wander_offset = Steering.update_wander_offset(e.wander_offset, e.rng)
	desired += Steering.wander(-e.global_transform.basis.z, e.wander_offset, max_speed) * 0.35
	e.steer(desired, delta)


func _pick_destination() -> void:
	enemy.request_path(enemy.level.random_point_in_bounds(enemy.rng))
