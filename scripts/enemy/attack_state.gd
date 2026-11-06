class_name AttackState
extends EnemyState
## Attacking: the player is in weapon range. Arrives at a stand-off point at a
## preferred distance (GSAIArrive), strafes around the player, faces the player
## and shoots lasers.

var _strafe_timer := 0.0


func setup() -> void:
	blend = GSAIBlend.new(enemy.agent)
	blend.add(enemy.arrive, 0.9)
	blend.add(enemy.strafe, 0.5)
	blend.add(enemy.avoid, 1.8)


func enter(_msg: Dictionary = {}) -> void:
	enemy.strafe.side_sign = 1.0 if enemy.rng.randf() < 0.5 else -1.0
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

	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		e.strafe.side_sign *= -1.0
		_strafe_timer = e.rng.randf_range(1.5, 3.0)

	# Stand-off point: on the line between us and the player, at preferred range.
	var player_position := e.player.global_position
	var away := (e.global_position - player_position).normalized()
	e.target_location.position = player_position + away * attack_range * 0.6
	steer_with(blend, delta, player_position)

	if e.is_facing(player_position, 12.0):
		e.fire_at_player()
