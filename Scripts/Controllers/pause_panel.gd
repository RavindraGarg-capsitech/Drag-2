class_name PausePanel
extends UIController


## PausePanel
##
## Created dynamically by UIManager when Pause is pressed.
## The panel remains interactive while the game tree is paused.
## It is freed when the player resumes, restarts, or goes home.


func _ready() -> void:
	# This panel must continue receiving input while the game is paused.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	super._ready()


# ============================================================
# CLOSE / RESUME
# ============================================================

func _on_back_btn_pressed() -> void:
	_resume()


func _on_resume_btn_pressed() -> void:
	_resume()


func _resume() -> void:
	GameService.haptics.light()

	# Resume gameplay.
	get_tree().paused = false

	# Tell other systems that gameplay has resumed.
	GameBus.game_resumed.emit()

	# Remove this dynamically spawned panel.
	GameService.ui.pop_instance(self)


# ============================================================
# RESTART
# ============================================================

func _on_restart_btn_pressed() -> void:
	GameService.haptics.light()

	var level_index: int = GameService.save.get_value(
		GameConfig.SAVE_KEY_LAST_LEVEL,
		1
	)

	# Unpause before restarting.
	get_tree().paused = false

	# Remove pause panel.
	GameService.ui.pop_instance(self)

	# Tell gameplay to reload the current level.
	GameBus.level_restarted.emit(level_index)


# ============================================================
# HOME
# ============================================================

func _on_home_btn_pressed() -> void:
	GameService.haptics.light()

	# Unpause before leaving gameplay.
	get_tree().paused = false

	# Remove pause panel.
	GameService.ui.pop_instance(self)

	# Tell the game to return home.
	GameBus.home_requested.emit()
