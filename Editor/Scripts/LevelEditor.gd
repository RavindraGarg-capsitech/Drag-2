class_name LevelEditor
extends Node2D

## Main controller coordinating LevelRoot, Selection, Object Management, and EditorUI.

@export var config: EditorConfig

@onready var camera: Camera2D = $Camera2D
@onready var level_root: LevelRoot = $LevelRoot
@onready var selection_manager: EditorSelectionManager = $EditorSelectionManager
@onready var editor_ui: EditorUI = $EditorUI

var object_manager: EditorObjectManager
var _is_play_testing: bool = false
var _saved_test_data: LevelData = null
var undo_redo: UndoRedo


func _ready() -> void:
	# 1. Auto-register required InputMap actions if missing
	EditorInputManager.ensure_input_actions()
	
	# 2. Load configuration if available
	if config == null and ResourceLoader.exists("res://Editor/Config/DefaultEditorConfig.tres"):
		config = ResourceLoader.load("res://Editor/Config/DefaultEditorConfig.tres") as EditorConfig
		
	if config != null:
		level_root.design_width = config.design_width
		level_root.design_height = config.design_height
		EditorSaveManager.default_levels_dir = config.levels_directory
		EditorObjectRegistry.load_from_config(config)
		
	# 3. Auto-populate from host project ObjectRegistry if available
	_check_host_object_registry()
	editor_ui.refresh_palette()
	
	# 4. Center camera in design space
	var design_sz := level_root.get_design_size()
	if camera != null:
		camera.position = design_sz / 2.0
		
	undo_redo = UndoRedo.new()
	editor_ui.property_manager.undo_redo = undo_redo
	object_manager = EditorObjectManager.new(level_root, selection_manager)

	
	# 5. Connect UI signals
	editor_ui.spawn_requested.connect(_on_spawn_requested)
	editor_ui.duplicate_requested.connect(_on_duplicate_requested)
	editor_ui.delete_requested.connect(_on_delete_requested)
	editor_ui.save_requested.connect(_on_save_requested)
	editor_ui.load_requested.connect(_on_load_requested)
	editor_ui.play_test_requested.connect(_on_play_test_requested)
	
	# 6. Connect Selection signals
	selection_manager.selection_changed.connect(_on_selection_changed)
	
	# 7. Ensure initial objects are in editor mode
	for obj in level_root.get_level_objects():
		obj.set_editor_mode(true)
		
	editor_ui.show_status("Ready. Press 'E' to open Object Palette.")

func _check_host_object_registry() -> void:
	if EditorObjectRegistry.get_palette_objects().is_empty():
		# Check if host project ObjectRegistry exists
		if ClassDB.class_exists("ObjectRegistry") or ResourceLoader.exists("res://Scripts/Core/ObjectRegistry.gd"):
			var reg_script = load("res://Scripts/Core/ObjectRegistry.gd")
			if reg_script != null and reg_script.has_method("get_all_registered_objects"):
				var host_objs = reg_script.get_all_registered_objects()
				for def in host_objs:
					EditorObjectRegistry.register_object(
						def.get("id", ""),
						def.get("scene_path", ""),
						def.get("display_name", ""),
						def.get("category", "General")
					)

func _unhandled_input(event: InputEvent) -> void:
	if _is_play_testing:
		if event.is_action_pressed("cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_stop_play_test()
		return
		
	# Keyboard shortcuts
	if event.is_action_pressed("toggle_editor_panel") or (event is InputEventKey and event.pressed and event.keycode == KEY_E and not event.echo):
		editor_ui.toggle_editor_panel()
		_consume_input()
	elif event.is_action_pressed("delete"):
		_on_delete_requested()
		_consume_input()
	elif event.is_action_pressed("duplicate"):
		_on_duplicate_requested()
		_consume_input()
	elif event.is_action_pressed("rotate"):
		_rotate_selected(15.0)
		_consume_input()
	elif event.is_action_pressed("cancel"):
		selection_manager.deselect()
		_consume_input()
	elif event.is_action_pressed("play_test"):
		_on_play_test_requested()
		_consume_input()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Z and event.ctrl_pressed and not event.shift_pressed:
		if undo_redo.has_undo():
			undo_redo.undo()
			editor_ui.refresh_transform_ui()
			var sel = selection_manager.get_selected_object()
			if sel != null:
				editor_ui.inspect_object(sel)
		_consume_input()
	elif (event is InputEventKey and event.pressed and event.keycode == KEY_Z and event.ctrl_pressed and event.shift_pressed) or (event is InputEventKey and event.pressed and event.keycode == KEY_Y and event.ctrl_pressed):
		if undo_redo.has_redo():
			undo_redo.redo()
			editor_ui.refresh_transform_ui()
			var sel = selection_manager.get_selected_object()
			if sel != null:
				editor_ui.inspect_object(sel)
		_consume_input()
		
	# Mouse canvas interactions
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var world_pos := get_global_mouse_position()
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				var hit_obj := selection_manager.find_object_at_point(world_pos, level_root)
				if hit_obj != null:
					selection_manager.select_object(hit_obj)
					object_manager.start_dragging(world_pos)
				else:
					selection_manager.deselect()
			else:
				object_manager.stop_dragging()
				
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			selection_manager.deselect()

	elif event is InputEventMouseMotion:
		if object_manager.is_dragging():
			var world_pos := get_global_mouse_position()
			object_manager.update_dragging(world_pos)
			editor_ui.refresh_transform_ui()

func _consume_input() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()

func _on_spawn_requested(object_id: String) -> void:
	if _is_play_testing:
		return
	var spawn_pos := level_root.get_design_size() / 2.0
	var obj := object_manager.spawn_object(object_id, spawn_pos)
	if obj != null:
		editor_ui.show_status("Spawned %s at (%d, %d)" % [obj.display_name, spawn_pos.x, spawn_pos.y])

func _on_selection_changed(obj: LevelObject) -> void:
	editor_ui.inspect_object(obj)

func _on_duplicate_requested() -> void:
	if _is_play_testing:
		return
	var dup := object_manager.duplicate_selected()
	if dup != null:
		editor_ui.show_status("Duplicated %s" % dup.display_name)

func _on_delete_requested() -> void:
	if _is_play_testing:
		return
	var sel := selection_manager.get_selected_object()
	if sel != null:
		var name_str := sel.display_name
		object_manager.delete_selected()
		editor_ui.show_status("Deleted %s" % name_str)

func _rotate_selected(degrees: float) -> void:
	var sel := selection_manager.get_selected_object()
	if sel != null:
		sel.rotation += deg_to_rad(degrees)
		editor_ui.refresh_transform_ui()

func _on_save_requested(level_id: String, level_name: String) -> void:
	var result := EditorSaveManager.save_level(level_root, level_id, level_name)
	if result["success"]:
		editor_ui.show_status("✅ Saved %s (%d objects)" % [result["path"].get_file(), result["object_count"]], Color.LIGHT_GREEN)
	else:
		editor_ui.show_status("❌ Save error: %s" % result["error"], Color.SALMON)

func _on_load_requested(file_path: String) -> void:
	selection_manager.deselect()
	var data := EditorSaveManager.load_level(file_path, level_root)
	if data != null:
		editor_ui.set_level_info(data.level_id, data.level_name)
		editor_ui.show_status("📂 Loaded %s (%d objects)" % [file_path.get_file(), data.objects.size()], Color.LIGHT_GREEN)
	else:
		editor_ui.show_status("❌ Failed to load level from %s" % file_path, Color.SALMON)

func _on_play_test_requested() -> void:
	if _is_play_testing:
		_stop_play_test()
	else:
		_start_play_test()

func _start_play_test() -> void:
	_is_play_testing = true
	selection_manager.deselect()
	
	# Capture in-memory state
	var design_sz := level_root.get_design_size()
	_saved_test_data = LevelData.new()
	_saved_test_data.design_width = design_sz.x
	_saved_test_data.design_height = design_sz.y
	for obj in level_root.get_level_objects():
		var d := LevelObjectData.new(obj.get_object_id(), obj.position, obj.rotation, obj.scale, obj.get_custom_properties())
		_saved_test_data.objects.append(d)
		
	# Unfreeze physics bodies
	for obj in level_root.get_level_objects():
		obj.set_editor_mode(false)
		
	editor_ui.show_status("▶️ PLAY TESTING... (Press ESC or Space to Stop)", Color.GOLD)

func _stop_play_test() -> void:
	_is_play_testing = false
	if _saved_test_data != null:
		LevelLoader.load_level(_saved_test_data, level_root)
		for obj in level_root.get_level_objects():
			obj.set_editor_mode(true)
	editor_ui.show_status("⏹️ Play test stopped. Returned to edit mode.")
