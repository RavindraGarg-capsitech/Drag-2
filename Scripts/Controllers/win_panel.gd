extends UIController

var level_index: int = 1
var stars: int = 0

func setup(p_level_index: int, p_stars: int) -> void:
	level_index = p_level_index
	stars = p_stars

func _on_back_btn_pressed() -> void:
	hide()
	GameBus.home_requested.emit()

func _on_home_btn_pressed() -> void:
	hide()
	GameBus.home_requested.emit()

func _on_restart_btn_pressed() -> void:
	GameBus.level_restarted.emit(level_index)
	hide()

func _on_resume_btn_pressed() -> void:
	hide()
	GameBus.game_resumed.emit()

func _on_next_btn_pressed() -> void:
	hide()
	GameBus.level_requested.emit(level_index + 1)
