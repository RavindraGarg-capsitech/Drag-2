extends Control

## Level Select Menu

@onready var level_container: GridContainer = $ScrollContainer/HBoxContainer/GridContainer


func _ready() -> void:
	print("[LevelMenu] READY")

	var level_index: int = 1

	for child in level_container.get_children():

		if child is TextureButton:

			print("[LevelMenu] Connecting Level ", level_index)

			child.pressed.connect(
				_on_level_button_pressed.bind(level_index)
			)

			level_index += 1


func _on_level_button_pressed(level_index: int) -> void:

	print("[LevelMenu] CLICKED LEVEL: ", level_index)

	_open_level(level_index)


func _open_level(level_index: int) -> void:

	# Level 1 = Level001.res
	# Level 2 = Level002.res
	# Level 3 = Level003.res

	var formatted_id: String = str(level_index).pad_zeros(3)

	var level_path: String = "res://Resources/Levels/Level%s.res" % formatted_id

	print("[LevelMenu] Loading: ", level_path)


	# Check if level exists
	if not ResourceLoader.exists(level_path):
		printerr("[LevelMenu] Level file not found: ", level_path)
		return


	# Load LevelData
	var level_res: Resource = ResourceLoader.load(level_path)

	if level_res == null:
		printerr("[LevelMenu] Could not load level: ", level_path)
		return


	# Make sure it is LevelData
	if not level_res is LevelData:
		printerr("[LevelMenu] Resource is not LevelData: ", level_path)
		return


	print("[LevelMenu] LevelData loaded successfully")


	# Load GamePlayUi
	var game_scene: PackedScene = load(
		"res://Scenes/gameplay/GamePlayUi.tscn"
	)

	if game_scene == null:
		printerr("[LevelMenu] Could not load GamePlayUi.tscn")
		return


	print("[LevelMenu] GamePlayUi loaded")


	# Create GamePlayUi
	var game_instance: Node = game_scene.instantiate()


	# Send LevelData to GamePlayUi
	game_instance.set(
		"initial_level_data",
		level_res
	)


	# Add GamePlayUi to scene
	get_tree().root.add_child(game_instance)


	print("[LevelMenu] GamePlayUi added")


	# Remove Level Select Menu
	queue_free()
