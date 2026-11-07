class_name Hud
extends CanvasLayer
## In-game user interface (scene: scenes/hud.tscn): health bar, kill counter,
## timer, virtual joystick, fire button, touch hint images, crosshair, enemy and
## goal markers, and the pause / game over / level complete panels.
## All controls are nodes in the scene; this script only updates them.

signal restart_requested

const SCENE_PATH := "res://scenes/hud.tscn"
## Seconds an enemy health bar stays visible after the enemy was last hit.
const BAR_VISIBLE_TIME := 2.0
const MARKER_TEXTURES := {
	"fighter": "res://assets/ui/crosshair/marker_fighter.png",
	"gunship": "res://assets/ui/crosshair/marker_gunship.png",
	"goal": "res://assets/ui/crosshair/marker_goal.png",
}
const MARKER_COLORS := {
	"fighter": Color(1.0, 0.35, 0.3),
	"gunship": Color(1.0, 0.65, 0.15),
	"goal": Color(0.3, 1.0, 0.9),
}

var joystick: GameVirtualJoystick
var fire_button: TouchButton

var _markers: Dictionary = {}
var _last_health := -1
var _message_tween: Tween

@onready var _health_bar: ProgressBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _kills_label: Label = %KillsLabel
@onready var _time_label: Label = %TimeLabel
@onready var _message_label: Label = %MessageLabel
@onready var _warning_label: Label = %WarningLabel
@onready var _loading: Control = %Loading
@onready var _damage_flash: ColorRect = %DamageFlash
@onready var _marker_layer: Control = %Markers
@onready var _game_over_panel: Control = %GameOverPanel
@onready var _complete_panel: Control = %CompletePanel
@onready var _pause_panel: Control = %PausePanel
@onready var _complete_time_label: Label = %CompleteTime
@onready var _complete_kills_label: Label = %CompleteKills
@onready var _steer_hint: Control = $UI/SteerHint
@onready var _fire_hint: Control = $UI/FireHint


static func create() -> Hud:
	return load(SCENE_PATH).instantiate()


func _ready() -> void:
	joystick = %Joystick
	fire_button = %FireButton
	# The touch hints disappear as soon as the player touches the control they describe.
	joystick.touched.connect(_steer_hint.hide)
	fire_button.pressed.connect(_fire_hint.hide)
	%PauseButton.pressed.connect(_show_pause)
	%ContinueButton.pressed.connect(func() -> void: restart_requested.emit())
	%QuitButton.pressed.connect(func() -> void: GameState.go_to_menu())
	%ReplayButton.pressed.connect(func() -> void: restart_requested.emit())
	%MenuButton.pressed.connect(func() -> void: GameState.go_to_menu())
	%ResumeButton.pressed.connect(_resume)
	%RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	%QuitMenuButton.pressed.connect(func() -> void: GameState.go_to_menu())
	for button in find_children("*", "Button", true, false):
		button.pressed.connect(func() -> void: AudioManager.play_sfx("ui_click", -6.0))


# --- Public API -------------------------------------------------------------

func set_health(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "HULL  %d / %d" % [current, maximum]
	var ratio := float(current) / float(maximum)
	var fill := _health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = Color(0.9, 0.2, 0.15).lerp(Color(0.25, 0.9, 0.35), ratio)
	if _last_health >= 0 and current < _last_health:
		_damage_flash.color.a = 0.35
		create_tween().tween_property(_damage_flash, "color:a", 0.0, 0.35)
		var camera := get_viewport().get_camera_3d()
		if camera is ChaseCamera:
			(camera as ChaseCamera).shake(0.5)
	_last_health = current


func set_kills(killed: int, required: int) -> void:
	_kills_label.text = "ENEMIES  %d / %d" % [killed, required]


func set_objective(text: String) -> void:
	_kills_label.text = text


func set_time(seconds: float) -> void:
	_time_label.text = _format_time(seconds)


func show_loading(value: bool) -> void:
	_loading.visible = value


func show_out_of_bounds(value: bool) -> void:
	_warning_label.visible = value


func show_message(text: String, duration := 3.0) -> void:
	_message_label.text = text
	if _message_tween != null:
		_message_tween.kill()
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.8)


## Adds a floating icon that follows [param node] on screen (or sticks to the
## screen edge when the node is off screen). kind: fighter, gunship or goal.
func add_marker(node: Node3D, kind: String) -> void:
	var holder := Control.new()
	holder.size = Vector2(64, 104)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = load(MARKER_TEXTURES[kind])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size = Vector2(64, 64)
	icon.modulate = MARKER_COLORS[kind]
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)
	var label := UiKit.make_label("", 18, MARKER_COLORS[kind])
	label.position = Vector2(-10, 62)
	label.size = Vector2(84, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(label)
	# Enemies get a small health bar that only shows for a moment after a hit.
	var bar: ProgressBar = null
	if node.has_signal("health_changed"):
		bar = UiKit.make_bar(Color(1.0, 0.3, 0.2), Vector2(72, 10))
		bar.position = Vector2(-4, 88)
		bar.size = Vector2(72, 10)
		bar.visible = false
		holder.add_child(bar)
		node.health_changed.connect(_on_enemy_health_changed.bind(node))
	_marker_layer.add_child(holder)
	_markers[node] = {"holder": holder, "label": label, "bar": bar, "bar_time": 0.0}


func _on_enemy_health_changed(current: int, maximum: int, node: Node3D) -> void:
	if not _markers.has(node):
		return
	var data: Dictionary = _markers[node]
	var bar := data["bar"] as ProgressBar
	if bar == null:
		return
	bar.max_value = maximum
	bar.value = current
	data["bar_time"] = BAR_VISIBLE_TIME


func show_game_over() -> void:
	get_tree().paused = true
	_game_over_panel.visible = true


func show_complete(seconds: float, kills: int) -> void:
	get_tree().paused = true
	_complete_time_label.text = "Total time: " + _format_time(seconds)
	_complete_kills_label.text = "Enemies destroyed: %d" % kills
	_complete_panel.visible = true


# --- Internals ----------------------------------------------------------------

func _show_pause() -> void:
	if _game_over_panel.visible or _complete_panel.visible:
		return
	get_tree().paused = true
	_pause_panel.visible = true


func _resume() -> void:
	get_tree().paused = false
	_pause_panel.visible = false


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var center := screen * 0.5
	var margin := 60.0
	for node in _markers.keys():
		var data: Dictionary = _markers[node]
		var holder: Control = data["holder"]
		if not is_instance_valid(node) or (node as Node).is_queued_for_deletion():
			holder.queue_free()
			_markers.erase(node)
			continue
		var world_pos: Vector3 = (node as Node3D).global_position
		var behind := camera.is_position_behind(world_pos)
		var point := camera.unproject_position(world_pos)
		var off_screen := behind or point.x < margin or point.y < margin or point.x > screen.x - margin or point.y > screen.y - margin
		if off_screen:
			var direction := point - center
			if behind:
				direction = -direction
			if direction.length() < 1.0:
				direction = Vector2.DOWN
			var scale_x := (center.x - margin) / maxf(absf(direction.x), 0.001)
			var scale_y := (center.y - margin) / maxf(absf(direction.y), 0.001)
			point = center + direction * minf(scale_x, scale_y)
		var bar_node := data["bar"] as ProgressBar
		if bar_node != null:
			data["bar_time"] = maxf(float(data["bar_time"]) - delta, 0.0)
			bar_node.visible = float(data["bar_time"]) > 0.0 and not off_screen
		holder.position = point - Vector2(32, 32)
		(data["label"] as Label).text = "%d m" % int(camera.global_position.distance_to(world_pos))


func _format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var secs := fmod(seconds, 60.0)
	return "%02d:%04.1f" % [minutes, secs]
