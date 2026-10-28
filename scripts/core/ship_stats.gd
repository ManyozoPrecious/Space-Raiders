class_name ShipStats
extends Resource
## Data describing one selectable player ship.
## max_speed and acceleration are shown on the ship selection screen.

@export var display_name := "Ship"
@export var description := ""
@export var model_path := ""
@export var texture_path := ""
@export var model_size := 9.0
@export var yaw_offset_deg := 180.0
@export var max_speed := 60.0
@export var acceleration := 25.0
@export var turn_rate := 1.6
@export var max_health := 100
@export var fire_cooldown := 0.16
