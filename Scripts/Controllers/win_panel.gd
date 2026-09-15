extends UIController

var level_index: int = 1
var stars: int = 0


func setup(p_level_index: int, p_stars: int) -> void:
	level_index = p_level_index
	stars = p_stars

	_update_ui()


func _update_ui() -> void:
	# Star UI later.
	pass


func _on_restart_btn_pressed() -> void:
	GameService.haptics.light()

	GameService.ui.pop_instance(self)

	GameBus.level_restarted.emit(level_index)


func _on_next_btn_pressed() -> void:
	GameService.haptics.light()

	GameService.ui.pop_instance(self)

	GameBus.level_requested.emit(level_index + 1)


func _on_home_btn_pressed() -> void:
	GameService.haptics.light()

	GameService.ui.pop_instance(self)

	GameBus.home_requested.emit()


func _on_back_btn_pressed() -> void:
	GameService.haptics.light()

	GameService.ui.pop_instance(self)

	GameBus.home_requested.emit()
