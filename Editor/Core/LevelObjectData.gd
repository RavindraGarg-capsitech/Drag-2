class_name LevelObjectData
extends Resource

## Portable data container representing a single level object instance.

@export var unique_id: String = ""
@export var object_id: String = ""
@export var position: Vector2 = Vector2.ZERO
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export var is_locked: bool = false
@export var properties: Dictionary = {}

func _init(p_object_id: String = "", p_pos: Vector2 = Vector2.ZERO, p_rot: float = 0.0, p_scale: Vector2 = Vector2.ONE, p_props: Dictionary = {}) -> void:
	object_id = p_object_id
	position = p_pos
	rotation = p_rot
	scale = p_scale
	properties = p_props
	if unique_id.is_empty():
		unique_id = "%s_%d" % [object_id if not object_id.is_empty() else "obj", Time.get_ticks_msec()]
