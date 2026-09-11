extends Control

## Level Select Menu

@onready var level_container: GridContainer = $ScrollContainer/HBoxContainer/GridContainer

const LEVELS_PATH: String = "res://Resources/Levels/"
const LEVEL_BUTTON_SCENE: String = "res://Scenes/UI/button/LevelBtn.tscn"


func _ready() -> void:
	_spawn_level_buttons()


func _spawn_level_buttons() -> void:
	for child: Node in level_container.get_children():
		child.queue_free()

	var directory: DirAccess = DirAccess.open(LEVELS_PATH)
	if directory == null:
		printerr("[LevelMenu] Levels folder not found")
		return

	var button_scene: PackedScene = load(LEVEL_BUTTON_SCENE)
	if button_scene == null:
		printerr("[LevelMenu] Level button scene not found")
		return

	var level_files: Array[String] = []

	directory.list_dir_begin()

	var file: String = directory.get_next()

	while file != "":
		if not directory.current_is_dir():
			if file.begins_with("Level") and file.ends_with(".res"):
				level_files.append(file)

		file = directory.get_next()

	directory.list_dir_end()
	level_files.sort()

	for level_file: String in level_files:
		var level_number: int = _get_level_number(level_file)

		if level_number > 0:
			_create_level_button(level_number, button_scene)


func _get_level_number(level_file: String) -> int:
	var number: String = level_file.trim_prefix("Level").trim_suffix(".res")

	return int(number) if number.is_valid_int() else -1


func _create_level_button(
	level_number: int,
	button_scene: PackedScene
) -> void:

	var button: TextureButton = button_scene.instantiate() as TextureButton

	if button == null:
		printerr("[LevelMenu] Invalid Level Button")
		return

	button.name = "Level%03d" % level_number

	var label: Label = button.find_child("Level_Label", true, false) as Label

	if label:
		label.text = str(level_number)

	button.pressed.connect(
		_on_level_button_pressed.bind(level_number)
	)

	level_container.add_child(button)


func _on_level_button_pressed(level_index: int) -> void:
	_open_level(level_index)


func _open_level(level_index: int) -> void:
	var level_path: String = (
		"res://Resources/Levels/Level%s.res"
		% str(level_index).pad_zeros(3)
	)

	if not ResourceLoader.exists(level_path):
		printerr("[LevelMenu] Level not found: ", level_path)
		return

	var level_data: Resource = load(level_path)

	if level_data == null or not level_data is LevelData:
		printerr("[LevelMenu] Invalid LevelData: ", level_path)
		return

	var game_scene: PackedScene = load(
		"res://Scenes/gameplay/GamePlayUi.tscn"
	)

	if game_scene == null:
		printerr("[LevelMenu] GamePlayUi not found")
		return

	var game_instance: Node = game_scene.instantiate()

	game_instance.set("initial_level_data", level_data)
	get_tree().root.add_child(game_instance)

	queue_free()
