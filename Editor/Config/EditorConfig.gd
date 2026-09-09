class_name EditorConfig
extends Resource

## Configuration resource defining project-specific settings for the portable Level Editor.

@export var design_width: float = 1920.0
@export var design_height: float = 1080.0
@export var levels_directory: String = "res://Resources/Levels/"
@export var default_level_id: String = "001"
@export var default_level_name: String = "Level 1"
@export var registered_objects: Array[Dictionary] = []

func get_design_size() -> Vector2:
	return Vector2(design_width, design_height)
