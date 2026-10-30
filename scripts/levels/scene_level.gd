class_name SceneLevel
extends LevelBase
## A level whose layout is built in the Godot editor. The level scene provides:
##   PlayerStart (Marker3D)  where and which way the player starts
##   GoalPosition (Marker3D) where the goal beacon appears
##   EnemySpawns (Node3D)    Marker3D children = enemy start points, used in order
##   obstacles               any node in the "obstacle" group (Obstacle scenes,
##                           or a StaticBody3D such as the planet ground)

var _spawn_index := 0


func _player_start() -> Transform3D:
	return ($PlayerStart as Node3D).global_transform


func _goal_position() -> Vector3:
	return ($GoalPosition as Node3D).global_position


func _build_environment() -> void:
	for body in get_tree().get_nodes_in_group("obstacle"):
		register_nav_target(body)
		if body is Obstacle:
			_obstacles.append({"position": (body as Obstacle).global_position, "radius": (body as Obstacle).get_radius()})
	_setup_level()


## Hook for level specific extras (star field, shadows, ...).
func _setup_level() -> void:
	pass


func _find_free_spawn_point() -> Vector3:
	var spawns := $EnemySpawns.get_children()
	if _spawn_index < spawns.size():
		var point := (spawns[_spawn_index] as Node3D).global_position
		_spawn_index += 1
		return point
	return super()
