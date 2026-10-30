extends Node
 

const SHIPS := [
	{
		"name": "Spitfire",
		"description": "Balanced all-rounder.",
		"model": "res://assets/ships/Spitfire/glTF/Spitfire.gltf",
		"texture": "res://assets/ships/Spitfire/Textures/Spitfire_Blue.png",
		"size": 9.0,
		"yaw_offset": 180.0,
		"max_speed": 65.0,
		"acceleration": 28.0,
		"turn_rate": 1.7,
		"max_health": 100,
		"fire_cooldown": 0.16,
	},
	{
		"name": "Striker",
		"description": "Very fast and agile, but fragile.",
		"model": "res://assets/ships/Striker/glTF/Striker.gltf",
		"texture": "res://assets/ships/Striker/Textures/Striker_Blue.png",
		"size": 8.0,
		"yaw_offset": 180.0,
		"max_speed": 90.0,
		"acceleration": 45.0,
		"turn_rate": 2.1,
		"max_health": 70,
		"fire_cooldown": 0.13,
	},
	{
		"name": "Imperial",
		"description": "Heavy cruiser: slow but tough.",
		"model": "res://assets/ships/Imperial/glTF/Imperial.gltf",
		"texture": "res://assets/ships/Imperial/Textures/Imperial_Blue.png",
		"size": 14.0,
		"yaw_offset": 180.0,
		"max_speed": 50.0,
		"acceleration": 16.0,
		"turn_rate": 1.25,
		"max_health": 170,
		"fire_cooldown": 0.22,
	},
]

const LEVELS := [
	{
		"name": "Asteroid Belt",
		"type": "Space",
		"scene": "res://scenes/space_level.tscn",
		"description": "Dogfight through a drifting asteroid field. Destroy 6 raiders, then fly into the beacon.",
	},
	{
		"name": "Canyon World",
		"type": "Planet surface",
		"scene": "res://scenes/planet_level.tscn",
		"description": "Skim an alien canyon. Destroy 8 raiders, then land at the outpost beacon.",
	},
]

var selected_ship := 0
var selected_level := 0


func get_ship_stats(index: int) -> ShipStats:
	var data: Dictionary = SHIPS[index]
	var stats := ShipStats.new()
	stats.display_name = data["name"]
	stats.description = data["description"]
	stats.model_path = data["model"]
	stats.texture_path = data["texture"]
	stats.model_size = data["size"]
	stats.yaw_offset_deg = data["yaw_offset"]
	stats.max_speed = data["max_speed"]
	stats.acceleration = data["acceleration"]
	stats.turn_rate = data["turn_rate"]
	stats.max_health = data["max_health"]
	stats.fire_cooldown = data["fire_cooldown"]
	return stats


func start_selected_level() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVELS[selected_level]["scene"])


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
