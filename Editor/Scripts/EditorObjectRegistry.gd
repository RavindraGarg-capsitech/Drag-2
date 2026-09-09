class_name EditorObjectRegistry
extends RefCounted

## Centralized, data-driven registry and factory for all placeable LevelObjects in the Editor.

static var _registered_objects: Dictionary = {}

## Registers an object scene with metadata.
static func register_object(object_id: String, scene_or_path: Variant, display_name: String = "", category: String = "General") -> void:
	var packed_scene: PackedScene = null
	var path_str: String = ""
	
	if scene_or_path is PackedScene:
		packed_scene = scene_or_path as PackedScene
		path_str = packed_scene.resource_path
	elif scene_or_path is String:
		path_str = scene_or_path as String
		if ResourceLoader.exists(path_str):
			packed_scene = ResourceLoader.load(path_str) as PackedScene
		else:
			push_warning("EditorObjectRegistry: Scene path '%s' does not exist" % path_str)
	
	_registered_objects[object_id] = {
		"id": object_id,
		"display_name": display_name if not display_name.is_empty() else object_id.capitalize(),
		"scene": packed_scene,
		"scene_path": path_str,
		"category": category
	}

## Loads registered objects from an EditorConfig resource.
static func load_from_config(config: EditorConfig) -> void:
	if config == null:
		return
	for def in config.registered_objects:
		var id: String = def.get("id", "")
		var path: String = def.get("scene_path", "")
		var name_str: String = def.get("display_name", "")
		var cat: String = def.get("category", "General")
		if not id.is_empty() and not path.is_empty():
			register_object(id, path, name_str, cat)

## Instantiates a registered LevelObject by ID.
static func instantiate_object(object_id: String) -> LevelObject:
	if not _registered_objects.has(object_id):
		_auto_discover_host_objects()
		
	if not _registered_objects.has(object_id):
		push_error("EditorObjectRegistry: Object ID '%s' is not registered" % object_id)
		return null
		
	var def: Dictionary = _registered_objects[object_id]
	var packed: PackedScene = def.get("scene")
	if packed == null and not def.get("scene_path", "").is_empty():
		packed = ResourceLoader.load(def["scene_path"]) as PackedScene
		def["scene"] = packed
		
	if packed == null:
		push_error("EditorObjectRegistry: PackedScene for '%s' could not be loaded" % object_id)
		return null
		
	var instance := packed.instantiate()
	if instance is LevelObject:
		var obj := instance as LevelObject
		obj.object_id = object_id
		if obj.display_name.is_empty():
			obj.display_name = def.get("display_name", object_id.capitalize())
		return obj
	else:
		push_error("EditorObjectRegistry: Instantiated scene for '%s' does not extend LevelObject" % object_id)
		return null

## Returns all object definitions for the palette UI.
static func get_palette_objects() -> Array[Dictionary]:
	if _registered_objects.is_empty():
		_auto_discover_host_objects()
	var result: Array[Dictionary] = []
	for id in _registered_objects.keys():
		result.append(_registered_objects[id])
	return result

static func _auto_discover_host_objects() -> void:
	if ResourceLoader.exists("res://Scripts/Core/ObjectRegistry.gd"):
		var reg_script = load("res://Scripts/Core/ObjectRegistry.gd")
		if reg_script != null and reg_script.has_method("get_all_registered_objects"):
			var host_objs = reg_script.get_all_registered_objects()
			for def in host_objs:
				register_object(
					def.get("id", ""),
					def.get("scene_path", ""),
					def.get("display_name", ""),
					def.get("category", "General")
				)

## Spawns an object by ID into target_root at spawn_pos.
static func spawn_object(object_id: String, target_root: LevelRoot, spawn_pos: Vector2 = Vector2(960, 540)) -> LevelObject:
	if target_root == null:
		push_error("EditorObjectRegistry: target_root is null")
		return null
		
	var obj: LevelObject = instantiate_object(object_id)
	if obj == null:
		return null
		
	obj.position = spawn_pos
	target_root.add_child(obj)
	obj.set_editor_mode(true)
	return obj

static func clear_registry() -> void:
	_registered_objects.clear()
