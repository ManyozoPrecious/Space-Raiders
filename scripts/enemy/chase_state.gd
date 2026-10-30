class_name ChaseState
extends EnemyState
 

const REPATH_INTERVAL := 1.0

var _repath_timer := 0.0


func enter(_msg: Dictionary = {}) -> void:
	_repath_timer = 0.0


func physics_update(delta: float) -> void:
	var e := enemy
	if not e.has_target():
		finished.emit("Wander", {})
		return
	var distance := e.distance_to_player()
	var sees_player := e.has_line_of_sight_to_player()
	if distance > float(e.config["detect_range"]) * 1.4:
		finished.emit("Wander", {})
		return
	if distance < float(e.config["attack_range"]) and sees_player:
		finished.emit("Attack", {})
		return

	var max_speed: float = e.config["max_speed"]
	var desired := Steering.pursue(e.global_position, e.player.global_position, e.player.velocity, max_speed)
	if not sees_player:
		_repath_timer -= delta
		if _repath_timer <= 0.0:
			_repath_timer = REPATH_INTERVAL
			e.request_path(e.player.global_position)
		desired = e.follow_path_velocity()
	e.steer(desired, delta)
