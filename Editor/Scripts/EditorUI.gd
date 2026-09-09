class_name EditorUI
extends CanvasLayer

## Controls the Level Editor UI sidebar, palette population, property inspection, and dialogs.

signal spawn_requested(object_id: String)
signal duplicate_requested
signal delete_requested
signal save_requested(level_id: String, level_name: String)
signal load_requested(file_path: String)
signal play_test_requested
signal panel_visibility_changed(is_visible: bool)

@onready var editor_panel: Control = $EditorPanel
@onready var palette_grid: GridContainer = $EditorPanel/MarginContainer/MainVBox/PaletteSection/PaletteGrid
@onready var property_container: VBoxContainer = $EditorPanel/MarginContainer/MainVBox/InspectorSection/PropertyPanel/ScrollContainer/PropertyContainer
@onready var duplicate_button: Button = $EditorPanel/MarginContainer/MainVBox/InspectorSection/ObjectActionBox/DuplicateButton
@onready var delete_button: Button = $EditorPanel/MarginContainer/MainVBox/InspectorSection/ObjectActionBox/DeleteButton
@onready var level_id_input: LineEdit = $EditorPanel/MarginContainer/MainVBox/LevelSection/LevelIdBox/LevelIdInput
@onready var level_name_input: LineEdit = $EditorPanel/MarginContainer/MainVBox/LevelSection/LevelNameBox/LevelNameInput
@onready var save_button: Button = $EditorPanel/MarginContainer/MainVBox/LevelSection/SaveLoadBox/SaveButton
@onready var load_button: Button = $EditorPanel/MarginContainer/MainVBox/LevelSection/SaveLoadBox/LoadButton
@onready var play_test_button: Button = $EditorPanel/MarginContainer/MainVBox/LevelSection/PlayTestButton
@onready var status_label: Label = $EditorPanel/MarginContainer/MainVBox/StatusLabel

var property_manager: EditorPropertyManager
var editor_panel_visible: bool = false
var _panel_tween: Tween
var _toggle_tab_button: Button

# Dialogs
var _load_dialog: ConfirmationDialog
var _load_item_list: ItemList
var _overwrite_dialog: ConfirmationDialog

func _ready() -> void:
	property_manager = EditorPropertyManager.new(property_container)
	_setup_palette()
	_setup_buttons()
	_setup_dialogs()
	_setup_toggle_tab()
	property_manager.inspect_object(null)
	# Hidden by default as required
	set_panel_visible(false, false)

func _get_editor_panel() -> Control:
	if editor_panel != null:
		return editor_panel
	editor_panel = get_node_or_null("EditorPanel") as Control
	return editor_panel

## Toggles the Editor Panel visibility.
func toggle_editor_panel() -> void:
	set_panel_visible(not editor_panel_visible, true)

## Sets the panel visibility with optional smooth slide animation.
func set_panel_visible(vis: bool, animate: bool = true) -> void:
	editor_panel_visible = vis
	var panel := _get_editor_panel()
	if panel == null:
		panel_visibility_changed.emit(editor_panel_visible)
		return
		
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
		
	var panel_width: float = 400.0
	var target_left: float = -panel_width if vis else 0.0
	var target_right: float = 0.0 if vis else panel_width
	
	if not animate or not is_inside_tree():
		panel.visible = vis
		panel.offset_left = target_left
		panel.offset_right = target_right
		_update_toggle_tab_text()
		panel_visibility_changed.emit(editor_panel_visible)
		return
		
	panel.visible = true
	_panel_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(panel, "offset_left", target_left, 0.22)
	_panel_tween.tween_property(panel, "offset_right", target_right, 0.22)
	
	if not vis:
		_panel_tween.chain().tween_callback(func():
			if not editor_panel_visible:
				panel.visible = false
		)
		
	if vis:
		refresh_palette()
		
	_update_toggle_tab_text()
	panel_visibility_changed.emit(editor_panel_visible)

func _setup_toggle_tab() -> void:
	_toggle_tab_button = Button.new()
	_toggle_tab_button.name = "TogglePanelButton"
	_toggle_tab_button.custom_minimum_size = Vector2(130, 36)
	_toggle_tab_button.anchors_preset = Control.PRESET_TOP_RIGHT
	_toggle_tab_button.anchor_left = 1.0
	_toggle_tab_button.anchor_right = 1.0
	_toggle_tab_button.offset_left = -142.0
	_toggle_tab_button.offset_top = 12.0
	_toggle_tab_button.offset_right = -12.0
	_toggle_tab_button.offset_bottom = 48.0
	_toggle_tab_button.tooltip_text = "Toggle Editor Panel (Shortcut: E)"
	_toggle_tab_button.pressed.connect(toggle_editor_panel)
	add_child(_toggle_tab_button)
	_update_toggle_tab_text()

func _update_toggle_tab_text() -> void:
	if _toggle_tab_button != null:
		_toggle_tab_button.text = "🛠️ Panel [E]" if not editor_panel_visible else "❌ Close [E]"

func _get_palette_grid() -> GridContainer:
	if palette_grid != null:
		return palette_grid
	palette_grid = get_node_or_null("EditorPanel/MarginContainer/MainVBox/PaletteSection/PaletteGrid") as GridContainer
	return palette_grid

## Generates palette buttons dynamically from the object registry.
func refresh_palette() -> void:
	_setup_palette()

func _setup_palette() -> void:
	var grid := _get_palette_grid()
	if grid == null:
		return
		
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
		
	var objects := EditorObjectRegistry.get_palette_objects()
	if objects.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No objects registered."
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		grid.add_child(empty_lbl)
		return
		
	var button_scene := preload("res://Editor/UI/ObjectButton.tscn")
	var icon_map := {
		"ball": "🏀",
		"basket": "🎯",
		"spring_rope": "🪢",
		"wall": "🧱",
		"box": "📦"
	}
	
	for def in objects:
		var btn: Button = button_scene.instantiate() as Button
		var id: String = def.get("id", "")
		var d_name: String = def.get("display_name", id.capitalize())
		var icon: String = icon_map.get(id, "➕")
		btn.text = "%s %s" % [icon, d_name]
		btn.tooltip_text = "Click to spawn %s into level" % d_name
		btn.pressed.connect(func(): spawn_requested.emit(id))
		grid.add_child(btn)

func _setup_buttons() -> void:
	duplicate_button.pressed.connect(func(): duplicate_requested.emit())
	delete_button.pressed.connect(func(): delete_requested.emit())
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	play_test_button.pressed.connect(func(): play_test_requested.emit())

func _setup_dialogs() -> void:
	# Load level selection dialog
	_load_dialog = ConfirmationDialog.new()
	_load_dialog.title = "Select Level to Load"
	_load_dialog.ok_button_text = "Load"
	_load_dialog.size = Vector2(400, 300)
	
	var vbox := VBoxContainer.new()
	_load_item_list = ItemList.new()
	_load_item_list.custom_minimum_size = Vector2(380, 220)
	_load_item_list.item_activated.connect(func(_idx): _confirm_load())
	vbox.add_child(_load_item_list)
	_load_dialog.add_child(vbox)
	_load_dialog.confirmed.connect(_confirm_load)
	add_child(_load_dialog)
	
	# Overwrite confirmation dialog
	_overwrite_dialog = ConfirmationDialog.new()
	_overwrite_dialog.title = "Overwrite Level?"
	_overwrite_dialog.dialog_text = "This level file already exists. Do you want to overwrite it?"
	_overwrite_dialog.ok_button_text = "Overwrite"
	_overwrite_dialog.confirmed.connect(_do_save)
	add_child(_overwrite_dialog)

func _on_save_pressed() -> void:
	var id := level_id_input.text.strip_edges()
	if id.is_empty():
		show_status("⚠️ Level ID cannot be empty", Color.SALMON)
		return
		
	if EditorSaveManager.level_file_exists(id):
		_overwrite_dialog.dialog_text = "Level '%s' already exists. Overwrite?" % id
		_overwrite_dialog.popup_centered()
	else:
		_do_save()

func _do_save() -> void:
	var id := level_id_input.text.strip_edges()
	var name_txt := level_name_input.text.strip_edges()
	save_requested.emit(id, name_txt)

func _on_load_pressed() -> void:
	var files := EditorSaveManager.get_available_levels()
	_load_item_list.clear()
	if files.is_empty():
		show_status("No saved levels found in res://Resources/Levels/", Color.SALMON)
		return
		
	for f in files:
		var file_name := f.get_file()
		_load_item_list.add_item(file_name)
		_load_item_list.set_item_metadata(_load_item_list.item_count - 1, f)
		
	_load_item_list.select(0)
	_load_dialog.popup_centered()

func _confirm_load() -> void:
	var selected := _load_item_list.get_selected_items()
	if selected.is_empty():
		return
	var file_path: String = _load_item_list.get_item_metadata(selected[0])
	_load_dialog.hide()
	load_requested.emit(file_path)

func inspect_object(obj: LevelObject) -> void:
	if property_manager != null:
		property_manager.inspect_object(obj)
	var has_selection: bool = (obj != null)
	duplicate_button.disabled = not has_selection
	delete_button.disabled = not has_selection

func refresh_transform_ui() -> void:
	if property_manager != null:
		property_manager.refresh_transform_ui()

func set_level_info(id: String, level_name: String) -> void:
	if level_id_input != null:
		level_id_input.text = id
	if level_name_input != null:
		level_name_input.text = level_name

func show_status(msg: String, color: Color = Color(0.4, 0.8, 1.0)) -> void:
	if status_label != null:
		status_label.text = msg
		status_label.add_theme_color_override("font_color", color)
