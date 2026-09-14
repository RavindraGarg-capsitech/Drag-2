
class_name UIManager
extends CanvasLayer

## UIManager
##
## PDF §5:
## Small UI panels are instantiated only when required and freed
## after they close.
##
## The UIManager is the common layer for temporary UI above gameplay.
##
## PDF §6:
## The stack provides direct access to the currently managed panels.


var _stack: Array[Control] = []


## Instantiate and display a small UI panel on demand.
##
## The panel scene itself is NOT preloaded or kept resident.
func push_packed(scene_path: String) -> Control:
	if scene_path.is_empty():
		push_error("UIManager: Empty panel scene path.")
		return null

	var packed: PackedScene = load(scene_path) as PackedScene

	if packed == null:
		push_error("UIManager: Panel scene not found: " + scene_path)
		return null

	var instance: Control = packed.instantiate() as Control

	if instance == null:
		push_error(
			"UIManager: Panel root must extend Control: " + scene_path
		)
		return null

	add_child(instance)
	_stack.append(instance)

	return instance


## Free the top-most panel.
func pop() -> void:
	if _stack.is_empty():
		return

	var top: Control = _stack.pop_back()

	if is_instance_valid(top):
		top.queue_free()


## Free a specific panel instance.
##
## Useful when a panel closes itself and another panel may have been
## pushed above it.
func pop_instance(instance: Control) -> void:
	if instance == null:
		return

	var index: int = _stack.find(instance)

	if index != -1:
		_stack.remove_at(index)

	if is_instance_valid(instance):
		instance.queue_free()


## Returns true when at least one temporary panel is open.
func has_open_panels() -> bool:
	return not _stack.is_empty()
