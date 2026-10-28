class_name GameVirtualJoystick
extends Control
 

@export var radius := 100.0

var output := Vector2.ZERO

var _touch_index := -1
var _offset := Vector2.ZERO

@onready var _nub: TextureRect = $Nub


func _ready() -> void:
	resized.connect(_center_nub)
	_center_nub()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update(event.position)
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update(event.position)


func _update(local_position: Vector2) -> void:
	_offset = (local_position - size * 0.5).limit_length(radius)
	output = _offset / radius
	_center_nub()


func _release() -> void:
	_touch_index = -1
	_offset = Vector2.ZERO
	output = Vector2.ZERO
	_center_nub()


func _center_nub() -> void:
	_nub.position = size * 0.5 + _offset - _nub.size * 0.5
