extends Node

## PlatformUtils
## PDF §6 Time Complexity: platform detection is queried once and cached,
## instead of every caller re-evaluating OS.get_name() and comparing
## strings on every check.

var _is_mobile_cache: Variant = null  # null = not computed yet
var _platform_name_cache: String = ""


func is_mobile() -> bool:
	if _is_mobile_cache == null:
		_is_mobile_cache = OS.get_name() in ["Android", "iOS"]
	return _is_mobile_cache


func platform_name() -> String:
	if _platform_name_cache.is_empty():
		_platform_name_cache = OS.get_name()
	return _platform_name_cache
