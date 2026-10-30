class_name Obstacle
extends StaticBody3D
## Static obstacle placed in the level editor (scenes/obstacles/*.tscn).
## Resize it in the editor with the normal Scale tool. When the game starts the
## scale is moved onto the model and the collision shape (so the body itself is
## unscaled), and the obstacle joins the "obstacle" group so the level can
## register it with the flight navigation volume.

var _radius := 0.0

@onready var _visual: Node3D = $Visual
@onready var _collider: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("obstacle")
	var factor := transform.basis.x.length()
	transform.basis = transform.basis.orthonormalized()
	_visual.scale = Vector3.ONE * factor
	# Each obstacle needs its own shape because the scene's shape is shared.
	var shape := _collider.shape.duplicate()
	if shape is SphereShape3D:
		shape.radius *= factor
		_radius = shape.radius
	elif shape is CylinderShape3D:
		shape.radius *= factor
		shape.height *= factor
		_radius = maxf(shape.radius, shape.height * 0.5)
	_collider.shape = shape


## Rough size of the obstacle, used to keep enemy spawns outside of it.
func get_radius() -> float:
	return _radius
