class_name ChaseState
extends EnemyState
## Chasing: the player is close enough to be hunted. With a clear line of sight
## the enemy pursues the player (GSAIPursue); otherwise it follows a navigation
## path to the player (GSAIFollowPath).

const REPATH_INTERVAL := 1.0

var _pursue_blend: GSAIBlend
var _path_blend: GSAIBlend
var _repath_timer := 0.0


func setup() -> void:
	_pursue_blend = GSAIBlend.new(enemy.agent)
	_pursue_blend.add(enemy.pursue, 1.0)
	_pursue_blend.add(enemy.avoid, 1.8)
	_path_blend = GSAIBlend.new(enemy.agent)
	_path_blend.add(enemy.follow_path, 1.0)
	_path_blend.add(enemy.avoid, 1.8)


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

	if sees_player:
		steer_with(_pursue_blend, delta)
	else:
		_repath_timer -= delta
		if _repath_timer <= 0.0:
			_repath_timer = REPATH_INTERVAL
			e.request_path(e.player.global_position)
		steer_with(_path_blend, delta)
