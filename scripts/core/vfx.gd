class_name Vfx
extends RefCounted
 


static func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material


static func _make_ramp(start: Color, end: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, start)
	gradient.set_color(1, end)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


static func _make_shrink_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


static func _make_particles(amount: int, lifetime: float, radius: float) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.visibility_aabb = AABB(Vector3(-60, -60, -60), Vector3(120, 120, 120))
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	particles.draw_pass_1 = mesh
	return particles

 
static func explosion(parent: Node, position: Vector3, power := 1.0) -> void:
	var particles := _make_particles(48, 1.0, 0.7)
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.8 * power
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 6.0 * power
	process.initial_velocity_max = 24.0 * power
	process.gravity = Vector3.ZERO
	process.damping_min = 4.0
	process.damping_max = 8.0
	process.scale_min = 1.0 * power
	process.scale_max = 2.4 * power
	process.scale_curve = _make_shrink_curve()
	process.color_ramp = _make_ramp(Color(1.0, 0.85, 0.35, 1.0), Color(0.9, 0.15, 0.05, 0.0))
	particles.process_material = process
	particles.material_override = _make_material(Color.WHITE)
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	parent.add_child(particles)
	particles.global_position = position
	parent.get_tree().create_timer(2.0).timeout.connect(particles.queue_free)


 
static func spark(parent: Node, position: Vector3, color := Color(0.6, 0.9, 1.0)) -> void:
	var particles := _make_particles(12, 0.35, 0.25)
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 8.0
	process.initial_velocity_max = 20.0
	process.gravity = Vector3.ZERO
	process.scale_curve = _make_shrink_curve()
	process.color_ramp = _make_ramp(color, Color(color.r, color.g, color.b, 0.0))
	particles.process_material = process
	particles.material_override = _make_material(Color.WHITE)
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	parent.add_child(particles)
	particles.global_position = position
	parent.get_tree().create_timer(1.0).timeout.connect(particles.queue_free)


 
static func engine_exhaust(color: Color, size := 1.0) -> GPUParticles3D:
	var particles := _make_particles(30, 0.45, 0.35 * size)
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0, 0, 1)
	process.spread = 6.0
	process.initial_velocity_min = 10.0
	process.initial_velocity_max = 16.0
	process.gravity = Vector3.ZERO
	process.scale_curve = _make_shrink_curve()
	process.color_ramp = _make_ramp(color, Color(color.r, color.g, color.b, 0.0))
	particles.process_material = process
	particles.material_override = _make_material(Color.WHITE)
	particles.local_coords = false
	particles.emitting = true
	return particles
