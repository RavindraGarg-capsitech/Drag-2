class_name EditorSaveManager
extends RefCounted

## Handles saving LevelRoot to .res files, listing existing levels, and loading level resources.

static var default_levels_dir: String = "res://Resources/Levels/"

## Returns the active levels directory path (with trailing slash).
static func get_levels_dir() -> String:
	return default_levels_dir

## Serializes LevelRoot into a LevelData resource and saves it to {levels_dir}/Level{id}.res.
static func save_level(level_root: LevelRoot, level_id: String, level_name: String, target_dir: String = "") -> Dictionary:
	if level_root == null:
		return {"success": false, "error": "LevelRoot is null"}
		
	if level_id.strip_edges().is_empty():
		return {"success": false, "error": "Level ID cannot be empty"}
		
	var dir_path := target_dir if not target_dir.is_empty() else get_levels_dir()
	if not dir_path.ends_with("/"):
		dir_path += "/"
		
	# Ensure directory exists
	var relative_dir := dir_path.trim_prefix("res://")
	var root_dir := DirAccess.open("res://")
	if root_dir != null and not root_dir.dir_exists(relative_dir):
		root_dir.make_dir_recursive(relative_dir)
		
	var level_data := LevelData.new()
	level_data.level_id = level_id.strip_edges()
	level_data.level_name = level_name.strip_edges() if not level_name.strip_edges().is_empty() else "Level " + level_id
	var sz := level_root.get_design_size()
	level_data.design_width = sz.x
	level_data.design_height = sz.y
	
	# Collect all LevelObjects
	for obj in level_root.get_level_objects():
		if not is_instance_valid(obj):
			continue
		var obj_data := LevelObjectData.new()
		obj_data.object_id = obj.get_object_id()
		obj_data.position = obj.position
		obj_data.rotation = obj.rotation
		obj_data.scale = obj.scale
		obj_data.is_locked = obj.is_locked
		var props = obj.get_custom_properties()
		print("[LevelData] Property Saved for ", obj.get_object_id(), ": ", props)
		obj_data.properties = props
		level_data.objects.append(obj_data)
		
	var formatted_id := level_id.pad_zeros(3) if level_id.is_valid_int() else level_id
	var file_name := "Level%s.res" % formatted_id
	var save_path := dir_path + file_name
	
	var err := ResourceSaver.save(level_data, save_path)
	if err != OK:
		return {"success": false, "error": "Failed to save resource (Error code: %d)" % err}
		
	return {
		"success": true,
		"path": save_path,
		"object_count": level_data.objects.size()
	}

## Checks if a level file already exists.
static func level_file_exists(level_id: String, target_dir: String = "") -> bool:
	var dir_path := target_dir if not target_dir.is_empty() else get_levels_dir()
	if not dir_path.ends_with("/"):
		dir_path += "/"
	var formatted_id := level_id.pad_zeros(3) if level_id.is_valid_int() else level_id
	var file_name := "Level%s.res" % formatted_id
	return FileAccess.file_exists(dir_path + file_name)

## Returns a list of all existing level file paths in the levels directory.
static func get_available_levels(target_dir: String = "") -> Array[String]:
	var dir_path := target_dir if not target_dir.is_empty() else get_levels_dir()
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".res"):
				result.append(dir_path + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	result.sort()
	return result

## Loads a level from a file path into LevelRoot.
static func load_level(file_path: String, level_root: LevelRoot) -> LevelData:
	if not ResourceLoader.exists(file_path):
		push_error("EditorSaveManager: Level file does not exist at '%s'" % file_path)
		return null
		
	var res := ResourceLoader.load(file_path)
	if res is LevelData:
		var level_data := res as LevelData
		LevelLoader.load_level(level_data, level_root)
		# Freeze physics for all loaded objects in editor
		for obj in level_root.get_level_objects():
			obj.set_editor_mode(true)
		return level_data
	else:
		push_error("EditorSaveManager: Loaded file is not a LevelData resource")
		return null
