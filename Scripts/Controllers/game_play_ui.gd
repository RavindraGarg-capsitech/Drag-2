extends Control


## Game root scene controller for "Drag to Goal".
## Coordinates the Camera2D and LevelRoot world (1920 x 1080 landscape design space).

@onready var level_root: LevelRoot = $LevelRoot

var initial_level_data: Resource = null

func _ready() -> void:
	if initial_level_data != null and initial_level_data is LevelData:
		print("[Game] Loading level: ", initial_level_data.level_name)
		LevelLoader.load_level(initial_level_data, level_root)
		for obj in level_root.get_level_objects():
			obj.set_editor_mode(false)


						  # ADDED
