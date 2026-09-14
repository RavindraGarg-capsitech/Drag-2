extends Control

signal back_pressed


func _on_back_btn_pressed() -> void:
	print("[Settings] BACK PRESSED")

	back_pressed.emit()
