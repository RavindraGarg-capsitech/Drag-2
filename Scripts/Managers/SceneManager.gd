
class_name SceneManager
extends Node

## SceneManager
##
## PDF §5:
## Large scenes are preloaded as resources but are not instantiated
## until actually required.
##
## PDF §6:
## PackedScene resources are cached in a Dictionary for O(1) lookup.


var _preloaded: Dictionary = {}


## Preload and cache a PackedScene resource.
##
## This does NOT instantiate the scene.
func preload_scene(path: String) -> void:
	if path.is_empty():
		return

	if _preloaded.has(path):
		return

	var packed: PackedScene = load(path) as PackedScene

	if packed == null:
		push_error("SceneManager: Failed to preload scene: " + path)
		return

	_preloaded[path] = packed


## Instantiate a scene and add it to the requested parent.
##
## configure is executed after instantiate() but BEFORE add_child().
## This is important because _ready() executes when add_child() occurs.
func go_to(
	path: String,
	parent: Node = null,
	configure: Callable = Callable()
) -> Node:
	if path.is_empty():
		push_error("SceneManager: Empty scene path.")
		return null

	var packed: PackedScene = _preloaded.get(path)

	if packed == null:
		# Fallback is allowed, but callers should preload large scenes
		# whenever possible.
		packed = load(path) as PackedScene

		if packed == null:
			push_error("SceneManager: Scene not found: " + path)
			return null

		_preloaded[path] = packed

	var instance: Node = packed.instantiate()

	if instance == null:
		push_error("SceneManager: Failed to instantiate scene: " + path)
		return null

	if configure.is_valid():
		configure.call(instance)

	var target_parent: Node = parent

	if target_parent == null:
		target_parent = get_tree().root

	target_parent.add_child(instance)

	return instance


## Remove a cached PackedScene resource.
##
## Existing instantiated scenes are NOT affected.
func unload(path: String) -> void:
	if path.is_empty():
		return

	_preloaded.erase(path)


## Returns whether a scene resource is currently cached.
func is_preloaded(path: String) -> bool:
	return _preloaded.has(path)
