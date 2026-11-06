class_name Steering
extends RefCounted
## Physics helpers used by the enemy steering behaviours.
## The movement behaviours themselves (seek, arrive, pursue, flee, path following,
## blending) come from the GDQuest Godot Steering AI Framework in
## addons/com.gdquest.godot-steering-ai-framework (MIT licence):
## https://github.com/GDQuest/godot-steering-ai-framework
## Raycast "whisker" obstacle avoidance follows the idea from Craig Reynolds,
## "Steering Behaviors For Autonomous Characters" (1999).


## Casts a fan of rays and returns a push away from whatever they hit; the push
## grows stronger as the obstacle gets closer.
static func avoid_obstacles(body: Node3D, forward: Vector3, look_ahead: float, mask := 1) -> Vector3:
	var space := body.get_world_3d().direct_space_state
	var origin := body.global_position
	var basis := body.global_transform.basis
	var directions: Array[Vector3] = [
		forward,
		(forward + basis.x * 0.5).normalized(),
		(forward - basis.x * 0.5).normalized(),
		(forward + basis.y * 0.5).normalized(),
		(forward - basis.y * 0.5).normalized(),
	]
	var push := Vector3.ZERO
	for direction in directions:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * look_ahead, mask)
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			var strength := 1.0 - origin.distance_to(hit["position"]) / look_ahead
			push += (hit["normal"] as Vector3) * strength
	return push


static func has_line_of_sight(body: Node3D, target: Vector3, mask := 1) -> bool:
	var space := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(body.global_position, target, mask)
	return space.intersect_ray(query).is_empty()
