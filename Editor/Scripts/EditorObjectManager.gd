class_name EditorObjectManager
extends RefCounted

## Manages spawning, moving, duplicating, and deleting LevelObjects in the Level Editor.

var level_root: LevelRoot
var selection_manager: EditorSelectionManager

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _init(p_level_root: LevelRoot, p_selection_mgr: EditorSelectionManager) -> void:
	level_root = p_level_root
	selection_manager = p_selection_mgr

## Spawns a new object from the registry and selects it.
func spawn_object(object_id: String, world_pos: Vector2 = Vector2(960, 540)) -> LevelObject:
	if level_root == null:
		return null
		
	var obj := EditorObjectRegistry.spawn_object(object_id, level_root, world_pos)
	if obj != null and selection_manager != null:
		selection_manager.select_object(obj)
	return obj

## Begins dragging the selected object.
func start_dragging(world_mouse_pos: Vector2) -> void:
	var obj := selection_manager.get_selected_object() if selection_manager != null else null
	if obj != null:
		_is_dragging = true
		_drag_offset = obj.position - world_mouse_pos

## Updates position while dragging.
func update_dragging(world_mouse_pos: Vector2) -> void:
	if not _is_dragging:
		return
	var obj := selection_manager.get_selected_object() if selection_manager != null else null
	if obj != null:
		obj.position = world_mouse_pos + _drag_offset

## Ends dragging.
func stop_dragging() -> void:
	_is_dragging = false

func is_dragging() -> bool:
	return _is_dragging

## Duplicates the currently selected object.
func duplicate_selected() -> LevelObject:
	var selected := selection_manager.get_selected_object() if selection_manager != null else null
	if selected == null or level_root == null:
		return null
		
	var obj_id := selected.get_object_id()
	var new_pos := selected.position + Vector2(30, 30)
	var new_obj := EditorObjectRegistry.spawn_object(obj_id, level_root, new_pos)
	if new_obj != null:
		new_obj.rotation = selected.rotation
		new_obj.scale = selected.scale
		new_obj.is_locked = selected.is_locked
		new_obj.apply_custom_properties(selected.get_custom_properties())
		selection_manager.select_object(new_obj)
		return new_obj
	return null

## Deletes the currently selected object.
func delete_selected() -> bool:
	var selected := selection_manager.get_selected_object() if selection_manager != null else null
	if selected == null:
		return false
		
	selection_manager.deselect()
	if selected.get_parent() != null:
		selected.get_parent().remove_child(selected)
	selected.queue_free()
	return true
