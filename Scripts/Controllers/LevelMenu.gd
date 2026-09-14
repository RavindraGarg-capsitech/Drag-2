extends Control

## Level Select Menu
## Handles level button creation and level launching.
## PDF §5: GamePlay.tscn is a big scene — it was preloaded by MenuCanvas
## when the menu booted, so go_to() here is a zero-stall instantiate
## instead of a fresh disk load() on every single level tap.
## PDF §6 DRY: paths come from GameConfig instead of locally duplicated
## consts.

signal back_pressed

@onready var level_container: GridContainer = $ScrollContainer/HBoxContainer/GridContainer


func _ready() -> void:
	push_error("LevelMenu", "READY")
	_spawn_level_buttons()


# =========================================================
# BACK BUTTON
# =========================================================

func _on_back_btn_pressed() -> void:
	push_error("LevelMenu", "BACK PRESSED")
	back_pressed.emit()


# =========================================================
# SPAWN LEVEL BUTTONS
# =========================================================

func _spawn_level_buttons() -> void:
	for child: Node in level_container.get_children():
		child.queue_free()

	var directory: DirAccess = DirAccess.open(GameConfig.LEVELS_PATH)

	if directory == null:
		push_error("LevelMenu", "Levels folder not found")
		return

	var button_scene: PackedScene = load(GameConfig.LEVEL_BUTTON_SCENE)

	if button_scene == null:
		push_error("LevelMenu", "Level button scene not found")
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


func _create_level_button(level_number: int, button_scene: PackedScene) -> void:
	var button: TextureButton = button_scene.instantiate() as TextureButton

	if button == null:
		push_error("LevelMenu", "Invalid Level Button")
		return

	button.name = "Level%03d" % level_number

	var label: Label = button.find_child("Level_Label", true, false) as Label

	if label:
		label.text = str(level_number)

	button.pressed.connect(_on_level_button_pressed.bind(level_number))
	level_container.add_child(button)


func _on_level_button_pressed(level_index: int) -> void:
	_open_level(level_index)


# =========================================================
# OPEN LEVEL
# =========================================================

func _open_level(level_index: int) -> void:
	var level_path: String = GameConfig.LEVEL_FILE_FORMAT % str(level_index).pad_zeros(3)

	if not ResourceLoader.exists(level_path):
		push_error("LevelMenu", "Level not found: " + level_path)
		return

	var level_data: Resource = load(level_path)

	if level_data == null or not level_data is LevelData:
		push_error("LevelMenu", "Invalid LevelData: " + level_path)
		return

	GameService.save.set_value(GameConfig.SAVE_KEY_LAST_LEVEL, level_index)
	GameService.save.save()

	# Big scene: instantiate the already-preloaded resource (PDF §5).
	# `configure` runs BEFORE add_child(), so GamePlay's _ready() sees
	# initial_level_data already set — setting it after go_to() returns
	# would be too late, since add_child() fires _ready() immediately.
	var game_instance: Node = GameService.scenes.go_to(
		GameConfig.GAMEPLAY_SCENE,
		null,
		func(instance: Node) -> void: instance.set("initial_level_data", level_data)
	)

	if game_instance == null:
		return

	GameBus.gameplay_started.emit(level_data)

	# Remove MenuCanvas when gameplay starts — freed via the bus-driven
	# owner reference instead of a get_parent().get_parent() reach-around.
	var menu_canvas: Node = get_tree().root.get_node_or_null("MenuCanvas")

	if menu_canvas == null:
		menu_canvas = get_parent().get_parent()  # fallback if not named "MenuCanvas"

	if is_instance_valid(menu_canvas):
		menu_canvas.queue_free()
