class_name UIController
extends Control

## UIController
##
## Base controller for all UI screens and panels.
##
## PDF §4 CPU Optimization:
## Inactive/off-screen UI must not continuously tick.
##
## PDF §6 DRY:
## Subclasses must not implement their own visibility_changed
## connection. They override _on_shown() / _on_hidden() instead.

func _ready() -> void:
	# UI controllers are idle by default.
	# Subclasses may explicitly enable processing when genuinely required.
	set_process(false)
	set_physics_process(false)

	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_on_shown()
	else:
		_on_hidden()


## Override when the UI becomes visible.
##
## If a subclass needs per-frame processing, it should enable it here:
##
## set_process(true)
##
## Do not enable processing unless the UI genuinely needs it.
func _on_shown() -> void:
	pass


## Override when the UI becomes hidden.
##
## Processing must always be disabled again here.
func _on_hidden() -> void:
	set_process(false)
	set_physics_process(false)
