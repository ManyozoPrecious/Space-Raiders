class_name Projectile
extends Area3D
## Laser bolt (scene: scenes/projectile.tscn). Moves along its forward (-Z)
## axis and damages the first body it touches. Shooting concept based on the
## KidsCanCode 3D shooting recipe:
## https://kidscancode.org/godot_recipes/3.x/3d/3d_shooting/index.html

const SCENE_PATH := "res://scenes/projectile.tscn"
const PLAYER_LAYER := 8
const ENEMY_LAYER := 16
const WORLD_BIT := 1
const PLAYER_BIT := 2
const ENEMY_BIT := 4

var speed := 180.0
var damage := 10
var lifetime := 2.5
var from_player := true
var shooter: Node3D

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _light: OmniLight3D = $Light


## Creates a bolt at [param position] flying along [param direction].
static func spawn(parent: Node, position: Vector3, direction: Vector3, owner_is_player: bool, bolt_damage: int, bolt_speed: float, source: Node3D) -> void:
	var bolt: Projectile = load(SCENE_PATH).instantiate()
	bolt.from_player = owner_is_player
	bolt.damage = bolt_damage
	bolt.speed = bolt_speed
	bolt.shooter = source
	parent.add_child(bolt)
	var up := Vector3.UP if absf(direction.dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
	bolt.global_transform = Transform3D(Basis.looking_at(direction, up), position)


func _ready() -> void:
	collision_layer = PLAYER_LAYER if from_player else ENEMY_LAYER
	collision_mask = (WORLD_BIT | ENEMY_BIT) if from_player else (WORLD_BIT | PLAYER_BIT)
	var color := Color(0.3, 0.9, 1.0) if from_player else Color(1.0, 0.25, 0.2)
	# Duplicate so tinting this bolt does not tint every other bolt.
	var material := (_mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	material.albedo_color = color
	_mesh.material_override = material
	_light.light_color = color
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta


func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	var color := Color(0.6, 0.95, 1.0) if from_player else Color(1.0, 0.5, 0.3)
	Vfx.spark(get_tree().current_scene, global_position, color)
	queue_free()
