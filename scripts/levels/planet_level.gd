class_name PlanetLevel
extends SceneLevel
## Level 2: skimming an alien canyon on a planet surface
## (scene: scenes/planet_level.tscn). The ground, canyon walls, towers, decor,
## outpost, sky, sun and spawn points are all nodes in the scene.


func _init() -> void:
	kills_required = 1
	bounds_radius = 300.0
	fly_height_range = Vector2(25.0, 170.0)
	nav_center = Vector3(0, 220, 0)


func _enemy_layout() -> Array[String]:
	return ["fighter", "fighter", "fighter", "fighter", "fighter", "gunship", "gunship", "gunship"]


func _objective_text() -> String:
	return "LAND AT THE OUTPOST BEACON!"


func _setup_level() -> void:
	 
	($Sun as DirectionalLight3D).shadow_enabled = not OS.has_feature("mobile")
