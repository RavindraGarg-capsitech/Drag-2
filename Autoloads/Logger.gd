extends Node

## Logger
## PDF §6 Time Complexity: O(1) level gate + cached tag array so repeated
## logging from hot paths (per-frame, per-node) never re-builds strings
## or re-checks config on every call beyond the first for a given tag.

enum Level { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }

## Raise this in release builds (e.g. Level.WARN) to silence noisy tags
## without touching call sites.
var current_level: int = Level.DEBUG

# Cache tag -> "[Tag]" so string formatting only happens once per tag,
# not once per log call (O(1) dictionary lookup vs repeated string build).
var _tag_prefix_cache: Dictionary = {}


func debug(tag: String, message: String) -> void:
	_log(Level.DEBUG, tag, message)


func info(tag: String, message: String) -> void:
	_log(Level.INFO, tag, message)


func warn(tag: String, message: String) -> void:
	_log(Level.WARN, tag, message)


func error(tag: String, message: String) -> void:
	_log(Level.ERROR, tag, message)


func _log(level: int, tag: String, message: String) -> void:
	# O(1) gate: bail before touching the cache or building any string.
	if level < current_level:
		return

	var prefix: String = _tag_prefix_cache.get(tag, "")

	if prefix.is_empty():
		prefix = "[%s]" % tag
		_tag_prefix_cache[tag] = prefix

	match level:
		Level.ERROR:
			printerr(prefix, " ", message)
		Level.WARN:
			print_rich("[color=orange]", prefix, " ", message, "[/color]")
		_:
			print(prefix, " ", message)
