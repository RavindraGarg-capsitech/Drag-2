extends CanvasLayer

## Gameplay UI
##
## Handles persistent gameplay UI controls.
## Temporary panels such as PausePanel and WinPanel are
## created and destroyed by UIManager.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


# ============================================================
# PAUSE
# ============================================================

func _on_pause_btn_pressed() -> void:
	GameService.haptics.light()

	# Pause gameplay.
	get_tree().paused = true

	# Spawn PausePanel dynamically.
	var pause_panel: Control = GameService.ui.push_packed(
		GameConfig.PAUSE_PANEL_SCENE
	)

	if pause_panel == null:
		# Prevent the game from remaining paused if spawning failed.
		get_tree().paused = false


# ============================================================
# HINT
# ============================================================

func _on_hint_btn_pressed() -> void:
	GameService.haptics.light()
	GameBus.hint_requested.emit()
