class_name LevelData
extends Resource

## Portable data container representing a complete playable level.
## Saved as a single .res resource file.

@export var level_id: String = "001"
@export var level_name: String = "Level 1"
@export var design_width: float = 1920.0
@export var design_height: float = 1080.0
@export var objects: Array[LevelObjectData] = []
@export var metadata: Dictionary = {}

func get_object_count() -> int:
	return objects.size()
