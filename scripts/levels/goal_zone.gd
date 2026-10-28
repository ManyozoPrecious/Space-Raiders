class_name GoalZone
extends Area3D
## Beacon the player must fly into after destroying the required enemies
## (scene: scenes/goal_zone.tscn). It is dim and inactive until set_active(true).

signal reached

const SCENE_PATH := "res://scenes/goal_zone.tscn"

var is_active := false

@onready var _ring: MeshInstance3D = $Ring
@onready var _beam: MeshInstance3D = $Beam
@onready var _ring_material := _ring.material_override as StandardMaterial3D
@onready var _beam_material := _beam.material_override as StandardMaterial3D


static func create() -> GoalZone:
	return load(SCENE_PATH).instantiate()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func set_active(value: bool) -> void:
	is_active = value
	var color := Color(0.2, 1.0, 0.9, 0.9) if value else Color(0.4, 0.4, 0.45, 0.35)
	_ring_material.albedo_color = color
	_beam_material.albedo_color = Color(color.r, color.g, color.b, 0.25 if value else 0.12)
	if value:
		var tween := create_tween().set_loops()
		tween.tween_property(_ring, "scale", Vector3.ONE * 1.08, 0.7)
		tween.tween_property(_ring, "scale", Vector3.ONE, 0.7)


func _on_body_entered(body: Node3D) -> void:
	if is_active and body.is_in_group("player"):
		is_active = false
		reached.emit()
