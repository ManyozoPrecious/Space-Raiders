class_name State
extends Node
## Base class for every state of a StateMachine.
## Pattern adapted from the GDQuest finite state machine tutorial:
## https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/

## Emitted when this state wants the machine to switch to another state.
signal finished(next_state_name: String, msg: Dictionary)


func enter(_msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
