class_name EditorInputManager
extends RefCounted

## Ensures all required InputMap actions exist for the editor, allowing it to run in any project without manual project.godot setup.

static func ensure_input_actions() -> void:
	_add_action_if_missing("toggle_editor_panel", [
		_create_key_event(KEY_E)
	])
	_add_action_if_missing("select", [
		_create_mouse_event(MOUSE_BUTTON_LEFT)
	])
	_add_action_if_missing("cancel", [
		_create_key_event(KEY_ESCAPE),
		_create_mouse_event(MOUSE_BUTTON_RIGHT)
	])
	_add_action_if_missing("delete", [
		_create_key_event(KEY_DELETE),
		_create_key_event(KEY_BACKSPACE)
	])
	_add_action_if_missing("duplicate", [
		_create_key_event(KEY_D, false, false, true) # Ctrl + D
	])
	_add_action_if_missing("rotate", [
		_create_key_event(KEY_R)
	])
	_add_action_if_missing("play_test", [
		_create_key_event(KEY_SPACE),
		_create_key_event(KEY_F5)
	])

static func _add_action_if_missing(action_name: String, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for ev in events:
			InputMap.action_add_event(action_name, ev)

static func _create_key_event(keycode: Key, shift: bool = false, alt: bool = false, ctrl: bool = false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.shift_pressed = shift
	ev.alt_pressed = alt
	ev.ctrl_pressed = ctrl
	ev.pressed = true
	return ev

static func _create_mouse_event(button_index: MouseButton) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	ev.pressed = true
	return ev
