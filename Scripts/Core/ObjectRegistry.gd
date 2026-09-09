class_name ObjectRegistry
extends RefCounted

## Centralized registry and factory mapping stable object IDs to reusable PackedScenes.
## Enables dynamic object discovery for the Level Editor and generic instantiation for Level Loaders.

const DEFAULT_REGISTRY: Dictionary = {
	"ball": {
		"id": "ball",
		"display_name": "Basketball",
		"scene_path": "res://Scenes/Objects/Ball.tscn",
		"category": "Core"
	},
	"basket": {
		"id": "basket",
		"display_name": "Goal Basket",
		"scene_path": "res://Scenes/Objects/Basket.tscn",
		"category": "Core"
	},
	"spring_rope": {
		"id": "spring_rope",
		"display_name": "Spring Rope",
		"scene_path": "res://Scenes/Objects/SpringRope.tscn",
		"category": "Interactive"
	},
	"wall": {
		"id": "wall",
		"display_name": "Static Wall",
		"scene_path": "res://Scenes/Objects/Wall.tscn",
		"category": "Obstacles"
	},
	"box": {
		"id": "box",
		"display_name": "Physics Box",
		"scene_path": "res://Scenes/Objects/Box.tscn",
		"category": "Physics"
	}
}

static var _custom_registry: Dictionary = {}
static var _scene_cache: Dictionary = {}

## Registers or overrides an object definition.
static func register_object(id: String, scene_path: String, display_name: String = "", category: String = "General") -> void:
	_custom_registry[id] = {
		"id": id,
		"display_name": display_name if not display_name.is_empty() else id.capitalize(),
		"scene_path": scene_path,
		"category": category
	}
	_scene_cache.erase(id)

## Returns metadata dictionary for a given object_id.
static func get_object_info(id: String) -> Dictionary:
	if _custom_registry.has(id):
		return _custom_registry[id]
	if DEFAULT_REGISTRY.has(id):
		return DEFAULT_REGISTRY[id]
	return {}

## Returns the PackedScene for the given object ID.
static func get_scene_for_id(id: String) -> PackedScene:
	if _scene_cache.has(id):
		return _scene_cache[id]
	
	var info := get_object_info(id)
	if info.is_empty() or not info.has("scene_path"):
		push_error("ObjectRegistry: Unknown object_id '%s'" % id)
		return null
		
	var path: String = info["scene_path"]
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("ObjectRegistry: Failed to load scene at '%s' for object_id '%s'" % [path, id])
		return null
		
	_scene_cache[id] = scene
	return scene

## Instantiates a LevelObject given its stable ID.
static func instantiate_object(id: String) -> LevelObject:
	var scene := get_scene_for_id(id)
	if scene == null:
		return null
	var instance := scene.instantiate()
	if instance is LevelObject:
		var obj := instance as LevelObject
		if obj.object_id.is_empty():
			obj.object_id = id
		return obj
	else:
		push_error("ObjectRegistry: Instantiated scene '%s' does not inherit from LevelObject" % id)
		return null

## Returns all registered object IDs.
static func get_all_registered_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in DEFAULT_REGISTRY.keys():
		if not ids.has(k):
			ids.append(k)
	for k in _custom_registry.keys():
		if not ids.has(k):
			ids.append(k)
	return ids

## Returns all registered object infos (for the future Level Editor palette/toolbar).
static func get_all_registered_objects() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for id in get_all_registered_ids():
		list.append(get_object_info(id))
	return list
