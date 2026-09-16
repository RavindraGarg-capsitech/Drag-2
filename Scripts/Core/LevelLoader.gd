class_name LevelLoader
extends RefCounted

static func load_level(
	level_res_or_path: Variant,
	target_root: LevelRoot
) -> bool:

	if target_root == null:
		push_error("LevelLoader: target_root is null")
		return false

	var level_data: LevelData = null

	if level_res_or_path is LevelData:
		level_data = level_res_or_path as LevelData

	elif level_res_or_path is String:
		var path: String = level_res_or_path as String

		if not ResourceLoader.exists(path):
			push_error(
				"LevelLoader: Resource does not exist at '%s'" % path
			)
			return false

		var res := ResourceLoader.load(path)

		if res is LevelData:
			level_data = res as LevelData
		else:
			push_error(
				"LevelLoader: Resource at '%s' is not a LevelData" % path
			)
			return false

	else:
		push_error(
			"LevelLoader: Invalid argument type for level_res_or_path"
		)
		return false

	if level_data == null:
		push_error("LevelLoader: level_data is null")
		return false

	target_root.clear_level_objects()

	target_root.design_width = level_data.design_width
	target_root.design_height = level_data.design_height

	print(
		"[LevelLoader] Loading level | Design Size: ",
		target_root.get_design_size()
	)

	for obj_data in level_data.objects:
		if obj_data == null:
			continue

		if obj_data.object_id.is_empty():
			continue

		var obj: LevelObject = (
			ObjectRegistry.instantiate_object(
				obj_data.object_id
			)
		)

		if obj == null:
			push_warning(
				"LevelLoader: Could not instantiate object '%s'"
				% obj_data.object_id
			)
			continue

		obj.design_position = obj_data.position
		obj.rotation = obj_data.rotation
		obj.scale = obj_data.scale
		obj.is_locked = obj_data.is_locked

		target_root.add_child(obj)

		obj.position = obj_data.position

		print(
			"[LevelLoader] Property Loaded for ",
			obj_data.object_id,
			": ",
			obj_data.properties
		)

		obj.apply_custom_properties(
			obj_data.properties
		)

	target_root._fit_level_to_viewport()

	print("[LevelLoader] Level loaded successfully.")

	return true
