
class_name SettingPanel
extends UIController

## Settings Panel
##
## PDF §5:
## Instantiated on demand and freed when closed.
##
## PDF §6:
## Sound/music state belongs to GameService.sound and is persisted
## through GameService.save.
##
## This panel does not own an AudioStreamPlayer or SaveManager.


signal back_pressed


func _on_back_btn_pressed() -> void:
	back_pressed.emit()


func _on_sound_btn_pressed() -> void:
	var new_value: bool = not GameService.sound.sound_enabled

	GameService.sound.set_sound_enabled(new_value)

	GameService.save.set_value(
		GameConfig.SAVE_KEY_SOUND_ENABLED,
		new_value
	)

	GameService.save.save()

	GameBus.sound_toggled.emit(new_value)


func _on_music_btn_pressed() -> void:
	var new_value: bool = not GameService.sound.music_enabled

	GameService.sound.set_music_enabled(new_value)

	GameService.save.set_value(
		GameConfig.SAVE_KEY_MUSIC_ENABLED,
		new_value
	)

	GameService.save.save()

	GameBus.music_toggled.emit(new_value)


func _on_privacy_btn_pressed() -> void:
	GameBus.privacy_requested.emit()

	# Do not hardcode a fake privacy-policy URL here.
	# Backend/application configuration should provide the real URL.
