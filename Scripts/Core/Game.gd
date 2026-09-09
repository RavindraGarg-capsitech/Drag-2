class_name Game
extends Node2D

## Game root scene controller for "Drag to Goal".
## Coordinates the Camera2D and LevelRoot world (1920 x 1080 landscape design space).

@onready var level_root: LevelRoot = $LevelRoot
@onready var camera: Camera2D = $Camera2D

var initial_level_data: Resource = null

func _ready() -> void:
	# Center the camera on the logical 1920x1080 design space center (960, 540)
	if camera != null:
		camera.position = LevelRoot.DESIGN_SIZE / 2.0
		_adapt_camera_to_viewport()
		get_viewport().size_changed.connect(_adapt_camera_to_viewport)
		
	if initial_level_data != null and initial_level_data is LevelData:
		print("[Game] Loading level: ", initial_level_data.level_name)
		LevelLoader.load_level(initial_level_data, level_root)
		# Unfreeze physics bodies for gameplay
		for obj in level_root.get_level_objects():
			obj.set_editor_mode(false)


func _adapt_camera_to_viewport() -> void:
	if camera == null:
		return
	camera.position = LevelRoot.DESIGN_SIZE / 2.0

func _on_home_button_pressed() -> void:
	var menu_scene = load("res://Scenes/Menu/LevelMenu.tscn")
	if menu_scene != null:
		get_tree().change_scene_to_packed(menu_scene)
	else:
		printerr("[Game] Could not load LevelMenu.tscn")
