extends Control

signal back_pressed


func _on_back_btn_pressed() -> void:
	print("[Settings] BACK PRESSED")

	back_pressed.emit()


func _on_sound_btn_pressed() -> void:
	pass # Replace with function body.


func _on_music_btn_pressed() -> void:
	pass # Replace with function body.


func _on_privacy_btn_pressed() -> void:
	pass # Replace with function body.
