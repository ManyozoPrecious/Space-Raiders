class_name Steering
extends RefCounted
## Steering behaviours for flying AI (after Craig Reynolds, "Steering Behaviors
## For Autonomous Characters", 1999; structure inspired by the GDQuest steering
## AI framework). Every function returns a desired velocity or an index.
## Behaviours used by the enemies: seek/pursue, wander, path following (waypoints
## come from the FlightNavigation3D plugin) and obstacle avoidance.


static func seek(position: Vector3, target: Vector3, max_speed: float) -> Vector3:
	return (target - position).normalized() * max_speed


static func arrive(position: Vector3, target: Vector3, max_speed: float, slow_radius: float) -> Vector3:
	var to_target := target - position
	var distance := to_target.length()
	if distance < 0.001:
		return Vector3.ZERO
	var speed := max_speed * clampf(distance / slow_radius, 0.0, 1.0)
	return to_target / distance * speed


## Seek the predicted future position of a moving target.
static func pursue(position: Vector3, target_position: Vector3, target_velocity: Vector3, max_speed: float) -> Vector3:
	var time_to_reach := position.distance_to(target_position) / maxf(max_speed, 1.0)
	return seek(position, target_position + target_velocity * time_to_reach, max_speed)


static func flee(position: Vector3, threat: Vector3, max_speed: float) -> Vector3:
	return (position - threat).normalized() * max_speed


## Wander: steer towards a point on a sphere that floats in front of the agent.
static func wander(forward: Vector3, wander_offset: Vector3, max_speed: float, circle_distance := 12.0) -> Vector3:
	return (forward * circle_distance + wander_offset).normalized() * max_speed


## Randomly nudges the wander target and keeps it on the wander sphere.
static func update_wander_offset(offset: Vector3, rng: RandomNumberGenerator, jitter := 0.7, radius := 6.0) -> Vector3:
	offset += Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * jitter
	if offset.length_squared() < 0.0001:
		offset = Vector3.FORWARD
	return offset.normalized() * radius


## Path following: returns the index of the waypoint the agent should seek.
static func path_follow_index(position: Vector3, path: PackedVector3Array, index: int, reach_radius: float) -> int:
	while index < path.size() - 1 and position.distance_to(path[index]) < reach_radius:
		index += 1
	return index


## Obstacle avoidance: casts a fan of rays and returns a push away from
## whatever the rays hit (strength grows as the obstacle gets closer).
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
