class_name ChaseCamera
extends Camera3D
## Third person chase camera similar to EverSpace 2: sits behind and above the
## ship, lags slightly when turning and widens the field of view with speed.

@export var offset := Vector3(0.0, 3.6, 12.0)
@export var rotation_lag := 5.0
@export var base_fov := 72.0
@export var max_fov_boost := 14.0

var target: PlayerShip

var _camera_basis := Basis.IDENTITY
var _shake := 0.0


func _ready() -> void:
	top_level = true
	fov = base_fov
	far = 3000.0
	current = true


func snap_to_target() -> void:
	if target == null:
		return
	_camera_basis = target.global_transform.basis
	_update_transform(0.0)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


 
func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	var target_basis: Basis = target.global_transform.basis.orthonormalized()
	var current_basis: Basis = _camera_basis.orthonormalized()

	_camera_basis = current_basis.slerp(
		target_basis,
		clampf(rotation_lag * delta, 0.0, 1.0)
	).orthonormalized()

	_update_transform(delta)



func _update_transform(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var scale_factor := 1.0 + target.current_speed / maxf(target.stats.max_speed, 1.0) * 0.15
	var position_offset := _camera_basis * (offset * scale_factor)
	var pitch_down := Basis(Vector3.RIGHT, -0.07)
	global_transform = Transform3D(_camera_basis * pitch_down, target.global_position + position_offset)
	var speed_ratio := target.current_speed / maxf(target.stats.max_speed, 1.0)
	fov = lerpf(fov, base_fov + max_fov_boost * speed_ratio, 3.0 * delta)
	if _shake > 0.01:
		h_offset = randf_range(-_shake, _shake)
		v_offset = randf_range(-_shake, _shake)
		_shake = lerpf(_shake, 0.0, 8.0 * delta)
	else:
		h_offset = 0.0
		v_offset = 0.0
