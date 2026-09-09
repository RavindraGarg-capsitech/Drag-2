@tool
class_name EditorSelectionManager
extends Node2D

## Handles object selection, hit testing, and drawing selection visual indicators in world space.

signal selection_changed(selected_object: LevelObject)

var selected_object: LevelObject = null:
	set(val):
		if selected_object != val:
			selected_object = val
			selection_changed.emit(selected_object)
			queue_redraw()

@export var selection_color: Color = Color(0.2, 0.7, 1.0, 0.9)
@export var handle_color: Color = Color(1.0, 0.8, 0.2, 1.0)

func _process(_delta: float) -> void:
	if selected_object != null and is_instance_valid(selected_object):
		queue_redraw()
	elif selected_object != null and not is_instance_valid(selected_object):
		selected_object = null

func select_object(obj: LevelObject) -> void:
	self.selected_object = obj

func deselect() -> void:
	self.selected_object = null

func get_selected_object() -> LevelObject:
	if selected_object != null and is_instance_valid(selected_object):
		return selected_object
	return null

## Performs point hit testing against all LevelObjects in level_root.
func find_object_at_point(world_pos: Vector2, level_root: LevelRoot) -> LevelObject:
	if level_root == null:
		return null
		
	var objects := level_root.get_level_objects()
	# Search in reverse order so top-most child gets selected first
	for i in range(objects.size() - 1, -1, -1):
		var obj := objects[i]
		if not is_instance_valid(obj) or not obj.is_selectable:
			continue
			
		var local_pos := obj.to_local(world_pos)
		var bounds := get_object_local_bounds(obj)
		if bounds.has_point(local_pos):
			return obj
			
	return null

## Computes approximate local bounding rect for hit testing and selection rendering.
func get_object_local_bounds(obj: LevelObject) -> Rect2:
	if obj == null or not is_instance_valid(obj):
		return Rect2(Vector2(-32, -32), Vector2(64, 64))
		
	if obj.has_method("get_selection_bounds"):
		return obj.get_selection_bounds()
		
	return Rect2(Vector2(-40, -40), Vector2(80, 80))

func _draw() -> void:
	if selected_object == null or not is_instance_valid(selected_object):
		return
		
	var local_bounds := get_object_local_bounds(selected_object)
	var xform := selected_object.global_transform
	
	# Transform corners into selection manager's space
	var p1 := to_local(xform * Vector2(local_bounds.position.x, local_bounds.position.y))
	var p2 := to_local(xform * Vector2(local_bounds.end.x, local_bounds.position.y))
	var p3 := to_local(xform * Vector2(local_bounds.end.x, local_bounds.end.y))
	var p4 := to_local(xform * Vector2(local_bounds.position.x, local_bounds.end.y))
	
	# Draw selection box outline
	draw_line(p1, p2, selection_color, 2.5)
	draw_line(p2, p3, selection_color, 2.5)
	draw_line(p3, p4, selection_color, 2.5)
	draw_line(p4, p1, selection_color, 2.5)
	
	# Draw corner handles
	for p in [p1, p2, p3, p4]:
		draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), handle_color)
		draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color.BLACK, false, 1.0)
		
	# Draw center pivot crosshair
	var center := to_local(selected_object.global_position)
	draw_line(center - Vector2(8, 0), center + Vector2(8, 0), selection_color, 1.5)
	draw_line(center - Vector2(0, 8), center + Vector2(0, 8), selection_color, 1.5)
