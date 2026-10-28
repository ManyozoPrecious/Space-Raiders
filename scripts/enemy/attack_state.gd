class_name AttackState
extends EnemyState
## Attacking: the player is in weapon range. Keeps a preferred distance,
## strafes, faces the player and shoots lasers.

var _strafe_direction := 1.0
var _strafe_timer := 0.0
var _time := 0.0


func enter(_msg: Dictionary = {}) -> void:
	_strafe_direction = 1.0 if enemy.rng.randf() < 0.5 else -1.0
	_strafe_timer = enemy.rng.randf_range(1.0, 2.5)


func physics_update(delta: float) -> void:
	var e := enemy
	if not e.has_target():
		finished.emit("Wander", {})
		return
	var distance := e.distance_to_player()
	var attack_range: float = e.config["attack_range"]
	if distance > attack_range * 1.3 or not e.has_line_of_sight_to_player():
		finished.emit("Chase", {})
		return

	_time += delta
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_direction *= -1.0
		_strafe_timer = e.rng.randf_range(1.5, 3.0)

	var max_speed: float = e.config["max_speed"]
	var to_player := e.player.global_position - e.global_position
	var direction := to_player.normalized()
	var preferred := attack_range * 0.6
	var desired := Vector3.ZERO
	if distance > preferred:
		desired += direction * max_speed * 0.6
	elif distance < preferred * 0.6:
		desired -= direction * max_speed * 0.6
	var side := direction.cross(Vector3.UP).normalized()
	desired += side * _strafe_direction * max_speed * 0.5
	desired += Vector3.UP * sin(_time * 1.5) * max_speed * 0.15
	e.steer(desired, delta, e.player.global_position)

	if e.is_facing(e.player.global_position, 12.0):
		e.fire_at_player()
