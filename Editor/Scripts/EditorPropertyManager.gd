class_name EditorPropertyManager
extends RefCounted

## Dynamically generates and updates inspector UI controls for the selected LevelObject.

var property_container: VBoxContainer
var _current_object: LevelObject = null
var _is_updating_ui: bool = false

# Standard transform controls
var _pos_x_spin: SpinBox
var _pos_y_spin: SpinBox
var _rot_spin: SpinBox
var _scale_x_spin: SpinBox
var _scale_y_spin: SpinBox

# Custom property control cache: prop_name -> Control / Array[Control]
var _custom_controls: Dictionary = {}

var undo_redo: UndoRedo = null

func _init(p_container: VBoxContainer) -> void:
	property_container = p_container

## Populates the inspector container for the newly selected object.
func inspect_object(obj: LevelObject) -> void:
	_current_object = obj
	_custom_controls.clear()
	
	if property_container == null:
		return
		
	# Clear previous controls
	for child in property_container.get_children():
		child.queue_free()
		
	if _current_object == null or not is_instance_valid(_current_object):
		var empty_lbl := Label.new()
		empty_lbl.text = "No object selected.\nClick an object to inspect."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		property_container.add_child(empty_lbl)
		return
		
	_is_updating_ui = true
	_build_header_ui()
	_build_transform_ui()
	_build_custom_properties_ui()
	_is_updating_ui = false

## Builds header with object display name and ID badge.
func _build_header_ui() -> void:
	var header := HBoxContainer.new()
	
	var name_lbl := Label.new()
	name_lbl.text = _current_object.display_name if not _current_object.display_name.is_empty() else _current_object.name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)
	
	var id_badge := Label.new()
	id_badge.text = "[%s]" % _current_object.get_object_id()
	id_badge.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	header.add_child(id_badge)
	
	property_container.add_child(header)
	property_container.add_child(HSeparator.new())

## Builds Transform (Position, Rotation, Scale) UI fields.
func _build_transform_ui() -> void:
	var section_lbl := Label.new()
	section_lbl.text = "TRANSFORM"
	section_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	property_container.add_child(section_lbl)
	
	# Position X / Y
	var pos_grid := GridContainer.new()
	pos_grid.columns = 2
	pos_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lbl_x := Label.new()
	lbl_x.text = "X:"
	pos_grid.add_child(lbl_x)
	_pos_x_spin = _create_spin_box(-10000, 10000, 1.0, _current_object.position.x)
	_pos_x_spin.value_changed.connect(func(v): _on_transform_changed())
	pos_grid.add_child(_pos_x_spin)
	
	var lbl_y := Label.new()
	lbl_y.text = "Y:"
	pos_grid.add_child(lbl_y)
	_pos_y_spin = _create_spin_box(-10000, 10000, 1.0, _current_object.position.y)
	_pos_y_spin.value_changed.connect(func(v): _on_transform_changed())
	pos_grid.add_child(_pos_y_spin)
	property_container.add_child(pos_grid)
	
	# Rotation (Degrees)
	var rot_box := HBoxContainer.new()
	var rot_lbl := Label.new()
	rot_lbl.text = "Rotation (°):"
	rot_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rot_box.add_child(rot_lbl)
	_rot_spin = _create_spin_box(-360, 360, 1.0, rad_to_deg(_current_object.rotation))
	_rot_spin.value_changed.connect(func(v): _on_transform_changed())
	rot_box.add_child(_rot_spin)
	property_container.add_child(rot_box)
	
	# Scale X / Y
	var scale_box := HBoxContainer.new()
	var scale_lbl := Label.new()
	scale_lbl.text = "Scale (X, Y):"
	scale_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_box.add_child(scale_lbl)
	_scale_x_spin = _create_spin_box(0.1, 50.0, 0.1, _current_object.scale.x)
	_scale_x_spin.value_changed.connect(func(v): _on_transform_changed())
	scale_box.add_child(_scale_x_spin)
	_scale_y_spin = _create_spin_box(0.1, 50.0, 0.1, _current_object.scale.y)
	_scale_y_spin.value_changed.connect(func(v): _on_transform_changed())
	scale_box.add_child(_scale_y_spin)
	property_container.add_child(scale_box)
	
	property_container.add_child(HSeparator.new())

## Dynamically generates controls for all custom properties of the object.
func _build_custom_properties_ui() -> void:
	var section_lbl := Label.new()
	section_lbl.text = "PROPERTIES"
	section_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	var added_any = false
	
	for prop in _current_object.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var prop_name: String = prop.name
			# Skip base object properties that are handled elsewhere, or internal/private properties
			if prop_name in ["object_id", "display_name", "is_selectable", "is_locked"] or prop_name.begins_with("_"):
				continue
				
			var val = _current_object.get(prop_name)
			var label_text: String = prop_name.replace("_", " ").capitalize()
			
			if not added_any:
				property_container.add_child(section_lbl)
				added_any = true
			
			if typeof(val) == TYPE_BOOL:
				var chk := CheckBox.new()
				chk.text = label_text
				chk.button_pressed = val
				chk.toggled.connect(func(pressed): _on_custom_property_changed(prop_name, pressed))
				property_container.add_child(chk)
				_custom_controls[prop_name] = chk
				
			elif typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
				var hbox := HBoxContainer.new()
				var lbl := Label.new()
				lbl.text = label_text + ":"
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hbox.add_child(lbl)
				
				var step := 0.05 if typeof(val) == TYPE_FLOAT and absf(val) <= 5.0 else 1.0
				var spin := _create_spin_box(-10000, 10000, step, val)
				if typeof(val) == TYPE_INT:
					spin.step = 1.0
					spin.value_changed.connect(func(new_val): _on_custom_property_changed(prop_name, int(new_val)))
				else:
					spin.value_changed.connect(func(new_val): _on_custom_property_changed(prop_name, new_val))
				hbox.add_child(spin)
				property_container.add_child(hbox)
				_custom_controls[prop_name] = spin
				
			elif typeof(val) == TYPE_VECTOR2:
				var vbox := VBoxContainer.new()
				var lbl := Label.new()
				lbl.text = label_text + " (X, Y):"
				vbox.add_child(lbl)
				
				var hbox := HBoxContainer.new()
				var spin_x := _create_spin_box(-10000, 10000, 5.0, (val as Vector2).x)
				var spin_y := _create_spin_box(-10000, 10000, 5.0, (val as Vector2).y)
				
				spin_x.value_changed.connect(func(vx): _on_custom_vec2_changed(prop_name, spin_x, spin_y))
				spin_y.value_changed.connect(func(vy): _on_custom_vec2_changed(prop_name, spin_x, spin_y))
				
				hbox.add_child(spin_x)
				hbox.add_child(spin_y)
				vbox.add_child(hbox)
				property_container.add_child(vbox)
				_custom_controls[prop_name] = [spin_x, spin_y]
			elif typeof(val) == TYPE_STRING:
				var hbox := HBoxContainer.new()
				var lbl := Label.new()
				lbl.text = label_text + ":"
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hbox.add_child(lbl)
				
				var line := LineEdit.new()
				line.text = val
				line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				line.text_submitted.connect(func(new_val): _on_custom_property_changed(prop_name, new_val))
				hbox.add_child(line)
				property_container.add_child(hbox)
				_custom_controls[prop_name] = line


func _create_spin_box(min_v: float, max_v: float, step_v: float, initial_v: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_v
	spin.max_value = max_v
	spin.step = step_v
	spin.value = initial_v
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin

func _on_transform_changed() -> void:
	if _is_updating_ui or _current_object == null or not is_instance_valid(_current_object):
		return
	var old_pos = _current_object.position
	var new_pos = Vector2(_pos_x_spin.value, _pos_y_spin.value)
	var old_rot = _current_object.rotation
	var new_rot = deg_to_rad(_rot_spin.value)
	var old_scale = _current_object.scale
	var new_scale = Vector2(_scale_x_spin.value, _scale_y_spin.value)
	
	if undo_redo != null:
		undo_redo.create_action("Change Transform")
		undo_redo.add_do_property(_current_object, "position", new_pos)
		undo_redo.add_do_property(_current_object, "rotation", new_rot)
		undo_redo.add_do_property(_current_object, "scale", new_scale)
		undo_redo.add_undo_property(_current_object, "position", old_pos)
		undo_redo.add_undo_property(_current_object, "rotation", old_rot)
		undo_redo.add_undo_property(_current_object, "scale", old_scale)
		undo_redo.commit_action()
	else:
		_current_object.position = new_pos
		_current_object.rotation = new_rot
		_current_object.scale = new_scale

func _on_custom_property_changed(prop_name: String, new_val: Variant) -> void:
	if _is_updating_ui or _current_object == null or not is_instance_valid(_current_object):
		return
	
	# Fetch current value dynamically to avoid stale closures
	var current_val = _current_object.get(prop_name)
	if typeof(current_val) == typeof(new_val) and current_val == new_val:
		return
		
	if undo_redo != null:
		undo_redo.create_action("Change " + prop_name)
		undo_redo.add_do_property(_current_object, prop_name, new_val)
		undo_redo.add_undo_property(_current_object, prop_name, current_val)
		undo_redo.commit_action()
		print("[LevelEditor] Property Changed: ", prop_name, " to ", new_val)
	else:
		_current_object.set(prop_name, new_val)
		print("[LevelEditor] Property Changed (No Undo): ", prop_name, " to ", new_val)

func _on_custom_vec2_changed(prop_name: String, spin_x: SpinBox, spin_y: SpinBox) -> void:
	if _is_updating_ui or _current_object == null or not is_instance_valid(_current_object):
		return
		
	var new_vec := Vector2(spin_x.value, spin_y.value)
	var current_vec = _current_object.get(prop_name)
	if current_vec is Vector2 and current_vec == new_vec:
		return
		
	if undo_redo != null:
		undo_redo.create_action("Change " + prop_name)
		undo_redo.add_do_property(_current_object, prop_name, new_vec)
		undo_redo.add_undo_property(_current_object, prop_name, current_vec)
		undo_redo.commit_action()
	else:
		_current_object.set(prop_name, new_vec)

## Syncs inspector UI inputs with the live object transform (e.g. while dragging).
func refresh_transform_ui() -> void:
	if _current_object == null or not is_instance_valid(_current_object) or _pos_x_spin == null:
		return
	_is_updating_ui = true
	if _pos_x_spin.value != _current_object.position.x:
		_pos_x_spin.value = _current_object.position.x
	if _pos_y_spin.value != _current_object.position.y:
		_pos_y_spin.value = _current_object.position.y
	if not is_equal_approx(deg_to_rad(_rot_spin.value), _current_object.rotation):
		_rot_spin.value = rad_to_deg(_current_object.rotation)
	if _scale_x_spin.value != _current_object.scale.x:
		_scale_x_spin.value = _current_object.scale.x
	if _scale_y_spin.value != _current_object.scale.y:
		_scale_y_spin.value = _current_object.scale.y
	_is_updating_ui = false
