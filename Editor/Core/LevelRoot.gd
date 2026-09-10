class_name LevelRoot
extends Node2D

## World container and coordinator for level objects inside the design space.

const DESIGN_WIDTH: float = 1920.0
const DESIGN_HEIGHT: float = 1080.0
const DESIGN_SIZE: Vector2 = Vector2(1920.0, 1080.0)

@export var design_width: float = 1920.0
@export var design_height: float = 1080.0

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)   # ADDED: recalculate object positions whenever the viewport size changes

func _on_viewport_size_changed() -> void:                            # ADDED
	update_responsive_positions()                                     # ADDED

func get_design_size() -> Vector2:
	return Vector2(design_width, design_height)

## Converts a design/base position (from the Resource) into a runtime position
## that preserves the same relative location on the current viewport.
## Does NOT touch Camera2D and does NOT scale the scene.                    # ADDED
## Converts a design/base position (from the Resource) into a runtime position
## that preserves the same relative location on the current viewport.
## Does NOT touch Camera2D and does NOT scale the scene.
func calculate_responsive_position(design_position: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var design_size: Vector2 = get_design_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or design_size.x <= 0.0 or design_size.y <= 0.0:
		return design_position
	var normalized: Vector2 = design_position / design_size
	var offset_from_center: Vector2 = (normalized - Vector2(0.5, 0.5)) * viewport_size
	return viewport_size / 2.0 + offset_from_center   # FIXED: anchor to viewport center, not design center                         # ADDED

## Recalculates and applies responsive positions for every current level object,
## based on each object's stored design_position and the current viewport.   # ADDED
func update_responsive_positions() -> void:
	for obj in get_level_objects():
		obj.global_position = calculate_responsive_position(obj.design_position)   # CHANGED: global_position instead of position
		obj._capture_initial_state()                                       # ADDED: keep reset_to_initial_state() consistent with the latest viewport-adjusted position

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
