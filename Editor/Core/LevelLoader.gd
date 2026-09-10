class_name LevelLoader
extends RefCounted

## Generic level loader that instantiates LevelData resources into any LevelRoot container.

## Loads a LevelData resource from a file path or LevelData instance into target_root.
# LevelLoader.gd

static func load_level(level_res_or_path: Variant, target_root: LevelRoot) -> bool:
	if target_root == null:
		push_error("LevelLoader: target_root is null")
		return false
		
	var level_data: LevelData = null
	if level_res_or_path is LevelData:
		level_data = level_res_or_path as LevelData
	elif level_res_or_path is String:
		var path: String = level_res_or_path as String
		if not ResourceLoader.exists(path):
			push_error("LevelLoader: Resource does not exist at '%s'" % path)
			return false
		var res := ResourceLoader.load(path)
		if res is LevelData:
			level_data = res as LevelData
		else:
			push_error("LevelLoader: Resource at '%s' is not a LevelData" % path)
			return false
	else:
		push_error("LevelLoader: Invalid argument type for level_res_or_path")
		return false
		
	# Clear existing objects
	target_root.clear_level_objects()

	target_root.design_width = level_data.design_width      # ADDED: use this level's actual authored canvas size
	target_root.design_height = level_data.design_height    # ADDED: instead of LevelRoot's hardcoded default
	
	# Instantiate and restore objects
	for obj_data in level_data.objects:
		if obj_data == null or obj_data.object_id.is_empty():
			continue
		var obj: LevelObject = EditorObjectRegistry.instantiate_object(obj_data.object_id)
		if obj == null:
			push_warning("LevelLoader: Could not instantiate object '%s'" % obj_data.object_id)
			continue
			
		obj.design_position = obj_data.position
		obj.rotation = obj_data.rotation
		obj.scale = obj_data.scale
		obj.is_locked = obj_data.is_locked
		target_root.add_child(obj)                                                    # CHANGED: moved earlier, before position is set
		obj.global_position = target_root.calculate_responsive_position(obj_data.position)  # CHANGED: moved after add_child (see Fix 2)
		print("[LevelLoader] Property Loaded for ", obj_data.object_id, ": ", obj_data.properties)
		obj.apply_custom_properties(obj_data.properties)
		
	return true
