extends UIController

@onready var level_root: LevelRoot = $LevelRoot
@onready var win_panel: Control = $"GamePlay UI/WinPanel"

var initial_level_data: Resource = null


func _ready() -> void:
	super._ready()
	win_panel.hide()

	GameBus.home_requested.connect(_on_home_requested)
	GameBus.level_restarted.connect(_on_level_restarted)
	GameBus.level_completed.connect(_on_level_completed)

	if initial_level_data != null and initial_level_data is LevelData:
		_load_level(initial_level_data)


func _load_level(level_data: Resource) -> void:
	push_error("Game", "Loading level: " + level_data.level_name)
	LevelLoader.load_level(level_data, level_root)
	for obj in level_root.get_level_objects():
		obj.set_editor_mode(false)


func _on_level_restarted(_level_index: int) -> void:
	win_panel.hide()
	if initial_level_data != null:
		_load_level(initial_level_data)


func _on_level_completed(level_index: int, stars: int) -> void:
	win_panel.setup(level_index, stars)
	win_panel.show()


func _on_home_requested() -> void:
	GameService.scenes.go_to(GameConfig.MENU_CANVAS_SCENE)
	queue_free()
