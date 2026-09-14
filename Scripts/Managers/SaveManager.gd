
class_name SaveManager
extends Node

## SaveManager
##
## PDF §6:
## Reads/writes use an in-memory Dictionary cache.
## Disk I/O occurs only during load() and explicit save().
##
## This prevents repeated per-key disk access.


const SAVE_PATH: String = "user://save_data.json"


var _cache: Dictionary = {}
var _dirty: bool = false


func _ready() -> void:
	_load_from_disk()


func get_value(
	key: String,
	default_value: Variant = null
) -> Variant:
	return _cache.get(key, default_value)


func set_value(
	key: String,
	value: Variant
) -> void:
	if _cache.get(key, null) == value and _cache.has(key):
		return

	_cache[key] = value
	_dirty = true


func has_value(key: String) -> bool:
	return _cache.has(key)


func save() -> void:
	if not _dirty:
		return

	var file: FileAccess = FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"SaveManager: Failed to open save file for writing."
		)
		return

	file.store_string(JSON.stringify(_cache))
	file.close()

	_dirty = false


func _load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file: FileAccess = FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"SaveManager: Failed to open save file for reading."
		)
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)

	if parsed is Dictionary:
		_cache = parsed
		_dirty = false
	else:
		push_error(
			"SaveManager: Save file corrupt, starting fresh."
		)
