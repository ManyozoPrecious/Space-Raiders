extends Control
## Main menu with sub menus (scene: scenes/main_menu.tscn): play, select a space
## ship (rotating 3D preview with speed / acceleration stats) and select a level.
## All panels and buttons are nodes in the scene; this script wires them up.

@onready var _main_panel: Control = %MainPanel
@onready var _ship_panel: Control = %ShipPanel
@onready var _level_panel: Control = %LevelPanel
@onready var _summary_label: Label = %SummaryLabel
@onready var _preview_pivot: Node3D = %PreviewPivot
@onready var _ship_name_label: Label = %ShipName
@onready var _ship_desc_label: Label = %ShipDesc
@onready var _level_buttons: Array = [%Level1Button, %Level2Button]
@onready var _level_descriptions: Array = [%Level1Desc, %Level2Desc]
@onready var _stat_bars := {
	"speed": %SpeedBar, "accel": %AccelBar, "handling": %HandlingBar, "hull": %HullBar,
}
@onready var _stat_values := {
	"speed": %SpeedValue, "accel": %AccelValue, "handling": %HandlingValue, "hull": %HullValue,
}


func _ready() -> void:
	_build_stars()
	%PlayButton.pressed.connect(_on_play_pressed)
	%ShipButton.pressed.connect(func() -> void: _show_panel(_ship_panel))
	%LevelButton.pressed.connect(func() -> void: _show_panel(_level_panel))
	%QuitButton.pressed.connect(func() -> void: get_tree().quit())
	%PrevButton.pressed.connect(func() -> void: _change_ship(-1))
	%NextButton.pressed.connect(func() -> void: _change_ship(1))
	%SelectButton.pressed.connect(_on_back_to_main)
	%BackButton.pressed.connect(_on_back_to_main)
	for i in _level_buttons.size():
		_level_buttons[i].pressed.connect(func() -> void: _select_level(i))
		_level_descriptions[i].text = GameState.LEVELS[i]["description"]
	for button in find_children("*", "Button", true, false):
		button.pressed.connect(func() -> void: AudioManager.play_sfx("ui_click", -6.0))
	_show_panel(_main_panel)
	_refresh_ship()
	_refresh_levels()
	AudioManager.play_music("menu")


func _process(delta: float) -> void:
	_preview_pivot.rotate_y(delta * 0.9)


## Decorative star field behind the menu.
func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 140:
		var star := ColorRect.new()
		var size := rng.randf_range(1.5, 4.0)
		star.size = Vector2(size, size)
		star.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720))
		star.color = Color(1, 1, 1, rng.randf_range(0.3, 1.0))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		%Stars.add_child(star)


func _show_panel(panel: Control) -> void:
	for p in [_main_panel, _ship_panel, _level_panel]:
		p.visible = (p == panel)


func _on_play_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	GameState.start_selected_level()


func _on_back_to_main() -> void:
	_refresh_summary()
	_show_panel(_main_panel)


func _change_ship(step: int) -> void:
	var count := GameState.SHIPS.size()
	GameState.selected_ship = (GameState.selected_ship + step + count) % count
	_refresh_ship()


func _select_level(index: int) -> void:
	GameState.selected_level = index
	_refresh_levels()


func _refresh_levels() -> void:
	for i in _level_buttons.size():
		var data: Dictionary = GameState.LEVELS[i]
		var marker := "[X] " if i == GameState.selected_level else "[  ] "
		_level_buttons[i].text = "%s%s (%s)" % [marker, data["name"], data["type"]]
	_refresh_summary()


func _refresh_summary() -> void:
	var ship: Dictionary = GameState.SHIPS[GameState.selected_ship]
	var level: Dictionary = GameState.LEVELS[GameState.selected_level]
	_summary_label.text = "Ship: %s   |   Level: %s" % [ship["name"], level["name"]]


func _refresh_ship() -> void:
	var stats := GameState.get_ship_stats(GameState.selected_ship)
	_ship_name_label.text = stats.display_name
	_ship_desc_label.text = stats.description
	_set_stat("speed", stats.max_speed, "%d m/s" % int(stats.max_speed))
	_set_stat("accel", stats.acceleration * 2.0, "%d m/s2" % int(stats.acceleration))
	_set_stat("handling", stats.turn_rate * 45.0, "%.1f" % stats.turn_rate)
	_set_stat("hull", stats.max_health / 2.0, "%d HP" % stats.max_health)
	for child in _preview_pivot.get_children():
		child.queue_free()
	_preview_pivot.add_child(ModelUtil.instantiate_fitted(load(stats.model_path), 10.0, stats.texture_path, stats.yaw_offset_deg))
	_refresh_summary()


func _set_stat(stat: String, bar_value: float, text: String) -> void:
	(_stat_bars[stat] as ProgressBar).value = bar_value
	(_stat_values[stat] as Label).text = text
