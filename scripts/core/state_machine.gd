class_name StateMachine
extends Node
## Generic finite state machine. State nodes (children that extend State) are
## placed under this node in the scene; call register_children() then start().
## Pattern based on the GDQuest finite state machine tutorial:
## https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/

signal state_changed(state_name: String)

var current_state: State
var current_name := ""

var _states: Dictionary = {}


## Collects every State child so it can be reached by node name.
func register_children() -> void:
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.finished.connect(_on_state_finished)


func start(state_name: String, msg: Dictionary = {}) -> void:
	transition_to(state_name, msg)


func transition_to(state_name: String, msg: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_warning("StateMachine: no state named '%s'." % state_name)
		return
	if current_state != null:
		current_state.exit()
	current_state = _states[state_name]
	current_name = state_name
	current_state.enter(msg)
	state_changed.emit(state_name)


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func _on_state_finished(next_state_name: String, msg: Dictionary) -> void:
	transition_to(next_state_name, msg)
