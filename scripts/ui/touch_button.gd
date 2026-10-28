class_name TouchButton
extends Control
## Round on-screen button that tracks its own finger, so it works at the same
## time as the virtual joystick. `is_down` is true while it is held. The
## Background and Icon images are child nodes in the scene.

signal pressed
signal released

var is_down := false

var _touch_index := -1

@onready var _background: TextureRect = $Background


func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size * 0.5)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_set_down(true)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_set_down(false)


func _set_down(value: bool) -> void:
	is_down = value
	_background.modulate.a = 1.0 if value else 0.7
	scale = Vector2.ONE * (0.94 if value else 1.0)
	if value:
		pressed.emit()
	else:
		released.emit()
