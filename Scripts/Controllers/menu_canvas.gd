extends CanvasLayer



@onready var home_panel: Control = $Background/HomePanel
@onready var setting_container: Control = $Background/SettingPanel
@onready var level_select_container: Control = $Background/LevelSelectMenu


const SETTINGS_SCENE: String = "res://Scenes/home/setting_panel.tscn"
const LEVEL_SELECT_SCENE: String = "res://Scenes/home/level_select_menu.tscn"


var settings_instance: Control = null
var level_select_instance: Control = null


func _ready() -> void:
	print("[MenuCanvas] READY")

	# Initial state
	home_panel.show()
	setting_container.hide()
	level_select_container.hide()


# =========================================================
# PLAY BUTTON
# =========================================================

func _on_play_btn_pressed() -> void:
	print("[MenuCanvas] PLAY PRESSED")

	# Home hide
	home_panel.hide()

	# Settings hide
	setting_container.hide()

	# Level Select show
	level_select_container.show()

	# Spawn Level Select only once
	if level_select_instance == null:
		_spawn_level_select()


# =========================================================
# SPAWN LEVEL SELECT
# =========================================================

func _spawn_level_select() -> void:
	var scene: PackedScene = load(LEVEL_SELECT_SCENE)

	if scene == null:
		printerr(
			"[MenuCanvas] Level Select scene not found: ",
			LEVEL_SELECT_SCENE
		)
		return

	level_select_instance = scene.instantiate() as Control

	if level_select_instance == null:
		printerr(
			"[MenuCanvas] Level Select root must extend Control"
		)
		return

	level_select_container.add_child(level_select_instance)

	# Make spawned scene fill its container
	level_select_instance.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Connect Back signal
	if level_select_instance.has_signal("back_pressed"):
		level_select_instance.back_pressed.connect(
			_on_level_select_back
		)

	print("[MenuCanvas] Level Select spawned")


# =========================================================
# SETTINGS BUTTON
# =========================================================

func _on_setting_btn_pressed() -> void:
	print("[MenuCanvas] SETTINGS PRESSED")

	# Home hide
	home_panel.hide()

	# Level Select hide
	level_select_container.hide()

	# Settings show
	setting_container.show()

	# Spawn Settings only once
	if settings_instance == null:
		_spawn_settings()


# =========================================================
# SPAWN SETTINGS
# =========================================================

func _spawn_settings() -> void:
	var scene: PackedScene = load(SETTINGS_SCENE)

	if scene == null:
		printerr(
			"[MenuCanvas] Settings scene not found: ",
			SETTINGS_SCENE
		)
		return

	settings_instance = scene.instantiate() as Control

	if settings_instance == null:
		printerr(
			"[MenuCanvas] Settings root must extend Control"
		)
		return

	setting_container.add_child(settings_instance)

	# Make spawned scene fill its container
	settings_instance.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Connect Back signal
	if settings_instance.has_signal("back_pressed"):
		settings_instance.back_pressed.connect(
			_on_settings_back
		)

	print("[MenuCanvas] Settings spawned")


# =========================================================
# LEVEL SELECT BACK
# =========================================================

func _on_level_select_back() -> void:
	print("[MenuCanvas] LEVEL SELECT BACK")

	level_select_container.hide()
	home_panel.show()


# =========================================================
# SETTINGS BACK
# =========================================================

func _on_settings_back() -> void:
	print("[MenuCanvas] SETTINGS BACK")

	setting_container.hide()
	home_panel.show()
