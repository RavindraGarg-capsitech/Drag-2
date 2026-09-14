extends CanvasLayer


func _ready() -> void:


	# GamePlay UI itself does not need to process while paused.
	# Only the dynamically spawned PausePanel needs to work while paused.
	process_mode = Node.PROCESS_MODE_PAUSABLE


# =========================================================
# PAUSE
# =========================================================

func _on_pause_btn_pressed() -> void:
	GameService.haptics.light()

	# Pause the gameplay first.
	get_tree().paused = true

	# Spawn PausePanel only when needed.
	var pause_panel: Control = GameService.ui.push_packed(
		GameConfig.PAUSE_PANEL_SCENE
	)

	if pause_panel == null:
		# If spawning failed, don't leave the game paused.
		get_tree().paused = false

func _on_back_btn_pressed() -> void:
	_resume()

func _on_resume_btn_pressed() -> void:
	_resume()

func _on_restart_btn_pressed() -> void:
	GameService.haptics.light()
	GameBus.level_restarted.emit(_current_level_index())
	get_tree().paused = false
	hide()

func _on_home_btn_pressed() -> void:
	GameService.haptics.light()
	hide()
	get_tree().paused = false
	GameBus.home_requested.emit()

func _resume() -> void:
	GameService.haptics.light()
	hide()
	get_tree().paused = false
	GameBus.game_resumed.emit()

func _current_level_index() -> int:
	return GameService.save.get_value(GameConfig.SAVE_KEY_LAST_LEVEL, 1)
