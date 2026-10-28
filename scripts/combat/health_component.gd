class_name HealthComponent
extends Node
## Reusable health attribute for the player and the enemies.

signal health_changed(current: int, maximum: int)
signal died

@export var max_health := 100

var current_health := 100
var is_dead := false


func _ready() -> void:
	reset()


func reset() -> void:
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		is_dead = true
		died.emit()
