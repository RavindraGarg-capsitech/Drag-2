extends CanvasLayer

## MenuCanvas
## PDF §5 Panel & UI Memory Management: Settings and Level Select are small
## panels — instantiated on demand when opened, queue_free()'d when the
## player backs out, never kept resident.
## PDF §2: navigation out of the whole menu (Play -> Gameplay) goes through
## GameBus + GameService.scenes, not a direct get_parent().get_parent()
## reach-around into this node's own tree.

@onready var home_panel: Control = $Background/HomePanel
@onready var setting_container: Control = $Background/SettingPanel
@onready var level_select_container: Control = $Background/LevelSelectMenu

var settings_instance: Control = null
var level_select_instance: Control = null


func _ready() -> void:
	push_error("MenuCanvas", "READY")

	home_panel.show()
	setting_container.hide()
	level_select_container.hide()

	GameService.scenes.preload_scene(GameConfig.GAMEPLAY_SCENE)
	GameBus.home_requested.connect(_on_home_requested)


func _on_play_btn_pressed() -> void:
	push_error("MenuCanvas", "PLAY PRESSED")

	home_panel.hide()
	setting_container.hide()
	_free_settings()

	level_select_container.show()
	_spawn_level_select()


func _spawn_level_select() -> void:
	if level_select_instance != null:
		return

	var scene: PackedScene = load(GameConfig.LEVEL_SELECT_SCENE)

	if scene == null:
		push_error("MenuCanvas", "Level Select scene not found: " + GameConfig.LEVEL_SELECT_SCENE)
		return

	level_select_instance = scene.instantiate() as Control

	if level_select_instance == null:
		push_error("MenuCanvas", "Level Select root must extend Control")
		return

	level_select_container.add_child(level_select_instance)
	level_select_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if level_select_instance.has_signal("back_pressed"):
		level_select_instance.back_pressed.connect(_on_level_select_back)

	push_error("MenuCanvas", "Level Select spawned")


func _free_level_select() -> void:
	if level_select_instance == null:
		return
	level_select_instance.queue_free()
	level_select_instance = null


func _on_setting_btn_pressed() -> void:
	push_error("MenuCanvas", "SETTINGS PRESSED")

	home_panel.hide()
	level_select_container.hide()
	_free_level_select()

	setting_container.show()
	_spawn_settings()


func _spawn_settings() -> void:
	if settings_instance != null:
		return

	var scene: PackedScene = load(GameConfig.SETTINGS_PANEL_SCENE)

	if scene == null:
		push_error("MenuCanvas", "Settings scene not found: " + GameConfig.SETTINGS_PANEL_SCENE)
		return

	settings_instance = scene.instantiate() as Control

	if settings_instance == null:
		push_error("MenuCanvas", "Settings root must extend Control")
		return

	setting_container.add_child(settings_instance)
	settings_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if settings_instance.has_signal("back_pressed"):
		settings_instance.back_pressed.connect(_on_settings_back)

	push_error("MenuCanvas", "Settings spawned")


func _free_settings() -> void:
	if settings_instance == null:
		return
	settings_instance.queue_free()
	settings_instance = null


func _on_level_select_back() -> void:
	push_error("MenuCanvas", "LEVEL SELECT BACK")
	level_select_container.hide()
	_free_level_select()
	home_panel.show()


func _on_settings_back() -> void:
	push_error("MenuCanvas", "SETTINGS BACK")
	setting_container.hide()
	_free_settings()
	home_panel.show()


func _on_home_requested() -> void:
	home_panel.show()
	setting_container.hide()
	level_select_container.hide()
	_free_settings()
	_free_level_select()
