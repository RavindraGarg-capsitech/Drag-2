class_name LevelRoot
extends Node2D

## World container and coordinator for level objects inside the design space.

const DESIGN_WIDTH: float = 1920.0
const DESIGN_HEIGHT: float = 1080.0
const DESIGN_SIZE: Vector2 = Vector2(1920.0, 1080.0)

@export var design_width: float = 1920.0
@export var design_height: float = 1080.0

func _ready() -> void:
	pass

func get_design_size() -> Vector2:
	return Vector2(design_width, design_height)

## Returns all child nodes that implement LevelObject.
func get_level_objects() -> Array[LevelObject]:
	var result: Array[LevelObject] = []
	for child in get_children():
		if child is LevelObject:
			result.append(child as LevelObject)
	return result

## Resets all level objects back to their initial state.
func reset_level() -> void:
	for obj in get_level_objects():
		obj.reset_to_initial_state()

## Removes all level objects from the world immediately.
func clear_level_objects() -> void:
	for obj in get_level_objects():
		remove_child(obj)
		obj.queue_free()
