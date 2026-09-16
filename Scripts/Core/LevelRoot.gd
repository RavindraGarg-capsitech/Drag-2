class_name LevelRoot
extends Node2D

## World container and coordinator for level objects.
## Level objects keep their exact positions from LevelData.
## Only the complete LevelRoot is scaled and centered
## to fit the current viewport.

@export var design_width: float = 1920.0
@export var design_height: float = 1080.0


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_fit_level_to_viewport()


func get_design_size() -> Vector2:
	return Vector2(design_width, design_height)


## Fits the complete authored level inside the viewport.
## Objects themselves are NOT repositioned.
## Camera2D is NOT used.
func _fit_level_to_viewport() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var viewport_size: Vector2 = vp.get_visible_rect().size
	var design_size: Vector2 = get_design_size()

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	if design_size.x <= 0.0 or design_size.y <= 0.0:
		return

	# ------------------------------------------------------------
	# Calculate one uniform scale.
	# This keeps the original aspect ratio.
	# ------------------------------------------------------------

	var scale_x: float = viewport_size.x / design_size.x
	var scale_y: float = viewport_size.y / design_size.y

	var fit_scale: float = min(scale_x, scale_y)

	scale = Vector2.ONE * fit_scale


	# ------------------------------------------------------------
	# Center the complete LevelRoot.
	# ------------------------------------------------------------

	var scaled_size: Vector2 = design_size * fit_scale

	position = (viewport_size - scaled_size) / 2.0


	print(
		"[LevelRoot] Viewport: ",
		viewport_size,
		" | Design: ",
		design_size,
		" | Scale: ",
		fit_scale,
		" | Position: ",
		position
	)


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
 
